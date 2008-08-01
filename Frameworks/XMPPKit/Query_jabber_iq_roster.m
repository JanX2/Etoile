//
//  Query_jabber_iq_roster.m
//  Jabber
//
//  Created by David Chisnall on 12/11/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "Query_jabber_iq_roster.h"
#import "JabberIdentity.h"
#include "../Macros.h"

@implementation Query_jabber_iq_roster
- (id) init
{
	SUPERINIT;
	identities = RETAINED(NSMutableArray);
	value = identities;
	return self;
}

- (void)startElement:(NSString *)aName
		  attributes:(NSDictionary*)attributes
{
	if ([aName isEqualToString:@"item"])
	{
		[[[JabberIdentity alloc] initWithXMLParser:parser
											parent:self
											   key:@"identity"] startElement:aName
																  attributes:attributes];
	}
	else if ([aName isEqualToString:@"query"])
	{
		depth++;
	}
}

- (void) addidentity:(id)anIdentity
{
	[identities addObject:anIdentity];
}

- (void) dealloc
{
	[identities release];
	[super dealloc];
}

@end
