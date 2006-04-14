// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   screen.h for the Openbox window manager
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
#import "misc.h"
#import "geom.h"

@class AZClient;
@class AZPagerPopUp;

#define DESKTOP_ALL (0xffffffff)

typedef struct DesktopLayout {
    ObOrientation orientation;
    ObCorner start_corner;
    unsigned int rows;
    unsigned int columns;
} DesktopLayout;

@interface AZScreen: NSObject
{
  /*! The number of available desktops */
  unsigned int screen_num_desktops;
  /*! The number of virtual "xinerama" screens/heads */
  unsigned int screen_num_monitors;
  /*! The current desktop */
  unsigned int screen_desktop;
  /*! The desktop which was last visible */
  unsigned int screen_last_desktop;
  /*! Are we in showing-desktop mode? */
  BOOL screen_showing_desktop;
  /*! The support window also used for focus and stacking */
  Window screen_support_win;

  DesktopLayout screen_desktop_layout;

  /*! An array of gchar*'s which are desktop names in UTF-8 format */
  NSMutableArray *screen_desktop_names;

  /* Private */
  Rect  **area; /* array of desktop holding array of xinerama areas */
  Rect  *monitor_area;
  Size     screen_physical_size;
  AZPagerPopUp *desktop_cycle_popup;
}

+ (AZScreen *) defaultScreen;

/*! Take over the screen, set the basic hints on it claming it as ours */
- (BOOL) screenAnnex;

/*! Once the screen is ours, set up its initial state */
- (void) startup: (BOOL) reconfig;
/*! Free resources */
- (void) shutdown: (BOOL) reconfig;

/*! Figure out the new size of the screen and adjust stuff for it */
- (void) resize;

/*! Change the number of available desktops */
- (void) setNumberOfDesktops: (unsigned int) num;
- (unsigned int) numberOfDesktops;
/*! Change the current desktop */
- (void) setDesktop: (unsigned int) num;
- (unsigned int) desktop;
/*! Interactively change desktops */
- (unsigned int) cycleDesktop: (ObDirection) dir
                         wrap: (BOOL) wrap
		       linear: (BOOL) linear
		       dialog: (BOOL) dialog
		         done: (BOOL) done
		       cancel: (BOOL) cancel;

/*! Show/hide the desktop popup (pager) for the given desktop */
- (void) desktopPopup: (unsigned int) d
                 show: (BOOL) show;

/*! Shows and focuses the desktop and hides all the client windows, or
  returns to the normal state, showing client windows. */
- (void) showDesktop: (BOOL) show;
- (BOOL) showingDesktop;

/*! Updates the desktop layout from the root property if available */
- (void) updateLayout;

/*! Get desktop names from the root window property */
- (void) updateDesktopNames;

/*! Installs or uninstalls a colormap for a client. If client is NULL, then
  it handles the root colormap. */
- (void) installColormap: (AZClient*) client
                  install: (BOOL) install;

- (void) updateAreas;

- (Rect *) physicalArea;

- (Rect *) physicalAreaOfMonitor: (unsigned int) head;

- (Rect *) areaOfDesktop: (unsigned int) desktop;

- (Rect *) areaOfDesktop: (unsigned int) desktop
                 monitor: (unsigned int) head;

/*! Sets the root cursor. This function decides which cursor to use, but you
  gotta call it to let it know it should change. */
- (void) setRootCursor;

- (BOOL) pointerPosAtX: (int *) x y: (int *) y;

- (unsigned int) lastDesktop;

- (NSString *) nameOfDesktopAtIndex: (unsigned int) index;

- (Window) supportXWindow;

- (unsigned int) numberOfMonitors;

- (DesktopLayout) desktopLayout;

@end
