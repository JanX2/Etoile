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

@class AZClient;

@interface AZEventHandler: NSObject <AZXHandler, NSCopying>
{
  /* The most recent time at which an event with a timestamp occured. */
  Time event_lasttime;
 /* The time for the current event being processed
    (it's the event_lasttime for events without times, if this is a bug then
    use CurrentTime instead, but it seems ok) */
  Time event_curtime;

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
}

+ (AZEventHandler *) defaultHandler;

- (void) startup: (BOOL) reconfig;
- (void) shutdown: (BOOL) reconfig;

/*! Make as if the mouse just entered the client, use only when using focus
  follows mouse */
- (void) enterClient: (AZClient *) client;

/*! Request that any queued EnterNotify events not be used for distributing
  focus */
- (void) ignoreQueuedEnters;

/* Halts any focus delay in progress, use this when the user is selecting a
   window for focus */
- (void) haltFocusDelay;

- (Time) eventCurrentTime;
- (unsigned int) numLockMask;
- (unsigned int) scrollLockMask;

@end

