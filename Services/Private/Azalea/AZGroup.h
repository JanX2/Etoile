// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   group.h for the Openbox window manager
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

#import <Foundation/Foundation.h>
#import <X11/Xlib.h>

@class AZClient;

@interface AZGroup: NSObject <NSCopying>
{
  Window leader;
  NSMutableArray *members;
}
- (void) setLeader: (Window) leader;
- (void) addMember: (AZClient *) client;
- (void) removeMember: (AZClient *) client;
- (Window) leader;
- (NSArray *) members;
- (AZClient *) memberAtIndex: (int) index;
- (int) indexOfMember: (AZClient *) client;
@end

@interface AZGroupManager: NSObject
+ (AZGroupManager *) defaultManager;
- (void) startup: (BOOL) reconfig;
- (void) shutdown: (BOOL) reconfig;
- (AZGroup *) addWindow: (Window) leader withClient: (AZClient *) client;
- (void) removeClient: (AZClient *) client fromGroup: (AZGroup *) group;
- (AZGroup *) groupWithLeader: (Window) leader;
@end

