//
//  Roster.m
//  Jabber
//
//  Created by David Chisnall on Sun Apr 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "Roster.h"
#import "XMPPAccount.h"
#import "ETXMLNode.h"
#import "JabberPerson.h"
#import "JabberRootIdentity.h"
#import "JabberResource.h"
#import "CompareHack.h"
#include "../Macros.h"

@implementation Roster
- (id) initWithAccount:(id)_account
{
	self = [self init];
	if(self == nil || ![_account isKindOfClass:[XMPPAccount class]])
	{
		[self release];
		return nil;
	}
	account = _account;
	return self;
}

- (id) init
{
	account = nil;
	delegate = nil;
	dispatcher = nil;
	peopleByJID = [[NSMutableDictionary alloc] init];
	groups = [[NSMutableArray alloc] init];
	groupsByName = [[NSMutableDictionary alloc] init];
	initialMessage = nil;
	initialStatus = PRESENCE_ONLINE;
	return [super init];
}

- (void) setInitialStatus:(unsigned char)_status withMessage:(NSString*)_message
{
	[initialMessage release];
	initialMessage = [_message retain];
	initialStatus = _status;
}

- (void) offline
{
	FOREACH(peopleByJID, person, JabberPerson*)
	{
		FOREACH([person identityList], identity, JabberIdentity*)
		{
			Presence * unknownPresence = [[Presence alloc] initWithJID:[identity jid]];
			[identity setPresence:unknownPresence];
			[unknownPresence release];
		}
	}
	connected = NO;
	//Trigger a roster redisplay when we go offline
	[delegate update:nil];
}

- (void) addRosterFromQuery:(Iq*) rosterQuery
{
	NSLog(@"Parsing roster...");
	connection = [(XMPPAccount*)account connection];
	dispatcher = [connection dispatcher];

	FOREACH([[rosterQuery children] objectForKey:@"RosterItems"], newIdentity, JabberIdentity*)
	{
		JID * jid = [newIdentity jid];
		NSString * groupName = [newIdentity group];
		if(groupName == nil)
		{
			groupName = @"None";
		}
		RosterGroup * group = [groupsByName objectForKey:groupName];
		if(group == nil)
		{
			group = [RosterGroup groupWithRoster:self];
			[group groupName:groupName];
			[groupsByName setObject:group forKey:groupName];
			[groups addObject:group];
			//[groups sortUsingSelector:@selector(compare:)];
			[groups sortUsingFunction:compareTest context:nil];
			
		}
		[group addIdentity:newIdentity];

		[peopleByJID setObject:[group personNamed:[newIdentity name]] 
						forKey:[jid jidStringWithNoResource]];

		[dispatcher addPresenceHandler:[newIdentity person]
								ForJID:[jid jidStringWithNoResource]];
		[connection XMPPSend:[NSString stringWithFormat:@"<iq to='%@' type='get' id='%@'><vCard xmlns='vcard-temp'/></iq>"
							  , [jid jidStringWithNoResource], [connection newMessageID]]];
	}
	//Once we have received the roster, tell the server we are online.
	if(!connected)
	{
		[[(XMPPAccount*)account connection] setStatus:initialStatus withMessage:initialMessage];
	}
}

- (void) handlePresence:(Presence*)aPresence
{
	switch([aPresence type])
	{
		case subscribe:
			[[NSNotificationCenter defaultCenter] postNotificationName:@"TRXMPPSubscriptionRequest"
																object:aPresence];
			break;
		case subscribed:
			[[NSNotificationCenter defaultCenter] postNotificationName:@"TRXMPPSubscription"
																object:aPresence];
			break;
		case unsubscribe:
			[[NSNotificationCenter defaultCenter] postNotificationName:@"TRXMPPUnsubscriptionRequest"
																object:aPresence];
			break;
		case unsubscribed:
			[[NSNotificationCenter defaultCenter] postNotificationName:@"TRXMPPUnubscription"
																object:aPresence];
			break;
			//Ignore presence info for people not on the roster.  
			//If there is a conversation open for these people, it should have registered itself already
		case online:
			//TODO: Make this temporarily add people to the roster when they bing-bong you. 
		case unavailable:
		default:
			break;
	}
}

- (void) handleIq:(Iq*)anIq
{
	//NSLog(@"Children of iq node: %@", [anIq children]);
	if([[anIq children] objectForKey:@"RosterItems"] != nil)
	{
		[self addRosterFromQuery:anIq];
	}
/*	ETXMLNode * child = [[node getChildrenWithName:@"query"] anyObject];
	if([[child get:@"xmlns"] isEqualToString:@"jabber:iq:roster"])
	{
		[self addRosterFromQuery:child];
		//Trigger a full roster redisplay after it has been updated
		[delegate update:nil];
	}*/
}

- (void) subscribe:(JID*)_jid withName:(NSString*)_name inGroup:(NSString*)_group
{
	/*
	 <iq type="set" id="anID" >
	 <query xmlns="jabber:iq:roster">
	 <item name="The Raven" jid="theraven@theravensnest.org" >
	 <group>Me</group>
	 </item>
	 </query>
	 </iq>
	 
	 <presence type="subscribe" to="theraven@theravensnest.org" />
	 */
	NSString * jidString = [_jid jidString];
	ETXMLNode * setRoster = [ETXMLNode ETXMLNodeWithType:@"iq" attributes:[NSDictionary dictionaryWithObjectsAndKeys:
		@"set", @"type",
		[connection newMessageID], @"id", nil]];
	ETXMLNode * query = [ETXMLNode ETXMLNodeWithType:@"query" 
										  attributes:[NSDictionary dictionaryWithObject:@"jabber:iq:roster" 
																				 forKey:@"xmlns"]];
	ETXMLNode * item = [ETXMLNode ETXMLNodeWithType:@"item" 
											attributes:[NSDictionary dictionaryWithObjectsAndKeys:
												_name, @"name",
												jidString, @"jid", 
												nil]];
	//Add the group if one is specified
	if(_group != nil && ![_group isEqualToString:@""])
	{
		ETXMLNode * group = [ETXMLNode ETXMLNodeWithType:@"group"];
		[group setCData:_group];
		[item addChild:group];
	}
	[query addChild:item];
	[setRoster addChild:query];
	
	ETXMLNode * presenceNode = [ETXMLNode ETXMLNodeWithType:@"presence" 
												 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
													 @"subscribe", @"type", 
													 jidString, @"to", 
													 nil]];
	[connection XMPPSend:[setRoster stringValue]];
	[connection XMPPSend:[presenceNode stringValue]];
}

- (void) unsubscribe:(JID*)_jid
{
	/*<iq type="set" id="aab7a" >
	<query xmlns="jabber:iq:roster">
	<item subscription="remove" jid="gimbo@theravensnest.org" />
	</query>
	</iq>*/
	ETXMLNode * setRoster = [ETXMLNode ETXMLNodeWithType:@"iq" attributes:
		[NSDictionary dictionaryWithObjectsAndKeys:
			@"set", @"type", 
			[connection newMessageID], @"id", 
			nil]];
	ETXMLNode * query = [ETXMLNode ETXMLNodeWithType:@"query" 
										  attributes:[NSDictionary dictionaryWithObject:@"jabber:iq:roster" 
																				 forKey:@"xmlns"]];
	ETXMLNode * item = [ETXMLNode ETXMLNodeWithType:@"item" 
											attributes:[NSDictionary dictionaryWithObjectsAndKeys:
												@"remove", @"subscription",
												[_jid jidString], @"jid",
												nil]];
	[query addChild:item];
	[setRoster addChild:query];	
	[setRoster addChild:query];
	[connection XMPPSend:[setRoster stringValue]];
}
- (void) authorise:(JID*)_jid
{
	[connection XMPPSend:[[ETXMLNode ETXMLNodeWithType:@"presence" 
					  attributes:[NSDictionary dictionaryWithObjectsAndKeys:
						  @"subscribed", @"type", 
						  [_jid jidString], @"to",
						  nil]] stringValue]];
}


- (void) unauthorise:(JID*)_jid
{
	[connection XMPPSend:[[ETXMLNode ETXMLNodeWithType:@"presence" 
										   attributes:[NSDictionary dictionaryWithObjectsAndKeys:
											   @"unsubscribed", @"type",
											   [_jid jidString], @"to",
											   nil]] stringValue]];	
}


/*
 Roster updates look like this:
 <iq type='set' id='roster_3'>
 <query xmlns='jabber:iq:roster'>
 <item jid='romeo@example.net'
 name='Romeo'
 subscription='both'>
 <group>Friends</group>
 <group>Lovers</group>
 </item>
 </query>
 </iq>
 */ 
- (NSString*) iqSettingGroup:(NSString*)aGroup
						name:(NSString*)aName
					  forJID:(NSString*)aJID
{
	//<group>
	ETXMLNode * group = [[ETXMLNode alloc] initWithType:@"group"];
	[group setCData:aGroup];
	//<item>
	NSDictionary * itemAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		aJID, @"jid",
		aName, @"name",
		nil];
	ETXMLNode * item = [[ETXMLNode alloc] initWithType:@"item"
											attributes:itemAttributes];
	[item addChild:group];
	//<query>
	ETXMLNode * query = [[ETXMLNode alloc] initWithType:@"query"
											 attributes:[NSDictionary dictionaryWithObject:@"jabber:iq:roster"
																					forKey:@"xmlns"]];
	[query addChild:item];
	//<iq>
	NSDictionary * iqAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		@"set", @"type",
		[connection newMessageID], @"id",
		nil];
	ETXMLNode * iq = [[ETXMLNode alloc] initWithType:@"item"
										  attributes:iqAttributes];
	
	NSString * xml = [iq stringValue];
	//Clean up:
	[iq release];
	[query release];
	[item release];
	[group release];
	return xml;
}


- (void) setName:(NSString*)aName forIdentity:(JabberIdentity*)anIdentity
{
	JabberPerson * person = [self personForJID:[anIdentity jid]];
	//Don't use this for people who aren't in our roster. 
	if(person == nil)
	{
		return;
	}
	NSString * xml = [self iqSettingGroup:[person group]
									 name:aName
								   forJID:[[anIdentity jid] jidString]];
	//Send the iq:
	[connection XMPPSend:xml];
	//Remove the identity from the old person:
	[person removeIdentity:anIdentity];
}

- (void) setGroup:(NSString*)aGroup forIdentity:(JabberIdentity*)anIdentity
{
	JabberPerson * person = [self personForJID:[anIdentity jid]];
	//Don't use this for people who aren't in our roster. 
	if(person == nil)
	{
		return;
	}
	NSString * xml = [self iqSettingGroup:aGroup
									 name:[person name]
								   forJID:[[anIdentity jid] jidString]];
	//Send the iq:
	[connection XMPPSend:xml];
	//Remove the identity from the old person:
	[person removeIdentity:anIdentity];
}

- (JabberPerson*) personForJID:(JID*)_jid
{
	JabberPerson * person = [peopleByJID objectForKey:[_jid jidStringWithNoResource]];
	if(person == nil)
	{
		JabberRootIdentity * identity = [[JabberRootIdentity alloc] initWithJID:[_jid rootJID]
																   withName:[_jid node]
																	inGroup:nil
																  forPerson:nil];
		person = [[JabberPerson alloc] initWithIdentity:identity
											  forRoster:[account roster]];
		[identity person:person];
		if([_jid resource] != nil)
		{
			[identity addResource:_jid];
		}
		[peopleByJID setObject:person forKey:[_jid jidStringWithNoResource]];

		RosterGroup * group = [groupsByName objectForKey:@"None"];
		if(group == nil)
		{
			group = [RosterGroup groupWithRoster:self];
			[group groupName:@"None"];
			[groupsByName setObject:group forKey:@"None"];
			[groups addObject:group];
			//[groups sortUsingSelector:@selector(compare:)];
			[groups sortUsingFunction:compareTest context:nil];

		}
		[group addIdentity:identity];
	}
	return person;
}

- (RosterGroup*) groupForIndex:(int)_index
{
	return [groups objectAtIndex:_index];
}
- (RosterGroup*) groupForIndex:(int)_index ignoringPeopleLessOnlineThan:(unsigned int)onlineState
{
	int count = -1;
	FOREACH(groups, group, RosterGroup*)
	{
		if([group numberOfPeopleInGroupMoreOnlineThan:onlineState] > 0)
		{
			count++;
			if(count == _index)
			{
				return group;
			}
		}
	}
	return nil;
}

- (RosterGroup*) groupNamed:(NSString*)_groupName
{
	return [groupsByName objectForKey:_groupName];
}
- (int) numberOfGroups
{
	return [groups count];
}
//TODO: Fix typo in selector name
- (int) numberOfGroupsContainingPeopleMoreOnlineThan:(unsigned int)onlineState
{
	int count = 0;
	FOREACH(groups, group, RosterGroup*)
	{
		if([group numberOfPeopleInGroupMoreOnlineThan:onlineState] > 0)
		{
			count++;
		}
	}
	return count;
}

- (id) delegate
{
	return delegate;
}

- (void) setDelegate:(id <RosterDelegate, NSObject>)_delegate
{
	[delegate release];
	delegate = [_delegate retain];
}

- (void) update:(id)_object
{
	[delegate update:_object];
}
- (void) dealloc
{
	[delegate release];
	[super dealloc];
}
@end
