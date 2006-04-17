/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZMouseHandler.h for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   mouse.h for the Openbox window manager
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
#import "action.h"
#import "misc.h"

#include <X11/Xlib.h>

@interface AZMouseHandler: NSObject
{
  /* Array of GSList*s of ObMouseBinding*s. */
  NSMutableArray *bound_contexts[OB_FRAME_NUM_CONTEXTS];
}
+ (AZMouseHandler *) defaultHandler;
- (void) startup: (BOOL) reconfig;
- (void) shutdown: (BOOL) reconfig;

- (BOOL) bind: (NSString *) buttonstr context: (NSString *) contextstr
           mouseAction: (ObMouseAction) mact action: (AZAction *) action;
- (void) unbindAll;
- (void) processEvent: (XEvent *) e forClient: (AZClient *) client;

- (void) grab: (BOOL) grab forClient: (AZClient *) client;

- (ObFrameContext) frameContext: (ObFrameContext) context withButton: (unsigned int) button;

@end
