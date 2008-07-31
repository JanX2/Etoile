//
//  JabberIdentity.m
//  Jabber
//
//  Created by David Chisnall on 20/08/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "JabberIdentity.h"
#import "JabberRootIdentity.h"
#import <EtoileXML/ETXMLString.h>
#include "../Macros.h"

@implementation JabberIdentity


- (id) initWithJID:(JID*)_jid withName:(NSString*)_name inGroup:(NSString*)_group forPerson:(id)_person
{
	[self init];
	jid = [_jid retain];
	name = [_name retain];
	group = [_group retain];
	person = [_person retain];
	return self;
}

- (id) init
{
	SUPERINIT;
	presence = [[Presence alloc] init];
	return self;
}

/*
 <query xmlns='jabber:iq:roster'>
 <item
 jid='user@example.com'
 subscription='to'
 name='SomeUser'>
 <group>SomeGroup</group>
 </item>
 </query>
 */

- (void)startElement:(NSString *)aName
		  attributes:(NSDictionary*)attributes
{
	if([aName isEqualToString:@"item"])
	{
		depth++;
		jid = [[JID alloc] initWithString:[attributes objectForKey:@"jid"]];
		subscription = [[attributes objectForKey:@"subscription"] retain];
		ask = [[attributes objectForKey:@"ask"] retain];
		name = [[attributes objectForKey:@"name"] retain];
	}
	else if([aName isEqualToString:@"group"])
	{
		[[[ETXMLString alloc] initWithXMLParser:parser
										parent:self
										   key:@"group"] startElement:aName
														   attributes:attributes];
	}
	else
	{
		[[[ETXMLNullHandler alloc] initWithXMLParser:parser
											  parent:self
												 key:nil] startElement:aName
															attributes:attributes];
	}
}

- (void) addgroup:(NSString*)aGroup
{
	[group release];
	group = [aGroup retain];
}

- (void) setPresence:(Presence*)_presence
{
	[presence release];
	presence = [_presence retain];
	priority = basePriority + 70 - [presence show] + [presence priority];	
}

- (NSString*) name
{
	if (name == nil)
	{
		return [jid node];
	}
	return name;
}

- (NSString*) group
{
	return group;
}
- (void) setName:(NSString*)aName
{
	[aName retain];
	[name release];
	name = aName;
}
- (void) setGroup:(NSString*)aGroup
{
	[aGroup retain];
	[group release];
	group = aGroup;	
}

- (JID*) jid
{
	return jid;
}

- (Presence*) presence
{
	return presence;
}

- (int) priority
{
	return priority;
}
- (NSString*) subscription
{
	return subscription;
}
- (NSString*) ask
{
	return ask;
}
- (id) person
{
	return person;
}

- (void) person:(id)_person
{
	[person release];
	person = [_person retain];
}

- (NSComparisonResult) compareByPriority:(JabberIdentity*)_other
{
	if(priority > [_other priority])
	{
		return NSOrderedAscending;
	}
	if(priority < [_other priority])
	{
		return NSOrderedDescending;
	}
	return NSOrderedSame;
}

- (NSComparisonResult) compareByJID:(JabberIdentity*)_other
{
	return NSOrderedAscending;
}

- (void) dealloc
{
	[person release];
	[jid release];
	[subscription release];
	[ask release];
	[group release];
	[name release];
	[presence release];
	[super dealloc];
}
@end
