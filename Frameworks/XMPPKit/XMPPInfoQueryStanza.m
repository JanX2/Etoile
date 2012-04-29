//
//  XMPPInfoQueryStanza.m
//  Jabber
//
//  Created by David Chisnall on 30/05/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "XMPPInfoQueryStanza.h"
#import "XMPPInfoQueryStanzaFactory.h"
#import "XMPPIdentity.h"
#import <EtoileFoundation/EtoileFoundation.h>

static NSDictionary * TYPES;

@implementation XMPPInfoQueryStanza
+ (void) initialize
{
	TYPES = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:IQ_TYPE_SET], @"set",
		[NSNumber numberWithInt:IQ_TYPE_GET], @"get",
		[NSNumber numberWithInt:IQ_TYPE_RESULT], @"result",
		[NSNumber numberWithInt:IQ_TYPE_ERROR], @"error",
		nil];
}
- (id) initWithXMLParser: (ETXMLParser*)aParser
                     key: (id)aKey
{
	self = [super initWithXMLParser: aParser
	                            key: aKey];
	if (nil == self)
	{
		return nil;
	}
	children = [NSMutableDictionary new];
	return self;
}

- (void)startElement:(NSString *)aName
		  attributes:(NSDictionary*)attributes
{
	if([aName isEqualToString:@"iq"])
	{
		depth++;
		type = [[TYPES objectForKey:[attributes objectForKey:@"type"]] intValue];
		jid = [[JID alloc] initWithString:[attributes objectForKey:@"from"]];
		sequenceID = [attributes objectForKey:@"id"];
	}
	else
	{
		XMPPInfoQueryStanzaFactory * factory = [XMPPInfoQueryStanzaFactory sharedStazaFactory];
		NSString * xmlns = [attributes objectForKey:@"xmlns"];
		if([aName isEqualToString:@"query"])
		{
			queryxmlns = xmlns;
		}
		Class handler = [factory handlerForTag:aName inNamespace:xmlns];
		NSString * elementKey = [factory valueForTag:aName inNamespace:xmlns];
		[[[handler alloc] initWithXMLParser:parser
						key:elementKey] startElement:aName
					 attributes:attributes];
	}
}
- (NSString*) sequenceID
{
	return sequenceID;
}

- (JID*) jid
{
	return jid;
}

- (iq_type_t) type
{
	return type;
}
- (NSString*) queryNamespace
{
	return queryxmlns;
}

@end
