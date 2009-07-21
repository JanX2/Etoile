//
//  Roster.m
//  Jabber
//
//  Created by David Chisnall on Sun Apr 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "Roster.h"
#import "XMPPAccount.h"
#import "JabberPerson.h"
#import "JabberRootIdentity.h"
#import "JabberResource.h"
#import "CompareHack.h"
#import "ServiceDiscovery.h"
#import <EtoileFoundation/EtoileFoundation.h>

@implementation Roster
- (Roster*) initWithAccount:(id)_account
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
	peopleByJID = [[NSMutableDictionary alloc] init];
	groups = [[NSMutableArray alloc] init];
	groupsByName = [[NSMutableDictionary alloc] init];
	queriedServers = [[NSMutableSet alloc] init];
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
	if(disco == nil)
	{
		disco = (ServiceDiscovery*)[[ServiceDiscovery alloc] initWithAccount:account];		
	}

	FOREACH([[rosterQuery children] objectForKey:@"RosterItems"], newIdentity, JabberIdentity*)
	{
		JID * jid = [newIdentity jid];
		if([[newIdentity subscription] isEqualToString:@"remove"])
		{
			JabberPerson * person = [self personForJID:jid];
			JabberIdentity * oldIdentity = [person identityForJID:jid];
			RosterGroup * group = [self groupNamed:[person group]];
			[group removeIdentity:oldIdentity];
			[peopleByJID removeObjectForKey:[jid jidStringWithNoResource]];
			if([group numberOfPeopleInGroupMoreOnlineThan:PRESENCE_UNKNOWN + 10] == 0)
			{
				[groups removeObject:group];
				[groupsByName removeObjectForKey:[group groupName]];
			}
		}
		else
		{
			JabberIdentity * oldIdentity = [[peopleByJID objectForKey:[jid jidString]] identityForJID:jid];
			if(oldIdentity != nil)
			{
				if([[oldIdentity name] isEqualToString:[newIdentity name]]
				   &&
				   [[oldIdentity group] isEqualToString:[newIdentity group]])
				{
					continue;
				}
				[[oldIdentity retain] autorelease];
				[[groupsByName objectForKey:[oldIdentity group]] removeIdentity:oldIdentity];
				[oldIdentity setGroup:[newIdentity group]];
				[oldIdentity setName:[newIdentity name]];
				newIdentity = oldIdentity;
			}
			NSString * server = [jid domain];
			if(![queriedServers containsObject:server])
			{
				[queriedServers addObject:server];
				[disco featuresForJID:[JID jidWithString:server] node:nil];
			}
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
		}
	}
	//Once we have received the roster, tell the server we are online.
	if(!connected)
	{
		[[(XMPPAccount*)account connection] setStatus:initialStatus withMessage:initialMessage];
	}
	[self update:nil];
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
		{
			NSString * caps = [aPresence caps];
			if(caps != nil)
			{
				[disco setCapabilities:caps forJID:[aPresence jid]];		
			}
			//TODO: Make this temporarily add people to the roster when they bing-bong you. 
			break;
		}
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
	ETXMLWriter *xmlWriter = [connection xmlWriter];
	[xmlWriter startElement: @"iq"
	             attributes: D(@"set", @"type",
		                       [connection newMessageID], @"id")];
	[xmlWriter startElement: @"query"
	             attributes: D(@"jabber:iq:roster", @"xmlns")];
	[xmlWriter startElement: @"item"
	             attributes: D(_name, @"name", jidString, @"jid")];
	if(_group != nil && ![_group isEqualToString:@""])
	{
		[xmlWriter startAndEndElement: @"group"
		                        cdata: _group];
	}

	[xmlWriter endElement]; //</item>
	[xmlWriter endElement]; //</query>
	[xmlWriter endElement]; //</iq>
	//Add the group if one is specified
	
	[xmlWriter startAndEndElement: @"presence" 
	                   attributes: D(@"subscribe", @"type", jidString, @"to")];
}

- (void) unsubscribe:(JID*)_jid
{
	/*<iq type="set" id="aab7a" >
	<query xmlns="jabber:iq:roster">
	<item subscription="remove" jid="gimbo@theravensnest.org" />
	</query>
	</iq>*/
	ETXMLWriter *xmlWriter = [connection xmlWriter];
	[xmlWriter startElement: @"iq"
	             attributes: D(@"set", @"type",
	                           [connection newMessageID], @"id")];
	[xmlWriter startElement: @"query" 
	             attributes: D(@"jabber:iq:roster", @"xmlns")];
	[xmlWriter startAndEndElement: @"item" 
	                   attributes: D(@"remove", @"subscription",
	                                 [_jid jidString], @"jid")];
	[xmlWriter endElement]; //</query>
	[xmlWriter endElement]; //</iq>
}
- (void) authorise:(JID*)_jid
{
	ETXMLWriter *xmlWriter = [connection xmlWriter];
	[xmlWriter startAndEndElement: @"presence" 
	                   attributes: D(@"subscribed", @"type",
	                                 [_jid jidString], @"to")];
}


- (void) unauthorise:(JID*)_jid
{
	ETXMLWriter *xmlWriter = [connection xmlWriter];
	[xmlWriter startAndEndElement: @"presence" 
	                   attributes: D(@"unsubscribed", @"type", 
	                                 [_jid jidString], @"to")];
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
- (void)sendIqSettingGroup: (NSString*)aGroup
                      name: (NSString*)aName
                    forJID: (NSString*)aJID
{
	ETXMLWriter *xmlWriter = [connection xmlWriter];
	[xmlWriter startElement: @"iq"
	             attributes: D(@"set", @"type",
	                           [connection newMessageID], @"id")];
	[xmlWriter startElement: @"query"
	             attributes: D(@"jabber:iq:roster", @"xmlns")];
	[xmlWriter startElement: @"item"
	             attributes: D(aName, @"name", aJID, @"jid")];
	[xmlWriter startAndEndElement: @"group"
	                        cdata: aGroup];

	[xmlWriter endElement]; //</item>
	[xmlWriter endElement]; //</query>
	[xmlWriter endElement]; //</iq>
}


- (void) setName:(NSString*)aName group:(NSString*)aGroup forIdentity:(JabberIdentity*)anIdentity
{
	JabberPerson * person = [self personForJID:[anIdentity jid]];
	//Don't use this for people who aren't in our roster. 
	if(person == nil)
	{
		return;
	}
	[self sendIqSettingGroup: aGroup
	                    name: aName
	                  forJID: [[anIdentity jid] jidString]];
}

- (void) setGroup:(NSString*)aGroup forIdentity:(JabberIdentity*)anIdentity
{
	JabberPerson * person = [self personForJID:[anIdentity jid]];
	//Don't use this for people who aren't in our roster. 
	if(person == nil)
	{
		return;
	}
	[self sendIqSettingGroup: aGroup
	                    name: [person name]
	                  forJID: [[anIdentity jid] jidString]];
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
	if(_groupName == nil)
	{
		_groupName = @"None";
	}
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
- (Dispatcher*) dispatcher
{
	return dispatcher;
}
- (ServiceDiscovery*) disco
{
	return disco;
}
- (id) connection
{
	return connection;
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
