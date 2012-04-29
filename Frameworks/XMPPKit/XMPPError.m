//
//  XMPPError.m
//  Jabber
//
//  Created by David Chisnall on 26/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "XMPPError.h"
#import <EtoileXML/ETXMLString.h>
#import <EtoileFoundation/EtoileFoundation.h>

@implementation XMPPError
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
		type = [attributes objectForKey:@"type"];
	}
	else if([aName isEqualToString:@"text"])
	{
		[[[ETXMLString alloc] initWithXMLParser:parser
					            key:@"text"] startElement:aName
					     attributes:attributes];
	}
	else
	{
		[[[ETXMLNullHandler alloc] initWithXMLParser:parser
						         key:nil] startElement:aName
						  attributes:attributes];
	}
}
- (void) addtext:(NSString*)aString
{
	message = aString;
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

@end
