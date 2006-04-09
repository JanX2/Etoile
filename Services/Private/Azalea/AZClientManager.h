// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   client.h for the Openbox window manager
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
#import "AZClient.h"

extern NSString *AZClientDestroyNotification;

@interface AZClientManager: NSObject
{
  NSMutableArray *clist;
}
+ (AZClientManager *) defaultManager;
- (void) startup: (BOOL) reconfig;
- (void) shutdown: (BOOL) reconfig;
/*! Manages all existing windows */
- (void) manageAll;
/*! Manages a given window */
- (void) manageWindow: (Window) win;
/*! Unmanages all managed windows */
- (void) unmanageAll;
/*! Unmanages a given client */
- (void) unmanageClient: (AZClient *) win;
/*! Sets the client list on the root window from the client_list */
- (void) setList;

/* Accessories */
- (AZClient *) clientAtIndex: (int) index;
- (int) count;
- (int) indexOfClient: (AZClient *) client;

@end
