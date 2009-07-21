//
//  JabberRootIdentity.m
//  Jabber
//
//  Created by David Chisnall on 02/08/2005.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "JabberRootIdentity.h"
#import "JabberResource.h"
#import "CompareHack.h"
#import <EtoileFoundation/EtoileFoundation.h>

@implementation JabberRootIdentity
- (void)findType
{
	NSString * serverDomain = [jid domain];
	switch([jid type])
	{
		case serverJID:
		case serverResourceJID:
		case invalidJID:
			basePriority = 0;
			break;
		case resourceJID:
		case userJID:
			//TODO: At some point, make this use Disco to find out what sort of server it really is.
			if(
			   ([serverDomain rangeOfString:@"msn"].location == NSNotFound) &&
			   ([serverDomain rangeOfString:@"icq"].location == NSNotFound) &&
			   ([serverDomain rangeOfString:@"aim"].location == NSNotFound) &&
			   ([serverDomain rangeOfString:@"yahoo"].location == NSNotFound)
			   )
			{
				basePriority = 0;
			}
			else
			{
				basePriority = -7;
			}
	}
	priority = basePriority;
}

- (id) initWithJID:(JID*)_jid withName:(NSString*)_name inGroup:(NSString*)_group forPerson:(id)_person
{
	if(!(self = [super initWithJID:_jid
			  withName:_name
			   inGroup:_group
			 forPerson:_person]))
	{
		return nil;
	}

	
	if([jid type] == resourceJID)
	{
		JID * childJID = jid;
		[self addResource:childJID];
		jid = [jid rootJID];
		[childJID release];
	}
	
	subscription = nil;
	[self findType];
	return self;
	
}

- (id) init
{
	SUPERINIT
	resources = [[NSMutableDictionary alloc] init];
	resourceList = [[NSMutableArray alloc] init];
	return self;
}

- (void) addResource:(JID*)_jid
{
	NSString * resourceName = [_jid resource];
	JabberResource * resource = [[[JabberResource alloc] initWithJID:_jid
															withName:name
															 inGroup:group
														   forPerson:person] autorelease];
	[resource setRoot:self];
	[resources setObject:resource forKey:resourceName];
	[resourceList addObject:resource];
	//[resourceList sortUsingSelector:@selector(compareByPriority)];
	[resourceList sortUsingFunction:compareByPriority context:nil];
}

- (NSArray*) resources
{
	return resourceList;
}

- (JabberIdentity*) identityForResource:(NSString*)resource
{
	return [resources objectForKey:resource];
}

- (void) setPresence:(Presence*)_presence
{
	JID * presenceJID = [_presence jid];
	//If we receive a presence stanza from the root JID, use that.
	if([presenceJID isEqualToJID:jid])
	{
		//If the root identity is offline, all resources are offline
		if([presence show] >= PRESENCE_OFFLINE)
		{
			[resources removeAllObjects];
		}
		[super setPresence:_presence];
	}
	else
	{
		NSString * resourceName = [presenceJID resource];
		//If this is an offline presence, remove the resource referenced by it
		if([_presence show] >= PRESENCE_OFFLINE)
		{
			[resourceList removeObjectIdenticalTo:[resources objectForKey:resourceName]];
			[resources removeObjectForKey:resourceName]; 
		}
		else
		{
			JabberResource * resource = [resources objectForKey:resourceName];
			//Create a JabberResource for the resource if one does not exist
			if(resource ==	nil)
			{
				[self addResource:presenceJID];
				resource = [resources objectForKey:resourceName];
			}
			[resource setPresence:_presence];
			//[resourceList sortUsingSelector:@selector(compareByPriority:)];
			[resourceList sortUsingFunction:compareByPriority context:nil];
		}
	}
}

- (Presence*) presence
{
	if([resourceList count] > 0)
	{
		return [[resourceList objectAtIndex:0] presence];
	}
	return presence;
}
@end
