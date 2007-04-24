/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZMoveResizeHandler.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   moveresize.c for the Openbox window manager
   Copyright (c) 2004        Mikael Magnusson
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

#import "AZMoveResizeHandler.h"
#import "AZScreen.h"
#import "AZClient.h"
#import "AZClient+Resist.h"
#import "AZClientManager.h"
#import "AZPopUp.h"
#import "grab.h"
#import "prop.h"
#import "openbox.h"
#import "config.h"
#import "render/render.h"
#import "render/theme.h"

static AZMoveResizeHandler *sharedInstance = nil;

@interface AZMoveResizeHandler (AZPrivate)

- (void) popupFormat: (NSString *) format a: (int) a b: (int) b;
- (void) doMove: (BOOL) resist;
- (void) doResize: (BOOL) resist;
- (void) clientDestroy: (NSNotification *) not;

@end

@implementation AZMoveResizeHandler

+ (AZMoveResizeHandler *) defaultHandler
{
  if (sharedInstance == nil)
  {
    sharedInstance = [[AZMoveResizeHandler alloc] init];
  }
  return sharedInstance;
}

- (id) init
{
  self = [super init];
  moving = NO;
  return self;
}

- (void) dealloc
{
  [super dealloc];
}

- (void) startup: (BOOL) reconfig
{
  popup = [[AZPopUp alloc] initWithIcon: NO];
  if (!reconfig) {
    [[NSNotificationCenter defaultCenter] addObserver: self
	    selector: @selector(clientDestroy:)
	    name: AZClientDestroyNotification
	    object: nil];
  }
}

- (void) shutdown: (BOOL) reconfig
{
  if (!reconfig) {
    if (moveresize_in_progress)
      [self end: NO];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
  }
  DESTROY(popup);
}

- (void) startWithClient: (AZClient *) c x: (int) x y: (int) y
                button: (unsigned int) b corner: (unsigned int) cnr
{
    ObCursor cur;

    moving = (cnr == prop_atoms.net_wm_moveresize_move ||
              cnr == prop_atoms.net_wm_moveresize_move_keyboard);

    if (moveresize_in_progress || ![[c frame] visible] ||
        !(moving ?
          ([c functions] & OB_CLIENT_FUNC_MOVE) :
          ([c functions] & OB_CLIENT_FUNC_RESIZE)))
        return;

    moveresize_client = c;
    start_cx = [[c frame] area].x;
    start_cy = [[c frame] area].y;
    /* these adjustments for the size_inc make resizing a terminal more
       friendly. you essentially start the resize in the middle of the
       increment instead of at 0, so you have to move half an increment
       either way instead of a full increment one and 1 px the other. and this
       is one large mother fucking comment. */
    start_cw = [c area].width + [c size_inc].width / 2;
    start_ch = [c area].height + [c size_inc].height / 2;
    start_x = x;
    start_y = y;
    corner = cnr;
    button = b;

    /*
      have to change start_cx and start_cy if going to do this..
    if (corner == prop_atoms.net_wm_moveresize_move_keyboard ||
        corner == prop_atoms.net_wm_moveresize_size_keyboard)
        XWarpPointer(ob_display, None, c->window, 0, 0, 0, 0,
                     c->area.width / 2, c->area.height / 2);
    */

    if (moving) {
        cur_x = start_cx;
        cur_y = start_cy;
    } else {
        cur_x = start_cw;
        cur_y = start_ch;
    }

    moveresize_in_progress = YES;

    if (corner == prop_atoms.net_wm_moveresize_size_topleft)
        cur = OB_CURSOR_NORTHWEST;
    else if (corner == prop_atoms.net_wm_moveresize_size_top)
        cur = OB_CURSOR_NORTH;
    else if (corner == prop_atoms.net_wm_moveresize_size_topright)
        cur = OB_CURSOR_NORTHEAST;
    else if (corner == prop_atoms.net_wm_moveresize_size_right)
        cur = OB_CURSOR_EAST;
    else if (corner == prop_atoms.net_wm_moveresize_size_bottomright)
        cur = OB_CURSOR_SOUTHEAST;
    else if (corner == prop_atoms.net_wm_moveresize_size_bottom)
        cur = OB_CURSOR_SOUTH;
    else if (corner == prop_atoms.net_wm_moveresize_size_bottomleft)
        cur = OB_CURSOR_SOUTHWEST;
    else if (corner == prop_atoms.net_wm_moveresize_size_left)
        cur = OB_CURSOR_WEST;
    else if (corner == prop_atoms.net_wm_moveresize_size_keyboard)
        cur = OB_CURSOR_SOUTHEAST;
    else if (corner == prop_atoms.net_wm_moveresize_move)
        cur = OB_CURSOR_MOVE;
    else if (corner == prop_atoms.net_wm_moveresize_move_keyboard)
        cur = OB_CURSOR_MOVE;
    else
	NSAssert(0, @"Should not reach here");

    grab_pointer(YES, NO, cur);
    grab_keyboard(YES);
}

- (void) end: (BOOL) cancel
{
    grab_keyboard(NO);
    grab_pointer(NO, NO, OB_CURSOR_NONE);

    [popup hide];

    if (moving) {
	[moveresize_client moveToX: (cancel ? start_cx : cur_x)
		                        y: (cancel ? start_cy : cur_y)];
    } else {
	[moveresize_client configureToCorner: lockcorner
		x: [moveresize_client area].x
		y: [moveresize_client area].y
		width: (cancel ? start_cw : cur_x)
		height: (cancel ? start_ch : cur_y)
		user: YES final: YES];
    }

    moveresize_in_progress = NO;
    moveresize_client = nil;
}

- (void) event: (XEvent *) e
{
    NSAssert(moveresize_in_progress, @"Not in moving or resizing");

    if (e->type == ButtonPress) {
        if (!button) {
            start_x = e->xbutton.x_root;
            start_y = e->xbutton.y_root;
            button = e->xbutton.button; /* this will end it now */
        }
    } else if (e->type == ButtonRelease) {
        if (!button || e->xbutton.button == button) {
	    [self end: NO];
        }
    } else if (e->type == MotionNotify) {
        if (moving) {
            cur_x = start_cx + e->xmotion.x_root - start_x;
            cur_y = start_cy + e->xmotion.y_root - start_y;
	    [self doMove: YES];
        } else {
            if (corner == prop_atoms.net_wm_moveresize_size_topleft) {
                cur_x = start_cw - (e->xmotion.x_root - start_x);
                cur_y = start_ch - (e->xmotion.y_root - start_y);
                lockcorner = OB_CORNER_BOTTOMRIGHT;
            } else if (corner == prop_atoms.net_wm_moveresize_size_top) {
                cur_x = start_cw;
                cur_y = start_ch - (e->xmotion.y_root - start_y);
                lockcorner = OB_CORNER_BOTTOMRIGHT;
            } else if (corner == prop_atoms.net_wm_moveresize_size_topright) {
                cur_x = start_cw + (e->xmotion.x_root - start_x);
                cur_y = start_ch - (e->xmotion.y_root - start_y);
                lockcorner = OB_CORNER_BOTTOMLEFT;
            } else if (corner == prop_atoms.net_wm_moveresize_size_right) { 
                cur_x = start_cw + (e->xmotion.x_root - start_x);
                cur_y = start_ch;
                lockcorner = OB_CORNER_BOTTOMLEFT;
            } else if (corner ==
                       prop_atoms.net_wm_moveresize_size_bottomright) {
                cur_x = start_cw + (e->xmotion.x_root - start_x);
                cur_y = start_ch + (e->xmotion.y_root - start_y);
                lockcorner = OB_CORNER_TOPLEFT;
            } else if (corner == prop_atoms.net_wm_moveresize_size_bottom) {
                cur_x = start_cw;
                cur_y = start_ch + (e->xmotion.y_root - start_y);
                lockcorner = OB_CORNER_TOPLEFT;
            } else if (corner ==
                       prop_atoms.net_wm_moveresize_size_bottomleft) {
                cur_x = start_cw - (e->xmotion.x_root - start_x);
                cur_y = start_ch + (e->xmotion.y_root - start_y);
                lockcorner = OB_CORNER_TOPRIGHT;
            } else if (corner == prop_atoms.net_wm_moveresize_size_left) {
                cur_x = start_cw - (e->xmotion.x_root - start_x);
                cur_y = start_ch;
                lockcorner = OB_CORNER_TOPRIGHT;
            } else if (corner == prop_atoms.net_wm_moveresize_size_keyboard) {
                cur_x = start_cw + (e->xmotion.x_root - start_x);
                cur_y = start_ch + (e->xmotion.y_root - start_y);
                lockcorner = OB_CORNER_TOPLEFT;
            } else
		NSAssert(0, @"Should not reach here");

	    [self doResize: YES];
        }
    } else if (e->type == KeyPress) {
        if (e->xkey.keycode == ob_keycode(OB_KEY_ESCAPE))
	    [self end: YES];
        else if (e->xkey.keycode == ob_keycode(OB_KEY_RETURN))
	    [self end: NO];
        else {
            if (corner == prop_atoms.net_wm_moveresize_size_keyboard) {
                int dx = 0, dy = 0, ox = cur_x, oy = cur_y;

                if (e->xkey.keycode == ob_keycode(OB_KEY_RIGHT))
                    dx = MAX(4, [moveresize_client size_inc].width);
                else if (e->xkey.keycode == ob_keycode(OB_KEY_LEFT))
                    dx = -MAX(4, [moveresize_client size_inc].width);
                else if (e->xkey.keycode == ob_keycode(OB_KEY_DOWN))
                    dy = MAX(4, [moveresize_client size_inc].height);
                else if (e->xkey.keycode == ob_keycode(OB_KEY_UP))
                    dy = -MAX(4, [moveresize_client size_inc].height);
                else
                    return;

                cur_x += dx;
                cur_y += dy;
                XWarpPointer(ob_display, None, None, 0, 0, 0, 0, dx, dy);
                /* steal the motion events this causes */
                XSync(ob_display, NO);
                {
                    XEvent ce;
                    while (XCheckTypedEvent(ob_display, MotionNotify, &ce));
                }

		[self doResize: NO];

                /* because the cursor moves even though the window does
                   not nessesarily (resistance), this adjusts where the curor
                   thinks it started so that it keeps up with where the window
                   actually is */
                start_x += dx - (cur_x - ox);
                start_y += dy - (cur_y - oy);
            } else if (corner == prop_atoms.net_wm_moveresize_move_keyboard) {
                int dx = 0, dy = 0, ox = cur_x, oy = cur_y;
                int opx, px, opy, py;
		AZScreen *screen = [AZScreen defaultScreen];

                if (e->xkey.keycode == ob_keycode(OB_KEY_RIGHT))
                    dx = 4;
                else if (e->xkey.keycode == ob_keycode(OB_KEY_LEFT))
                    dx = -4;
                else if (e->xkey.keycode == ob_keycode(OB_KEY_DOWN))
                    dy = 4;
                else if (e->xkey.keycode == ob_keycode(OB_KEY_UP))
                    dy = -4;
                else
                    return;

                cur_x += dx;
                cur_y += dy;
		[screen pointerPosAtX: &opx y: &opy];
                XWarpPointer(ob_display, None, None, 0, 0, 0, 0, dx, dy);
                /* steal the motion events this causes */
                XSync(ob_display, NO);
                {
                    XEvent ce;
                    while (XCheckTypedEvent(ob_display, MotionNotify, &ce));
                }
		[screen pointerPosAtX: &px y: &py];

		[self doMove: NO];

                /* because the cursor moves even though the window does
                   not nessesarily (resistance), this adjusts where the curor
                   thinks it started so that it keeps up with where the window
                   actually is */
                start_x += (px - opx) - (cur_x - ox);
                start_y += (py - opy) - (cur_y - oy);
            }
        }
    }
}

- (BOOL) moveresize_in_progress { return moveresize_in_progress; }
- (AZClient *) moveresize_client { return moveresize_client; }

@end

@implementation AZMoveResizeHandler (AZPrivate)

- (void) popupFormat: (NSString *) format a: (int) a b: (int) b;
{
    AZClient *c = moveresize_client;
    NSString *text;

    text = [NSString stringWithFormat: format, a, b];
    if (config_resize_popup_pos == 1) /* == "Top" */
	[popup positionWithGravity: SouthGravity
		x: [[c frame] area].x + [[c frame] area].width/2
		y: [[c frame] area].y];
    else /* == "Center" */
	[popup positionWithGravity: CenterGravity
	    x: [[c frame] area].x + [[c frame] size].left + [c area].width / 2
	    y: [[c frame] area].y + [[c frame] size].top + [c area].height / 2];

    [popup showText: text];
}

- (void) doMove: (BOOL) resist
{
    if (resist) {
	[moveresize_client resistMoveWindowsAtX: &cur_x y: &cur_y];
    	[moveresize_client resistMoveMonitorsAtX: &cur_x y: &cur_y];
    }

    /* get where the client should be */
    [[moveresize_client frame] frameGravityAtX: &cur_x y: &cur_y];
    [moveresize_client configureToCorner: OB_CORNER_TOPLEFT
	    x: cur_x y: cur_y
	    width: [moveresize_client area].width
	    height: [moveresize_client area].height
	    user: YES final: NO];
    if (config_resize_popup_show == 2) /* == "Always" */
	[self popupFormat: @"%d x %d"
                a: [[moveresize_client frame] area].x
                b: [[moveresize_client frame] area].y];
}

- (void) doResize: (BOOL) resist
{
    /* resist_size_* needs the frame size */
    cur_x += [[moveresize_client frame] size].left +
        [[moveresize_client frame] size].right;
    cur_y += [[moveresize_client frame] size].top +
        [[moveresize_client frame] size].bottom;

    if (resist) {
	[moveresize_client resistSizeWindowsWithWidth: &cur_x height: &cur_y corner: lockcorner];
    	[moveresize_client resistSizeMonitorsWithWidth: &cur_x height: &cur_y corner: lockcorner];
    }

    cur_x -= [[moveresize_client frame] size].left +
        [[moveresize_client frame] size].right;
    cur_y -= [[moveresize_client frame] size].top +
        [[moveresize_client frame] size].bottom;
 
    [moveresize_client configureToCorner: lockcorner
	    x: [moveresize_client area].x
	    y: [moveresize_client area].y
	    width: cur_x height: cur_y user: YES final: NO];

    /* this would be better with a fixed width font ... XXX can do it better
       if there are 2 text boxes */
    if (config_resize_popup_show == 2 || /* == "Always" */
            (config_resize_popup_show == 1 && /* == "Nonpixel" */
                ([moveresize_client size_inc].width > 1 ||
                 [moveresize_client size_inc].height > 1))
        )
	[self popupFormat: @"%d x %d"
              a: [moveresize_client logical_size].width
              b: [moveresize_client logical_size].height];
}

- (void) clientDestroy: (NSNotification *) not
{
  AZClient *client = [not object];
  if (moveresize_client == client)
    [self end: YES];
}

@end
