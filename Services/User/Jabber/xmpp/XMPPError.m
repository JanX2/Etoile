//
//  XMPPError.m
//  Jabber
//
//  Created by David Chisnall on 26/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "XMPPError.h"
#import "ETXMLString.h"
#include "../Macros.h"

@implementation XMPPError
- (id) init
{
	SUPERINIT;
	value = self;
	return self;
}
/*
<error code='404' type='wait'>
 <recipient-unavailable xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
 <text xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>error message</text>
</error>
 */
 
- (void)startElement:(NSString *)aName
		  attributes:(NSDictionary*)attributes
{
	if([aName isEqualToString:@"error"])
	{
		depth++;
		code = [[attributes objectForKey:@"code"] intValue];
		type = [[attributes objectForKey:@"type"] retain];
	}
	else if([aName isEqualToString:@"text"])
	{
		[[[ETXMLString alloc] initWithXMLParser:parser
										 parent:self
											key:@"text"] startElement:aName
														   attributes:attributes];
	}
	else
	{
		[[[ETXMLNullHandler alloc] initWithXMLParser:parser
											  parent:self
												 key:@"text"] startElement:aName
																attributes:attributes];
	}
}
- (void) addtext:(NSString*)aString
{
	[message release];
	message = [aString retain];
}
- (NSString*) errorMessage
{
	return message;
}
- (int) errorCode
{
	return code;
}
- (NSString*) errorType
{
	return type;
}

- (void) dealloc
{
	[message release];
	[type release];
	[super dealloc];
}
@end
