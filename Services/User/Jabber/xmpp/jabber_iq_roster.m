//
//  jabber_iq_roster.m
//  Jabber
//
//  Created by David Chisnall on 03/06/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "jabber_iq_roster.h"
#import "JID.h"
#import <EtoileXML/ETXMLString.h>
#import "../Macros.h"

@interface roster_item : ETXMLNullHandler {
}
@end

@implementation roster_item
- (void)startElement:(NSString *)aName
		  attributes:(NSDictionary*)attributes;
{
	if([aName isEqualToString:@"item"])
	{
		value = [attributes retain];
	}
	else if([aName isEqualToString:@"group"])
	{
		[[ETXMLString alloc] initWithXMLParser:parser
										parent:self
										   key:@"group"];
	}
}
- (void) setgroup:(NSString*)aGroup
{
	[(NSMutableDictionary*)value setObject:aGroup
									 forKey:@"group"];
}

@end

@implementation jabber_iq_roster
- (id) init
{
	SUPERINIT;
	value = [[NSMutableArray alloc] init];
	return self;
}
- (void)startElement:(NSString *)aName
		  attributes:(NSDictionary*)attributes;
{
	if([aName isEqualToString:@"item"])
	{
		[[[roster_item alloc] initWithXMLParser:parser
										parent:self
										   key:@"item"] startElement:aName
														  attributes:attributes];
		
	}		
}

- (void) setitem:(id)anItem
{
	[value addObject:anItem];
}
@end
