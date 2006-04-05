// Modified Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   dock.h for the Openbox window manager
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

#ifndef __AZDock__
#define __AZDock__

#import <Foundation/Foundation.h>
#import "AZDockApp.h"
#import "render/render.h"
#import "window.h"
#import "X11/Xutil.h"
#import "geom.h"

@class AZDock;

/* use this to trick stacking */
struct _AZDockStruct
{
  Window_InternalType type;
  AZDock *dock;
};

@interface AZDock: NSObject
{
    ObWindow obwin;

    struct _AZDockStruct _self;

    Window frame;
    RrAppearance *a_frame;

    /* actual position (when not auto-hidden) */
    int x;
    int y;
    int w;
    int h;

    BOOL hidden;

    NSMutableArray *dock_apps;

    StrutPartial dock_strut;
}

+ (AZDock *) defaultDock;

- (void) startup: (BOOL) reconfig;
- (void) shutdown: (BOOL) reconfig;

- (void) configure;
- (void) setHide: (BOOL) hide;

- (void) addWindow: (Window) win hints: (XWMHints *) wmhints;
- (void) removeAll;
- (void) remove: (AZDockApp *) app reparent: (BOOL) reparent;

- (int) x;
- (int) y;
- (int) w;
- (int) h;
- (StrutPartial) strut;
- (Window) frame;

- (NSArray *) dockApplications;
- (void) moveDockApp: (AZDockApp *) app toIndex: (int) index;

- (struct _AZDockStruct *) _self;

@end

#endif
