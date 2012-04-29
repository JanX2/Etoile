//
//  XMPPRoster.m
//  Jabber
//
//  Created by David Chisnall on Sun Apr 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "XMPPRoster.h"
#import "XMPPAccount.h"
#import "XMPPPerson.h"
#import "XMPPRootIdentity.h"
#import "XMPPResource.h"
#import "CompareHack.h"
#import "XMPPServiceDiscovery.h"
#import <EtoileFoundation/EtoileFoundation.h>

@implementation XMPPRoster
- (XMPPRoster*) initWithAccount:(id)anAccount
{
	SUPERINIT
	if(![anAccount isKindOfClass: [XMPPAccount class]])
	{
		return nil;
	}
	account = anAccount;
	peopleByJID = [[NSMutableDictionary alloc] init];
	groups = [[NSMutableArray alloc] init];
	groupsByName = [[NSMutableDictionary alloc] init];
	queriedServers = [[NSMutableSet alloc] init];
	initialMessage = nil;
	initialStatus = PRESENCE_ONLINE;
	return self;
}

- (void) setInitialStatus:(unsigned char)aStatus withMessage:(NSString*)aMessage
{
	initialMessage = aMessage;
	initialStatus = aStatus;
}

- (void) offline
{
	FOREACH(peopleByJID, person, XMPPPerson*)
	{
		FOREACH([person identityList], identity, XMPPIdentity*)
		{
			XMPPPresence * unknownPresence = [[XMPPPresence alloc] initWithJID:[identity jid]];
			[identity setPresence:unknownPresence];
		}
	}
	connected = NO;
	//Trigger a roster redisplay when we go offline
	[delegate update:nil];
}

- (void) addRosterFromQuery:(XMPPInfoQueryStanza*) rosterQuery
{
	NSLog(@"Parsing roster...");
	connection = [(XMPPAccount*)account connection];
	dispatcher = [connection dispatcher];
	if(disco == nil)
	{
		disco = (XMPPServiceDiscovery*)[[XMPPServiceDiscovery alloc] initWithAccount:account];                
	}

	for (__strong XMPPIdentity *newIdentity in [[rosterQuery children] objectForKey:@"RosterItems"])
	{
		JID * jid = [newIdentity jid];
		if([[newIdentity subscription] isEqualToString:@"remove"])
		{
			XMPPPerson * person = [self personForJID:jid];
			XMPPIdentity * oldIdentity = [person identityForJID:jid];
			XMPPRosterGroup * group = [self groupNamed:[person group]];
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
			XMPPIdentity * oldIdentity = [[peopleByJID objectForKey:[jid jidString]] identityForJID:jid];
			if(oldIdentity != nil)
			{
				if([[oldIdentity name] isEqualToString:[newIdentity name]]  &&
                  [[oldIdentity group] isEqualToString:[newIdentity group]])
				{
					continue;
				}
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
				XMPPRosterGroup * group = [groupsByName objectForKey:groupName];
				if(group == nil)
				{
					group = [XMPPRosterGroup groupWithRoster:self];
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

- (void) handlePresence:(XMPPPresence*)aPresence
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
				[disco setCapabilities:caps forJID:[aPresence jid]];            			}
			//TODO: Make this temporarily add people to the roster when they bing-bong you. 
			break;
		}
		case unavailable:
		default:
			break;
	}
}

- (void) handleInfoQuery:(XMPPInfoQueryStanza*)anIq
{
	//NSLog(@"Children of iq node: %@", [anIq children]);
	if([[anIq children] objectForKey:@"RosterItems"] != nil)
		{
			[self addRosterFromQuery:anIq];
		}
}

- (void) subscribe:(JID*)aJid withName:(NSString*)aName inGroup:(NSString*)aGroup
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
	NSString * jidString = [aJid jidString];
	ETXMLWriter *xmlWriter = [connection xmlWriter];
	[xmlWriter startElement: @"iq"
	attributes: D(@"set", @"type", [connection nextMessageID], @"id")];
	[xmlWriter startElement: @"query"
                 attributes: D(@"jabber:iq:roster", @"xmlns")];
	[xmlWriter startElement: @"item"
                 attributes: D(aName, @"name", jidString, @"jid")];
	if(aGroup != nil && ![aGroup isEqualToString:@""])
	{
		[xmlWriter startAndEndElement: @"group"
                                cdata: aGroup];
	}

	[xmlWriter endElement]; //</item>
	[xmlWriter endElement]; //</query>
	[xmlWriter endElement]; //</iq>
	//Add the group if one is specified
	[xmlWriter startAndEndElement: @"presence" 
                       attributes: D(@"subscribe", @"type", jidString, @"to")];
}

- (void) unsubscribe:(JID*)aJid
{
	/*<iq type="set" id="aab7a" >
	<query xmlns="jabber:iq:roster">
	<item subscription="remove" jid="gimbo@theravensnest.org" />
	</query>
	</iq>*/
	ETXMLWriter *xmlWriter = [connection xmlWriter];
	[xmlWriter startElement: @"iq"
                 attributes: D(@"set", @"type",
	[connection nextMessageID], @"id")];
	[xmlWriter startElement: @"query" 
                 attributes: D(@"jabber:iq:roster", @"xmlns")];
	[xmlWriter startAndEndElement: @"item" 
                       attributes: D(@"remove", @"subscription", [aJid jidString], @"jid")];
	[xmlWriter endElement]; //</query>
	[xmlWriter endElement]; //</iq>
}
- (void) authorise:(JID*)aJid
{
	ETXMLWriter *xmlWriter = [connection xmlWriter];
	[xmlWriter startAndEndElement: @"presence" 
                       attributes: D(@"subscribed", @"type",[aJid jidString], @"to")];
}


- (void) unauthorise:(JID*)aJid
{
	ETXMLWriter *xmlWriter = [connection xmlWriter];
	[xmlWriter startAndEndElement: @"presence" 
                       attributes: D(@"unsubscribed", @"type",[aJid jidString], @"to")];
}


/*
 XMPPRoster updates look like this:
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
                 attributes: D(@"set", @"type",[connection nextMessageID], @"id")];
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


- (void) setName:(NSString*)aName group:(NSString*)aGroup forIdentity:(XMPPIdentity*)anIdentity
{
	XMPPPerson * person = [self personForJID:[anIdentity jid]];
	//Don't use this for people who aren't in our roster. 
	if(person == nil)
	{
		return;
	}
	[self sendIqSettingGroup: aGroup
                        name: aName
                      forJID: [[anIdentity jid] jidString]];
}

- (void) setGroup:(NSString*)aGroup forIdentity:(XMPPIdentity*)anIdentity
{
	XMPPPerson * person = [self personForJID:[anIdentity jid]];
	//Don't use this for people who aren't in our roster. 
	if(person == nil)
	{
		return;
	}
	[self sendIqSettingGroup: aGroup
                        name: [person name]
                      forJID: [[anIdentity jid] jidString]];
}

- (XMPPPerson*) personForJID:(JID*)aJid
{
	XMPPPerson * person = [peopleByJID objectForKey:[aJid jidStringWithNoResource]];
	if(person == nil)
	{
		XMPPRootIdentity * identity = [[XMPPRootIdentity alloc] initWithJID:[aJid rootJID]
                                                                   withName:[aJid node]
                                                                    inGroup:nil
                                                                  forPerson:nil];
		person = [[XMPPPerson alloc] initWithIdentity:identity
                                            forRoster:[account roster]];
		[identity person:person];
		if([aJid resource] != nil)
		{
			[identity addResource:aJid];
		}
		[peopleByJID setObject:person forKey:[aJid jidStringWithNoResource]];
		XMPPRosterGroup * group = [groupsByName objectForKey:@"None"];
		if(group == nil)
		{
			group = [XMPPRosterGroup groupWithRoster:self];
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

- (XMPPRosterGroup*) groupForIndex:(int)anIndex
{
	return [groups objectAtIndex:anIndex];
}
- (XMPPRosterGroup*) groupForIndex:(int)anIndex ignoringPeopleLessOnlineThan:(unsigned int)onlineState
{
	int count = -1;
	FOREACH(groups, group, XMPPRosterGroup*)
	{
		if([group numberOfPeopleInGroupMoreOnlineThan:onlineState] > 0)
		{
			count++;
			if(count == anIndex)
			{
				return group;
			}
		}
	}
	return nil;
}

- (XMPPRosterGroup*) groupNamed:(NSString*)aGroupName
{
	if(aGroupName == nil)
	{
		aGroupName = @"None";
	}
	return [groupsByName objectForKey:aGroupName];
}
- (int) numberOfGroups
{
	return [groups count];
}
//TODO: Fix typo in selector name
- (int) numberOfGroupsContainingPeopleMoreOnlineThan:(unsigned int)onlineState
{
	int count = 0;
	FOREACH(groups, group, XMPPRosterGroup*)
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

- (void) setDelegate:(id <RosterDelegate, NSObject>)aDelegate
{
	delegate = aDelegate;
}
- (XMPPDispatcher*) dispatcher
{
	return dispatcher;
}
- (XMPPServiceDiscovery*) disco
{
	return disco;
}
- (id) connection
{
	return connection;
}
- (void) update:(id)anObject
{
	[delegate update:anObject];
}
@end
