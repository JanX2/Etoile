// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   focus.h for the Openbox window manager
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
#import "misc.h"
#import "render/render.h"

@class AZClient;
@class AZIconPopUp;

typedef enum {
    OB_FOCUS_FALLBACK_UNFOCUSING, /*!< forcefully remove focus from the
                                    current window */
    OB_FOCUS_FALLBACK_NOFOCUS     /*!< nothing has focus for some reason */
} ObFocusFallbackType;

@interface AZFocusManager: NSObject
{
  /*! The client which is currently focused */
  AZClient *focus_client;

  /*! The client which is being decorated as focused, not always matching the
    real focus, but this is used to track it so that it can be ersolved to match
  */
  AZClient *focus_hilite;

  /*! The client which appears focused during a focus cycle operation */
  AZClient *focus_cycle_target;

  /*! The recent focus order on each desktop */
  NSMutableArray *focus_order; /* these lists are created when screen_startup
                          sets the number of desktops */

  /* Private */
  RrAppearance *a_focus_indicator;
  RrColor *color_white;
  AZIconPopUp *focus_cycle_popup;
}

+ (AZFocusManager *) defaultManager;

- (void) startup: (BOOL) reconfig;
- (void) shutdown: (BOOL) reconfig;

/*! Specify which client is currently focused, this doesn't actually
  send focus anywhere, its called by the Focus event handlers */
- (void) setClient: (AZClient *) client;

- (AZClient *) fallbackTarget: (ObFocusFallbackType) type;

/*! Call this when you need to focus something! */
- (void) fallback: (ObFocusFallbackType) type;

/*! Cycle focus amongst windows. */
- (void) cycleForward: (BOOL) forward linear: (BOOL) linear
          interactive: (BOOL) interactive dialog: (BOOL) dialog
	  done: (BOOL) done cancel: (BOOL) cancel;
- (void) directionalCycle: (ObDirection) dir interactive: (BOOL) interactive
                 dialog: (BOOL) dialog done: (BOOL) done cancel: (BOOL) cancel;
- (void) cycleDrawIndicator;

/*! Add a new client into the focus order */
- (void) focusOrderAdd: (AZClient *) c;

/*! Remove a client from the focus order */
- (void) focusOrderRemove: (AZClient *) c;

/*! Move a client to the top of the focus order */
- (void) focusOrderToTop: (AZClient *) c;

/*! Move a client to the bottom of the focus order (keeps iconic windows at the
  very bottom always though). */
- (void) focusOrderToBottom: (AZClient *) c;

- (void) setNumberOfScreens: (int) num old: (int) old;
- (int) numberOfFocusOrderInScreen: (int) i;
- (AZClient *) focusOrder: (int) index inScreen: (int) i;

/* accessories */
- (void) set_focus_client: (AZClient *) focus_client;
- (void) set_focus_hilite: (AZClient *) focus_hilite;
- (void) set_focus_cycle_target: (AZClient *) focus_cycle_target;
- (AZClient *) focus_client;
- (AZClient *) focus_hilite;
- (AZClient *) focus_cycle_target;

@end
