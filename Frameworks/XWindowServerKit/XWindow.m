/*
   XWindow.m for the Azalea window manager
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

#import "XWindow.h"
#import "prop.h"

@implementation XWindow
- (id) initWithContentRect: (NSRect)contentRect
                 styleMask: (unsigned int)aStyle
                   backing: (NSBackingStoreType)bufferingType
                     defer: (BOOL)flag
                    screen: (NSScreen*)aScreen
{
  self = [super initWithContentRect: contentRect
                 styleMask: aStyle
                   backing: bufferingType
                     defer: flag
                    screen: aScreen];

  server = GSCurrentServer();
  dpy = (Display*)[GSCurrentServer() serverDevice];
  screen = [[NSScreen mainScreen] screenNumber];
  root_win = RootWindow(dpy, screen);
  prop_startup(dpy);

  return self;
}

- (Window) xwindow
{
  if (!win)
  {
    win = *(Window *)[server windowDevice: [self windowNumber]];
  }
  return win;
}

- (void) setDesktop: (int) desktop
{
  /* stay in all desktops */
  prop_message(dpy, screen, [self xwindow], prop_atoms.net_wm_desktop, 
		  desktop, 0, 0, 0, 
		  SubstructureNotifyMask | SubstructureRedirectMask);
  //PROP_MSG([self xwindow], net_wm_desktop, desktop, 0, 0, 0);

  /* and in case window manager is not running */
  prop_set32(dpy, [self xwindow], prop_atoms.net_wm_desktop,
		  prop_atoms.cardinal, desktop);
//  PROP_SET32([self xwindow], net_wm_desktop, cardinal, desktop);
}

- (void) skipTaskbarAndPager
{
/*
  Atom *state = calloc(sizeof(Atom), 2);
  state[0] = prop_atoms.net_wm_state_skip_pager;
  state[1] = prop_atoms.net_wm_state_skip_taskbar;
  PROP_SETA32([self xwindow], net_wm_state, atom, state, 2);
  free(state);
*/
}

@end
