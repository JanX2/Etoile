/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZEventHandler.h for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   event.h for the Openbox window manager
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
#import "AZMainLoop.h"

/* The time for the current event being processed */
extern Time event_curtime;

BOOL event_time_after(Time t1, Time t2);

@class AZClient;

@interface AZEventHandler: NSObject <AZXHandler, NSCopying>
{
  /*! The value of the mask for the NumLock modifier */
  unsigned int NumLockMask;

  /*! The value of the mask for the ScrollLock modifier */
  unsigned int ScrollLockMask;

  /* Private */
  /*! The key codes for the modifier keys */
  XModifierKeymap *modmap;

  int mask_table_size;

  unsigned int ignore_enter_focus;

  BOOL menu_can_hide;

  NSTimer *menuTimer;
}

+ (AZEventHandler *) defaultHandler;

- (void) startup: (BOOL) reconfig;
- (void) shutdown: (BOOL) reconfig;

/*! Request that any queued EnterNotify events not be used for distributing
  focus */
- (void) ignoreQueuedEnters;

- (void) setCurrentTime: (XEvent *) e;

- (unsigned int) numLockMask;
- (unsigned int) scrollLockMask;

@end

