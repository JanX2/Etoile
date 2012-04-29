//  XMPPIdentity.m
//  Jabber
//
//  Created by David Chisnall on 20/08/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XMPPIdentity.h"
#import "XMPPRootIdentity.h"
#import <EtoileXML/ETXMLString.h>
#import <EtoileFoundation/EtoileFoundation.h>

@implementation XMPPIdentity


- (id) initWithJID:(JID*)_jid withName:(NSString*)_name inGroup:(NSString*)_group forPerson:(id)_person
{
	if (!(self = [self init])) return nil;
	jid = _jid;
	name = _name;
	group = _group;
	person = _person;
	return self;
}

- (id) initWithXMLParser: (ETXMLParser*) aParser
                     key: (id) aKey
{
	self = [super initWithXMLParser: aParser
	                            key: aKey];
	if (nil == self)
	{
		return nil;
	}
	presence = [[XMPPPresence alloc] init];
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
		subscription = [attributes objectForKey:@"subscription"];
		ask = [attributes objectForKey:@"ask"];
		name = [attributes objectForKey:@"name"];
	}
	else if([aName isEqualToString:@"group"])
	{
		[[[ETXMLString alloc] initWithXMLParser:parser
	   					    key:@"group"] startElement:aName
														   attributes:attributes];
	}
	else
	{
		[[[ETXMLNullHandler alloc] initWithXMLParser:parser
						         key:nil] startElement:aName
															          attributes:attributes];
	}
}

- (void) addgroup:(NSString*)aGroup
{
	group = aGroup;
}

- (void) setPresence:(XMPPPresence*)_presence
{
	presence = _presence;
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
	name = aName;
}
- (void) setGroup:(NSString*)aGroup
{
	group = aGroup;	
}

- (JID*) jid
{
	return jid;
}

- (XMPPPresence*) presence
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
	person = _person;
}

- (NSComparisonResult) compareByPriority:(XMPPIdentity*)_other
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

- (NSComparisonResult) compareByJID:(XMPPIdentity*)_other
{
	return NSOrderedAscending;
}

@end
