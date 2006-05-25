/*
   XWindow.h for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

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

#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSDisplayServer.h>
#import <X11/Xlib.h>

/* allow accessing xwindow system */
@interface XWindow: NSWindow
{
  GSDisplayServer *server;
  Display *dpy;
  int screen;
  Window root_win, win;
}

/* If defer is NO when window is created. 
 * xwindow doesn't not exist until it is ordered front.
 * Better to set defer YES all the time. */
- (Window) xwindow;

/* Use ALL_DESTKTOP for all desktops */
- (void) setDesktop: (int) desktop;

/* Skip taskbar and pager */
- (void) skipTaskbarAndPager;

@end
