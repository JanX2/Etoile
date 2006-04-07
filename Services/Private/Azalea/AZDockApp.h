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

#import <Foundation/Foundation.h>
#import <X11/Xlib.h>
#import "window.h"

@interface AZDockApp: NSObject <NSCopying, AZWindow>
{
    int ignore_unmaps;

    Window icon_win;
    Window win;

    NSString *name;
    NSString *class;

    int x;
    int y;
    int w;
    int h;
}

- (void) drag: (XMotionEvent *) e;
- (void) configureWithWidth: (int) w height: (int) h;
- (void) grabButton: (BOOL) grab;

- (int) x;
- (int) y;
- (int) w;
- (int) h;
- (void) setX: (int) x;
- (void) setY: (int) y;
- (void) setW: (int) w;
- (void) setH: (int) h;

- (Window) window;
- (Window) iconWindow;
- (NSString *) name;
- (NSString *) class;
- (int) ignoreUnmaps;
- (void) setWindow: (Window) win;
- (void) setIconWindow: (Window) icon_win;
- (void) setName: (NSString *) name;
- (void) setClass: (NSString *) class;
- (void) setIgnoreUnmaps: (int) value;

@end

