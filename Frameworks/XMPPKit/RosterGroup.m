//
//  RosterGroup.m
//  Jabber
//
//  Created by David Chisnall on Sun Jul 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "RosterGroup.h"
#import "Presence.h"
#import "CompareHack.h"
#import <EtoileFoundation/EtoileFoundation.h>

@implementation RosterGroup
+ (id) groupWithRoster:(id)_roster
{
	return [[[RosterGroup alloc] initWithRoster:_roster] autorelease];
}

- (id) initWithRoster:(id)_roster
{
	[self init];
	roster = _roster;
	return self;
}

- (id) init
{
	roster = nil;
	peopleByName = [[NSMutableDictionary alloc] init];
	people = [[NSMutableArray alloc] init];
	return [super init];
}

- (NSString*) groupName
{
	return name;
}

- (void) groupName:(NSString*)_name
{
	[name release];
	name = [_name retain];
}

- (void) addIdentity:(JabberIdentity*)_identity
{
	JabberPerson * person = [peopleByName objectForKey:[_identity name]];
	if(person == nil)
	{
		person = [JabberPerson jabberPersonWithIdentity:_identity forRoster:roster];
		[peopleByName setObject:person forKey:[person name]];
		NSLog(@"Adding new person %@", [person name]);
		[people addObject:person];
		[people sortUsingFunction:compareTest context:nil];
	}
	else
	{
		[person addIdentity:_identity];
	}
}

- (void) removeIdentity:(JabberIdentity*)_identity
{
	JabberPerson * person = [peopleByName objectForKey:[_identity name]];
	[person removeIdentity:_identity];
	if([person identities] == 0)
	{
		NSLog(@"Removing person %@", [person name]);
		[people removeObject:person];
		[peopleByName removeObjectForKey:[person name]];
	}
}

- (JabberPerson*) personNamed:(NSString*)_name
{
	return [peopleByName objectForKey:_name];
}

- (unsigned int) numberOfPeopleInGroupMoreOnlineThan:(unsigned int)hide
{
	//Sort every time a UI tries to inspect us to make sure we are in a consistent order.

	if ([people count] > 1)
	{
//		[people sortUsingSelector:@selector(compare:)];
		//Ugly hack.  No idea why this works and the other version doesn't...
		[people sortUsingFunction:compareTest context:nil];
	}
		
	/*	if(hide > PRESENCE_UNKNOWN)
	{
		return [people count];
	}*/
	int count = 0;
	for(unsigned int i=0 ; i<[people count] ; i++)
	{
		JabberPerson* person = [people objectAtIndex:i];
		//NSLog(@"Person in group %@[%d]: %@ (%d)", name, i, [person name], (int)[[[person defaultIdentity] presence] show]);
		if([[[person defaultIdentity] presence] show] < hide)
		{
			count++;
		}
	}

	
	return count;
}

- (NSComparisonResult) compare:(RosterGroup*)otherGroup
{
	return [name caseInsensitiveCompare:[otherGroup groupName]];
}

- (JabberPerson*) personAtIndex:(unsigned int)_index
{
	if (_index < [people count])
		return [people objectAtIndex:_index];
	return nil;
}
@end
