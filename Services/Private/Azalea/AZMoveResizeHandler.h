/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZMoveResizeHandler.h for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   moveresize.h for the Openbox window manager
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

@class AZClient;
@class AZPopUp;

@interface AZMoveResizeHandler: NSObject
{
  BOOL moveresize_in_progress;
  AZClient *moveresize_client;

  /* private */
  BOOL moving; /* TRUE - moving, FALSE - resizing */
  int start_x, start_y, start_cx, start_cy, start_cw, start_ch;
  int cur_x, cur_y;
  unsigned int button;
  unsigned int corner;
  ObCorner lockcorner;

  AZPopUp *popup;
}

+ (AZMoveResizeHandler *) defaultHandler;

- (void) startup: (BOOL) reconfig;
- (void) shutdown: (BOOL) reconfig;

- (void) startWithClient: (AZClient *) c x: (int) x y: (int) y
                  button: (unsigned int) button corner: (unsigned int) corner;
- (void) end: (BOOL) cancel;
- (void) event: (XEvent *) e;

/* accessories */
- (BOOL) moveresize_in_progress;
- (AZClient *) moveresize_client;

@end
