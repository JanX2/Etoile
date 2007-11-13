//
//  JabberPerson.m
//  Jabber
//
//  Created by David Chisnall on Sun Apr 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//
#import "JabberRootIdentity.h"
#import "JabberPerson.h"
#import "Dispatcher.h"
#import "Roster.h"
#import "CompareHack.h"
#import "XMPPConnection.h"
#import "../Macros.h"

@implementation JabberPerson
+ (id) jabberPersonWithIdentity:(JabberIdentity*)_identity forRoster:(id)_roster
{
	return [[[JabberPerson alloc] initWithIdentity:_identity forRoster:(id)_roster] autorelease];
}

- (void) calculateIdentityList
{
	[identityList removeAllObjects];
	FOREACH(identities, identity, JabberIdentity*)
	{
		[identityList addObject:identity];
		if([identity isKindOfClass:[JabberRootIdentity class]])
		{
			[identityList addObjectsFromArray:[(JabberRootIdentity*)identity resources]];
		}
	}
	//[identityList sortUsingSelector:@selector(compareByPriority:)];
	[identityList sortUsingFunction:compareByPriority context:nil];
	identityCount = [identityList count];
}

- (id) init
{
	SUPERINIT
	identities = [[NSMutableDictionary alloc] init];
	identityList = [[NSMutableArray alloc] init];	
	return self;
}

- (id) initWithIdentity:(JabberIdentity*)_identity forRoster:(id)_roster
{
	SELFINIT
	roster = _roster;
	[identities setValue:_identity forKey:[[_identity jid] jidString]];
	name = [_identity name];
	group = [_identity group];
	hash = [[NSString stringWithFormat:@"%@ some random wibble %@",name, group] hash];
	[_identity person:self];
	//Load the person's vCard
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary * vCards = [defaults dictionaryForKey:@"vCards"];
	NSString * vCardID = [vCards objectForKey:[NSString stringWithFormat:@"%@!%@", group, name]];
	if(vCardID != nil)
	{
		ABAddressBook * ab = [ABAddressBook sharedAddressBook];
		vCard = (ABPerson*)[[ab recordForUniqueId:vCardID] retain];
	}
	[self calculateIdentityList];
	return self;
}

- (void) addIdentity:(JabberIdentity*)anIdentity
{
	NSString * jidString = [[anIdentity jid] jidString];
	[anIdentity person:self];
	[identities setValue:anIdentity forKey:jidString];
	[self calculateIdentityList];
	//Request the identity's vcard
	if(vCard == nil)
	{
		XMPPConnection * connection = (id)[roster connection];
		NSString * vCardRequestID = [connection newMessageID];
		[connection XMPPSend:
		 [NSString stringWithFormat:@"<iq to='%@' type='get' id='%@'><vCard xmlns='vcard-temp'/></iq>"
		  , jidString, vCardRequestID]];
		[[roster dispatcher] addIqResultHandler:self forID:vCardRequestID];
	}
}

- (void) removeIdentity:(JabberIdentity*)_identity
{
	[identities removeObjectForKey:[[_identity jid] jidString]];
	[self calculateIdentityList];
}
- (NSString*) group
{
	return group;
}

- (void) group:(NSString*)_group
{
	[group release];
	group = [_group retain];
}

- (NSString*) name
{
	return name;
}

- (void) name:(NSString*)_name
{
	[name release];
	name = [_name retain];
}

- (JabberIdentity*) identityForJID:(JID*)jid
{
	JabberIdentity * identity = [identities objectForKey:[jid jidString]];
	if([jid type] == resourceJID)
	{
		if (identity == nil)
		{
			return [identities objectForKey:[jid jidStringWithNoResource]];
		}
	}
	return identity;
}

- (unsigned int) identities
{
	return identityCount;
}

- (JabberIdentity*) defaultIdentity
{
	return [identityList objectAtIndex:0];
}

- (NSArray*) identityList
{
	return identityList;
}

- (id)copyWithZone:(NSZone *)zone
{
	return self;
}

//Hash value is computed when the object is created, and so will remain constant throughout the lifespan of the object.
- (unsigned int) hash
{
	return hash;
}

- (void) handlePresence:(Presence*)aPresence
{
	NSString * from = [[aPresence jid] jidStringWithNoResource];
	
	JabberIdentity * identity = [identities objectForKey:from];
	
	NSNotificationCenter * notifier = [NSNotificationCenter defaultCenter];
	
	//Set the presence for the identity
	Presence * oldPresence = [[[self defaultIdentity] presence] retain];//Retain this in case changing the presence would cause it to be released
	[identity setPresence:aPresence];
	
	[self calculateIdentityList];
	//Notify anyone who cares that a new presence has been received if it results in the presence of this person changing
	if([oldPresence show] != [aPresence show]
	   ||
	   ![[oldPresence status] isEqualToString:[aPresence status]]
	   )
	{
		//TODO: Make each Identity do this as well
		NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt:[aPresence show]], @"NewPresence",
			[NSNumber numberWithInt:[oldPresence show]], @"OldPresence",
			[aPresence status], @"NewStatus",
			[oldPresence status], @"OldStatus",
			nil];
		[notifier postNotificationName:@"TRXMPPPresenceChanged" object:self userInfo:userInfo];			
	}
	[oldPresence release];
	[notifier postNotificationName:@"TRXMPPIdentityPresenceChanged" object:self userInfo:nil];
}

- (void) handleIq:(Iq*)anIq
{
	ABPerson * identityvCard = [[anIq children] objectForKey:@"vCard"];
	if(identityvCard != nil)
	{
		ABAddressBook * ab = [ABAddressBook sharedAddressBook];
		if(vCard != nil)
		{
			//TODO: Merge the vCard data
		}
		else
		{
			vCard = identityvCard;
			if([vCard valueForProperty:kABNicknameProperty] == nil)
			{
				[vCard setValue:name forProperty:kABNicknameProperty];
			}
			//TODO: Parse bridged JIDs correctly (i.e. parse 123456@icq.example.com 
			//as an ICQ UIN, not a JID)
			if([vCard valueForProperty:kABJabberInstantProperty] == nil)
			{
				ABMutableMultiValue * vCardJID = [[ABMutableMultiValue alloc] init];
				[vCardJID addValue:[[anIq jid] jidStringWithNoResource] withLabel:kABJabberHomeLabel];
				[vCard setValue:vCardJID forProperty:kABJabberInstantProperty];
				[vCardJID release];
			}
			//Get the group that contains Jabber people
			ABGroup * jabberGroup = nil;
			NSArray * groups = [ab groups];
			FOREACH(groups, abgroup, ABRecord*)
			{
				if([[abgroup valueForProperty:kABGroupNameProperty] isEqualToString:@"Jabber People"])
				{
					jabberGroup = (ABGroup*)abgroup;
				}
			}
			if(jabberGroup == nil)
			{
				jabberGroup = [[[ABGroup alloc] init] autorelease];
				[jabberGroup setValue:@"Jabber People" forProperty:kABGroupNameProperty];
				[ab addRecord:jabberGroup];
			}
			//
			[ab addRecord:vCard];
			[jabberGroup addMember:vCard];
			[ab save];
			NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
			NSDictionary * vCards = [defaults dictionaryForKey:@"vCards"];
			if(vCards == nil)
			{
				vCards = [NSDictionary dictionary];
			}			
			NSMutableDictionary * newvCards = [vCards mutableCopy];
			[newvCards setObject:[vCard uniqueId] forKey:[NSString stringWithFormat:@"%@!%@", group, name]];
			[defaults setObject:newvCards forKey:@"vCards"];
		}
	}
}

- (NSComparisonResult) compare:(JabberPerson*)otherPerson
{
	Presence * myDefaultPresence = [[self defaultIdentity] presence];
	unsigned char myPresence = myDefaultPresence == nil ? PRESENCE_UNKNOWN : [myDefaultPresence show];
	unsigned char otherPresence = [[[otherPerson defaultIdentity] presence] show];
	NSComparisonResult result;
	if (myPresence < otherPresence)
	{
		result = NSOrderedAscending;
	}
	else if (myPresence > otherPresence)
	{
		result = NSOrderedDescending;
	}
	else //if (myPresence == otherPresence)
	{
		result = [name caseInsensitiveCompare:[otherPerson name]];
		//result = NSOrderedSame;
	}
	//NSLog(@"Comparing %@(%d) to %@(%d) gives %d", name, (int)myPresence, [otherPerson name], (int)otherPresence, result);	
	return result;
}

- (NSImage*) avatar
{
	if(avatar == nil)
	{
		NSData * avatarData = [vCard imageData];
		if(avatarData != nil)
		{
			avatar = [[NSImage alloc] initWithData:avatarData];
		}
	}
	return avatar;
}

- (void) dealloc
{
	[group release];
	[name release];
	[identities release];
	[super dealloc];
}
@end
