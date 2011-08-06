//
//  XMPPMessage.m
//  Jabber
//
//  Created by David Chisnall on 20/08/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XMPPMessage.h"
#include <wchar.h>
#include <wctype.h>
#import <AppKit/AppKit.h>
#import <EtoileXML/ETXMLString.h>
#import "XMPPMessageStanzaFactory.h"
#import "XMPPError.h"
#import "NSAttributedString+HTML-IM.h"
#import <EtoileFoundation/EtoileFoundation.h>

NSDictionary * MESSAGE_TYPES;

@implementation XMPPMessage
+ (void) initialize
{
	MESSAGE_TYPES = [[NSDictionary alloc] initWithObjectsAndKeys:
		[NSNumber numberWithInt:MESSAGE_TYPE_CHAT], @"chat",
		[NSNumber numberWithInt:MESSAGE_TYPE_MESSAGE], @"message",
		[NSNumber numberWithInt:MESSAGE_TYPE_ERROR], @"error",
		[NSNumber numberWithInt:MESSAGE_TYPE_GROUPCHAT], @"groupchat",
		nil];
}
	
+ (id) messageWithBody:(id)_body for:(JID*)_recipient withSubject:(NSString*)_subject type:(message_type_t)_type
{
	return [[[XMPPMessage alloc] initWithBody:_body for:_recipient withSubject:_subject type:_type] autorelease];
}

- (id) initWithBody:(id)_body for:(JID*)_recipient withSubject:(NSString*)_subject type:(message_type_t)_type
{
	NSLog(@"Body (%@) %@", [_body class], _body);
	if([_body isKindOfClass:[NSString class]])
	{
		body = [[_body stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] retain];		
	}
	else if([_body isKindOfClass:[NSAttributedString class]])
	{
		body = [[[_body stringValueWithExpandedLinks] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] retain];
		html = [_body retain];
	}
	correspondent = [_recipient retain];
	subject = [_subject retain];
	type = type;
	direction = out;
	return [super init];
}

- (id) initWithXMLParser: (ETXMLParser*)aParser
                  parent: (id <ETXMLParserDelegate>) aParent
                     key: (id) aKey
{
	self = [super initWithXMLParser: aParser
	                         parent: aParent
	                            key: aKey];
	if (nil == self)
	{
		return nil;
	}
	unknownAttributes = [[NSMutableDictionary alloc] init];
	timestamps = [[NSMutableArray alloc] init];
	body = @"";
	shouldDisplay = YES;
	return self;
}

- (void) beginWritingToXMLWriter: (ETXMLWriter*)xmlWriter
{
	NSMutableDictionary * attributes = [[NSMutableDictionary alloc] init];
	
	switch(type)
	{
		case MESSAGE_TYPE_CHAT:
			[attributes setValue:@"chat" forKey:@"type"];
			break;
		case MESSAGE_TYPE_ERROR:
			[attributes setValue:@"error" forKey:@"type"];
			break;
		case MESSAGE_TYPE_GROUPCHAT:
			[attributes setValue:@"groupchat" forKey:@"type"];
		case MESSAGE_TYPE_MESSAGE:
		case MESSAGE_TYPE_SPECIAL:
			break;
	}
	if(direction == out)
	{
		[attributes setValue:[correspondent jidString] forKey:@"to"];
	}
	else
	{
		[attributes setValue:[correspondent jidString] forKey:@"from"];
	}
	[xmlWriter startElement: @"message" attributes: attributes];
	[attributes release];

	if(subject != nil)
	{
		[xmlWriter startElement: @"subject"];
		[xmlWriter characters: subject];
		[xmlWriter endElement];
	}
	if(body != nil)
	{
		[xmlWriter startElement: @"body"];
		[xmlWriter characters: body];
		[xmlWriter endElement];
	}
	if(html != nil)
	{
		[html writeXHTMLIMToXMLWriter: xmlWriter];
	}
}

- (void) finishWritingToXMLWriter: (ETXMLWriter*) xmlWriter
{
	[xmlWriter endElement];
}

- (void)writeToXMLWriter: (ETXMLWriter*)xmlWriter
{
	[self beginWritingToXMLWriter: (ETXMLWriter*) xmlWriter];
	[self finishWritingToXMLWriter: (ETXMLWriter*) xmlWriter];
}


- (JID*) correspondent
{
	return correspondent;
}

- (NSString*) subject
{
	return subject;
}

- (void) setSubject:(NSString*)aSubject
{
	subject = [aSubject retain];
}
- (NSString*) body
{
	return body;
}

- (void) setBody:(NSString*)aBody
{
	body = [aBody retain];
}


- (NSAttributedString*) HTMLBody
{
	if(html != nil)
	{
		return html;
	}
	return [[[NSAttributedString alloc] initWithString:body] autorelease];
}

- (BOOL) in
{
	if(direction == in)
	{
		return YES;
	}
	return NO;
}
- (message_type_t) type
{
	return type;
}
- (Timestamp*) timestamp
{
	return [timestamps lastObject];
}
- (XMPPError*) error
{
	return error;
}
- (NSComparisonResult) compareByTimestamp:(XMPPMessage*)_other
{
	return [[self timestamp] compare:[_other timestamp]];
}
- (void)characters:(NSString *)_chars
{
	//Ignore cdata
}
- (void)startElement:(NSString *)aName
		  attributes:(NSDictionary*)attributes
{
	if([aName isEqualToString:@"message"])
	{
		depth++;
		correspondent = [[JID jidWithString:[attributes objectForKey:@"from"]] retain];
		direction = in;
		type = [[MESSAGE_TYPES objectForKey:[attributes objectForKey:@"type"]] intValue];		
	}
	else 
	{
		XMPPMessageStanzaFactory * factory = [XMPPMessageStanzaFactory sharedStazaFactory];
		NSString * xmlns = [attributes objectForKey:@"xmlns"];
		Class handler = [factory handlerForTag:aName inNamespace:xmlns];
		NSString * elementKey = [factory valueForTag:aName inNamespace:xmlns];
		[[[handler alloc] initWithXMLParser:parser
									 parent:self
										key:elementKey] startElement:aName
														  attributes:attributes];
	}
}
- (void)endElement:(NSString *)aName
{
	if([aName isEqualToString:@"message"])
	{
		[parser setContentHandler:parent];
		[(id)parent addChild:self forKey:key];
	}
	else
	{
		NSLog(@"End of %@ tag received while parsing a message.  This probably indicates a bug.", aName);
	}
}


- (void) setParser:(id) XMLParser
{
	parser = XMLParser;
}
- (void) setParent:(id) newParent
{
	parent = newParent;
}

- (void) addbody:(NSString*)aBody
{
	body = [[aBody stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] retain];
}
- (void) addsubject:(NSString*)aSubject
{
	subject = [aSubject retain];
}
- (void) addtimestamp:(Timestamp*)aTimestamp
{
	[timestamps addObject:aTimestamp];
	[timestamps sortUsingSelector:@selector(compare:)];
}
- (void) addhtml:(NSAttributedString*)anAttributedString
{
	html = [anAttributedString retain];
}
- (void) adderror:(XMPPError*)anError
{
	[error release];
	error = [anError retain];
}

- (void) setShouldDisplay:(BOOL)aFlag
{
	shouldDisplay = aFlag;
}
- (BOOL) shouldDisplay
{
	return shouldDisplay;
}


- (void) dealloc
{
	[correspondent release];
	[subject release];
	[body release];
	[timestamps release];
	[error release];
	[super dealloc];
}

@end
