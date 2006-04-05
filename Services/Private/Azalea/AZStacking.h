// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   stacking.h for the Openbox window manager
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
#import "window.h"
#import <glib.h>
#import <X11/Xlib.h>

/*! The possible stacking layers a client window can be a part of */
typedef enum {
    OB_STACKING_LAYER_DESKTOP,     /*!< 0 - desktop windows */
    OB_STACKING_LAYER_BELOW,       /*!< 1 - normal windows w/ below */
    OB_STACKING_LAYER_NORMAL,      /*!< 2 - normal windows */
    OB_STACKING_LAYER_ABOVE,       /*!< 3 - normal windows w/ above */
    OB_STACKING_LAYER_FULLSCREEN,  /*!< 4 - fullscreeen windows */
    OB_STACKING_LAYER_INTERNAL,    /*!< 5 - openbox windows/menus */
    OB_NUM_STACKING_LAYERS
} ObStackingLayer;

@interface AZStacking: NSObject
{
  /* list of ObWindow*s in stacking order from highest to lowest */
  GList *stacking_list;
}

+ (AZStacking *) stacking;

/*! Sets the window stacking list on the root window from the
  stacking_list */
- (void) setList;

- (void) addWindow: (ObWindow *) win;
- (void) removeWindow: (ObWindow *) win;

/*! Raises a window above all others in its stacking layer */
- (void) raiseWindow: (ObWindow *) win group: (BOOL) group;

/*! Lowers a window below all others in its stacking layer */
- (void) lowerWindow: (ObWindow *) win group: (BOOL) group;

/*! Moves a window below another if its in the same layer.
  This function does not enforce stacking rules IRT transients n such, and so
  it should really ONLY be used to restore stacking orders from saved sessions
*/
- (void) moveWindow: (ObWindow *) window belowWindow: (ObWindow *) below;

/* Accessories */
- (int) count;
- (ObWindow *) windowAtIndex: (int) index;

@end

