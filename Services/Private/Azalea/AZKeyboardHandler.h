/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZKeyboardHandler.h for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   keyboard.h for the Openbox window manager
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

@class AZAction;
@class AZClient;
@class AZKeyBindingTree;

@interface AZKeyboardHandler: NSObject
{
  AZKeyBindingTree *keyboard_firstnode;

  /* private */
  NSMutableArray *interactive_states;
  AZKeyBindingTree *curpos;
}

+ (AZKeyboardHandler *) defaultHandler;

- (void) startup: (BOOL) reconfig;
- (void) shutdown: (BOOL) reconfig;

- (BOOL) bind: (NSArray *) keylist action: (AZAction *) action;
- (void) unbindAll;

- (void) processEvent: (XEvent *) e forClient: (AZClient *) client;
- (void) resetChains;

- (BOOL) interactiveGrab: (unsigned int) state
                    client: (AZClient *) client
		    action: (AZAction *) action;
- (BOOL) processInteractiveGrab: (XEvent *) e
                      forClient: (AZClient **) client;
- (BOOL) interactivelyGrabbed;
- (void) grab: (BOOL) grab forClient: (AZClient *) client;

- (AZKeyBindingTree *) firstnode;
- (void) set_firstnode: (AZKeyBindingTree *) firstnode;

@end

