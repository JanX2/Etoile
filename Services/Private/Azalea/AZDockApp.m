// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   dock.c for the Openbox window manager
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

#import "AZDock.h"
#import "AZDockApp.h"
#import "config.h"

@implementation AZDockApp

- (void) grabButton: (BOOL) grab
{
    if (grab) {
        grab_button_full(config_dock_app_move_button,
                         config_dock_app_move_modifiers, icon_win,
                         ButtonPressMask | ButtonReleaseMask |
                         ButtonMotionMask,
                         GrabModeAsync, OB_CURSOR_MOVE);
    } else {
        ungrab_button(config_dock_app_move_button,
                      config_dock_app_move_modifiers, icon_win);
    }
}

- (void) configureWithWidth: (int) width height: (int) height
{
    w = width;
    h = height;
    [[AZDock defaultDock] configure];
}

- (void) drag: (XMotionEvent *) e
{
    AZDock *dock = [AZDock defaultDock];
    AZDockApp *over = nil;
    int pos, i, count;
    int ex, ey;
    BOOL after;
    BOOL stop;

    ex = e->x_root;
    ey = e->y_root;

    /* are we on top of the dock? */
    if (!(ex >= [dock x] &&
          ey >= [dock y] &&
          ex < [dock x] + [dock w] &&
          ey < [dock y] + [dock h]))
        return;

    ex -= [dock x];
    ey -= [dock y];

    /* which dock app are we on top of? */
    stop = NO;
    count = [[dock dockApplications] count];
    for (i = 0; i < count; i++) {
	over = [[dock dockApplications] objectAtIndex: i];
	pos = i;
        switch (config_dock_orient) {
        case OB_ORIENTATION_HORZ:
            if (ex >= [over x] && ex < [over x] + [over w])
                stop = YES;
            break;
        case OB_ORIENTATION_VERT:
            if (ey >= [over y] && ey < [over y] + [over h])
                stop = YES;
            break;
        }
        /* dont go to it->next! */
        if (stop) break;
    }
    if ((i == count) || self == over) return;

    ex -= [over x];
    ey -= [over y];

    switch (config_dock_orient) {
    case OB_ORIENTATION_HORZ:
        after = (ex > [over w] / 2);
        break;
    case OB_ORIENTATION_VERT:
        after = (ey > [over h] / 2);
        break;
    }

    if (after) pos++;

    [dock moveDockApp: self toIndex: pos];
    [dock configure];
}

- (int) x { return x; }
- (int) y { return y; }
- (int) w { return w; }
- (int) h { return h; }
- (void) setX: (int) value { x = value; }
- (void) setY: (int) value { y = value; }
- (void) setW: (int) value { w = value; }
- (void) setH: (int) value { h = value; }

- (Window) window { return win; }
- (Window) iconWindow { return icon_win; }
- (NSString *) name { return name; }
- (NSString *) class { return class; }
- (int) ignoreUnmaps { return ignore_unmaps; }
- (void) setWindow: (Window) window { win = window; }
- (void) setIconWindow: (Window) window { icon_win = window; }
- (void) setName: (NSString *) n { ASSIGN(name, n); }
- (void) setClass: (NSString *) c { ASSIGN(class, c); }
- (void) setIgnoreUnmaps: (int) value { ignore_unmaps = value; }

- (void) dealloc
{
  DESTROY(name);
  DESTROY(class);
  [super dealloc];
}

- (id) copyWithZone: (NSZone *) zone
{
  RETAIN(self);
}

/* AZWindow protocol */
- (Window_InternalType) windowType { return Window_DockApp; }
- (int) windowLayer { g_assert_not_reached(); return 0; }
- (Window) windowTop { g_assert_not_reached(); return 0; }


@end
