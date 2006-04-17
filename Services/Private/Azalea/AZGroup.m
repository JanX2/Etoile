/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZGroup.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   group.c for the Openbox window manager
   Copyright (c) 2003        Ben Jansens

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   See the COPYING file for a copy of the GNU General Public License.
*/

#import "AZGroup.h"
#import "AZClient.h"

static NSMutableDictionary *group_map;
static AZGroupManager *sharedInstance;

@implementation AZGroupManager

- (void) startup: (BOOL) reconfig
{
    if (reconfig) return;

    group_map = [[NSMutableDictionary alloc] init];
}

- (void) shutdown: (BOOL) reconfig
{
    if (reconfig) return;

    DESTROY(group_map);
}

- (AZGroup *) addWindow: (Window) leader withClient: (AZClient *) client
{
  AZGroup *group = nil;

  group = [group_map objectForKey: [NSNumber numberWithInt: leader]];
  if (group == nil) 
  {
    group = [[AZGroup alloc] init];
    [group setLeader: leader];
    [group_map setObject: group forKey: [NSNumber numberWithInt: leader]];
    RELEASE(group);
  }

  [group addMember: client];
  return group;
}

- (void) removeClient: (AZClient *) client fromGroup: (AZGroup *) group
{
  [group removeMember: client];
  if ([[group members] count] == 0)
  {
    Window leader = [group leader];
    [group_map removeObjectForKey: [NSNumber numberWithInt: leader]];
  }
}

- (AZGroup *) groupWithLeader: (Window) leader
{
  return [group_map objectForKey: [NSNumber numberWithInt: leader]];
}

+ (AZGroupManager *) defaultManager
{
  if (sharedInstance == nil)
  {
    sharedInstance = [[AZGroupManager alloc] init];
  }
  return sharedInstance;
}

@end

@implementation AZGroup

- (void) setLeader: (Window) l
{
  leader = l;
}

- (void) addMember: (AZClient *) client
{
  [members addObject: client];
}

- (void) removeMember: (AZClient *) client
{
  [members removeObject: client];
}

- (Window) leader
{
  return leader;
}

- (NSArray *) members
{
  return members;
}

- (AZClient *) memberAtIndex: (int) index
{
  if ((index < 0) || (index >= [members count]))
    return NULL;

  return [members objectAtIndex: index];
}

- (int) indexOfMember: (AZClient *) client
{
  return [members indexOfObject: client];
}

- (id) init
{
  self = [super init];
  members = [[NSMutableArray alloc] init];
  return self;
}

- (void) dealloc
{
  DESTROY(members);
  [super dealloc];
}

- (id) copyWithZone: (NSZone *) zone
{
  RETAIN(self);
}
@end
