//
//  Query_jabber_iq_roster.m
//  Jabber
//
//  Created by David Chisnall on 12/11/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "Query_jabber_iq_roster.h"
#import "XMPPIdentity.h"
#import <EtoileFoundation/EtoileFoundation.h>

@implementation Query_jabber_iq_roster
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
	identities = [NSMutableArray new];
	[value autorelease];
	value = identities;
	return self;
}

- (void)startElement:(NSString *)aName
		  attributes:(NSDictionary*)attributes
{
	if ([aName isEqualToString:@"item"])
	{
		[[[XMPPIdentity alloc] initWithXMLParser:parser
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
