/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZFocusManager.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   focus.c for the Openbox window manager
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

#import "AZScreen.h"
#import "AZEventHandler.h"
#import "AZDebug.h"
#import "AZGroup.h"
#import "AZClientManager.h"
#import "AZStacking.h"
#import "AZPopUp.h"
#import "AZFocusManager.h"
#import "openbox.h"
#import "grab.h"
#import "config.h"
#import "prop.h"
#import "render/render.h"
#import <assert.h>

struct {
    AZInternalWindow *top;
    AZInternalWindow *left;
    AZInternalWindow *right;
    AZInternalWindow *bottom;
} focus_indicator;

static Window createWindow(Window parent, unsigned long mask,
                           XSetWindowAttributes *attrib)
{
    return XCreateWindow(ob_display, parent, 0, 0, 1, 1, 0,
                         [ob_rr_inst depth], InputOutput,
                         [ob_rr_inst visual], mask, attrib);
                       
}

static AZFocusManager *sharedInstance;

@interface AZFocusManager (AZPrivate)

- (void) pushToTop: (AZClient *) client;
- (AZClient *) findTransientRecursive: (AZClient *) c : (AZClient *) top : (AZClient *) skip;
- (AZClient *) fallbackTransient: (AZClient *) top : (AZClient *) old;
- (void) popupCycle: (AZClient *) c show: (BOOL) show;
- (BOOL) validFocusTarget: (AZClient *) ft;
- (void) toTop: (AZClient *) c desktop: (unsigned int) d;
- (void) toBottom: (AZClient *) c desktop: (unsigned int) d;
- (void) clientDestroy: (NSNotification *) not;

@end

@implementation AZFocusManager

- (void) startup: (BOOL) reconfig
{
    focus_cycle_popup = [[AZIconPopUp alloc] initWithIcon: YES];

    if (!reconfig) {
        XSetWindowAttributes attr;
	AZStacking *stacking = [AZStacking stacking];

	[[NSNotificationCenter defaultCenter] addObserver: self
		selector: @selector(clientDestroy:)
		name: AZClientDestroyNotification
		object: nil];

        /* start with nothing focused */
	[self setClient: nil];

        focus_indicator.top = [[AZInternalWindow alloc] init];
        focus_indicator.left = [[AZInternalWindow alloc] init];
        focus_indicator.right = [[AZInternalWindow alloc] init];
        focus_indicator.bottom = [[AZInternalWindow alloc] init];

        attr.override_redirect = True;
        attr.background_pixel = BlackPixel(ob_display, ob_screen);
        [focus_indicator.top set_window: 
            createWindow(RootWindow(ob_display, ob_screen),
                         CWOverrideRedirect | CWBackPixel, &attr)];
        [focus_indicator.left set_window:
            createWindow(RootWindow(ob_display, ob_screen),
                         CWOverrideRedirect | CWBackPixel, &attr)];
        [focus_indicator.right set_window:
            createWindow(RootWindow(ob_display, ob_screen),
                         CWOverrideRedirect | CWBackPixel, &attr)];
        [focus_indicator.bottom set_window:
            createWindow(RootWindow(ob_display, ob_screen),
                         CWOverrideRedirect | CWBackPixel, &attr)];

        [stacking addWindow: focus_indicator.top];
        [stacking addWindow: focus_indicator.left];
        [stacking addWindow: focus_indicator.right];
        [stacking addWindow: focus_indicator.bottom];

        color_white = RrColorNew(ob_rr_inst, 0xff, 0xff, 0xff);

        a_focus_indicator = [[AZAppearance alloc] initWithInstance: ob_rr_inst numberOfTextures: 4];
        [a_focus_indicator surfacePointer]->grad = RR_SURFACE_SOLID;
        [a_focus_indicator surfacePointer]->relief = RR_RELIEF_FLAT;
        [a_focus_indicator surfacePointer]->primary = RrColorNew(ob_rr_inst,
                                                        0, 0, 0);
        [a_focus_indicator texture][0].type = RR_TEXTURE_LINE_ART;
        [a_focus_indicator texture][0].data.lineart.color = color_white;
        [a_focus_indicator texture][1].type = RR_TEXTURE_LINE_ART;
        [a_focus_indicator texture][1].data.lineart.color = color_white;
        [a_focus_indicator texture][2].type = RR_TEXTURE_LINE_ART;
        [a_focus_indicator texture][2].data.lineart.color = color_white;
        [a_focus_indicator texture][3].type = RR_TEXTURE_LINE_ART;
        [a_focus_indicator texture][3].data.lineart.color = color_white;
    }
}

- (void) shutdown: (BOOL) reconfig
{
    unsigned int i;
    unsigned int count = [[AZScreen defaultScreen] numberOfDesktops];

    DESTROY(focus_cycle_popup);

    if (!reconfig) {
	[[NSNotificationCenter defaultCenter] removeObserver: self];

        for (i = 0; i < count; ++i)
	    [[focus_order objectAtIndex: i] removeAllObjects];
	[focus_order removeAllObjects];

        /* reset focus to root */
        XSetInputFocus(ob_display, PointerRoot, RevertToNone, CurrentTime);

        RrColorFree(color_white);

        DESTROY(a_focus_indicator);

        XDestroyWindow(ob_display, [focus_indicator.top window]);
        XDestroyWindow(ob_display, [focus_indicator.left window]);
        XDestroyWindow(ob_display, [focus_indicator.right window]);
        XDestroyWindow(ob_display, [focus_indicator.bottom window]);

	DESTROY(focus_indicator.top);
	DESTROY(focus_indicator.left);
	DESTROY(focus_indicator.right);
	DESTROY(focus_indicator.bottom);
    }
}

- (void) setClient: (AZClient *) client
{
    Window active;
    AZClient *old;
    AZScreen *screen = [AZScreen defaultScreen];

#ifdef DEBUG_FOCUS
    AZDebug("focus_set_client 0x%lx\n", client ? [client window] : 0);
#endif

    /* uninstall the old colormap, and install the new one */
    [screen installColormap: focus_client install: NO];
    [screen installColormap: client install: YES];

    if (client == nil) {
#ifdef DEBUG_FOCUS
        AZDebug("actively focusing NONWINDOW\n");
#endif
        /* when nothing will be focused, send focus to the backup target */
        XSetInputFocus(ob_display, [screen supportXWindow], RevertToNone,
                       [[AZEventHandler defaultHandler] eventCurrentTime]);
        XSync(ob_display, NO);
    }

    /* in the middle of cycling..? kill it. */
    if (focus_cycle_target)
	[self cycleForward: YES linear: YES interactive: YES
	      dialog: YES done: YES cancel: YES opaque: NO];

    old = focus_client;
    focus_client = client;

    /* move to the top of the list */
    if (client != nil)
	[self pushToTop: client];

    /* set the NET_ACTIVE_WINDOW hint, but preserve it on shutdown */
    if (ob_state() != OB_STATE_EXITING) {
        active = client ? [client window] : None;
        PROP_SET32(RootWindow(ob_display, ob_screen),
                   net_active_window, window, active);

        /* remove hiliting from the window when it gets focused */
        if (client != nil)
            [client hilite: NO];
    }
}

- (AZClient *) fallbackTarget: (ObFocusFallbackType) type
{
    AZClient *old = nil;
    AZClient *target = nil;
    AZScreen *screen = [AZScreen defaultScreen];

    old = focus_client;

    if ((type == OB_FOCUS_FALLBACK_UNFOCUSING ||
	 type == OB_FOCUS_FALLBACK_CLOSED) && old) {
        if ([old transient_for]) {
            BOOL trans = NO;

            if (!config_focus_follow || config_focus_last)
                trans = YES;
            else {
                if ((target = AZUnderPointer()) &&
	            [[target searchTopTransient] searchTransient: old])
                {
                    trans = YES;
                }
            }

            /* try for transient relations */
            if (trans) {
                if ([old transient_for] == OB_TRAN_GROUP) {
		    NSArray *order = [focus_order objectAtIndex: [screen desktop]];
		    int j, jcount = [order count];
		    for (j = 0; j < jcount; j++) 
                    {
	                int i, count = [[[old group] members] count];
			for (i = 0; i < count; i++) {
			  AZClient *data = [[old group] memberAtIndex: i];
                          if (data == [order objectAtIndex: j])
                                if ((target =
				     [self fallbackTransient: data : old]))
                                    return target;
                        }
                    }
                } else {
                    if ((target =
			 [self fallbackTransient: [old transient_for] : old]))
                        return target;
                }
            }
        }
    }

    if (config_focus_follow && 
	(type == OB_FOCUS_FALLBACK_UNFOCUSING || !config_focus_last)) {
        if ((target = AZUnderPointer()))
            if ([target normal] && [target canFocus])
                return target;
    }

    NSArray *karray = [focus_order objectAtIndex: [screen desktop]];
    int k, kcount =  [karray count];
    for (k = 0; k < kcount; k++) {
	AZClient *c = [karray objectAtIndex: k];
        if (type != OB_FOCUS_FALLBACK_UNFOCUSING || c != old)
            if ([c normal] && [c canFocus])
                return c;
    }

    /* XXX fallback to the "desktop window" if one exists ?
       could store it while going through all the windows in the loop right
       above this..
    */

    return nil;
}

- (void) fallback: (ObFocusFallbackType) type
{
    AZClient *new;

    /* unfocus any focused clients.. they can be focused by Pointer events
       and such, and then when I try focus them, I won't get a FocusIn event
       at all for them.
    */
    [self setClient: nil];

    if ((new = [self fallbackTarget: type]))
	[new focus];
}

- (void) cycleDrawIndicator
{
    if (!focus_cycle_target) {
        XUnmapWindow(ob_display, [focus_indicator.top window]);
        XUnmapWindow(ob_display, [focus_indicator.left window]);
        XUnmapWindow(ob_display, [focus_indicator.right window]);
        XUnmapWindow(ob_display, [focus_indicator.bottom window]);
    } else {
        int x, y, w, h;
        int wt, wl, wr, wb;

        wt = wl = wr = wb = MAX(3,
                                ob_rr_theme->handle_height +
                                ob_rr_theme->bwidth * 2);

        x = [[focus_cycle_target frame] area].x;
        y = [[focus_cycle_target frame] area].y;
        w = [[focus_cycle_target frame] area].width;
        h = wt;

        XMoveResizeWindow(ob_display, [focus_indicator.top window],
                          x, y, w, h);
        [a_focus_indicator texture][0].data.lineart.x1 = 0;
        [a_focus_indicator texture][0].data.lineart.y1 = h-1;
        [a_focus_indicator texture][0].data.lineart.x2 = 0;
        [a_focus_indicator texture][0].data.lineart.y2 = 0;
        [a_focus_indicator texture][1].data.lineart.x1 = 0;
        [a_focus_indicator texture][1].data.lineart.y1 = 0;
        [a_focus_indicator texture][1].data.lineart.x2 = w-1;
        [a_focus_indicator texture][1].data.lineart.y2 = 0;
        [a_focus_indicator texture][2].data.lineart.x1 = w-1;
        [a_focus_indicator texture][2].data.lineart.y1 = 0;
        [a_focus_indicator texture][2].data.lineart.x2 = w-1;
        [a_focus_indicator texture][2].data.lineart.y2 = h-1;
        [a_focus_indicator texture][3].data.lineart.x1 = (wl-1);
        [a_focus_indicator texture][3].data.lineart.y1 = h-1;
        [a_focus_indicator texture][3].data.lineart.x2 = w - wr;
        [a_focus_indicator texture][3].data.lineart.y2 = h-1;
        [a_focus_indicator paint: [focus_indicator.top window] width: w height: h];

        x = [[focus_cycle_target frame] area].x;
        y = [[focus_cycle_target frame] area].y;
        w = wl;
        h = [[focus_cycle_target frame] area].height;

        XMoveResizeWindow(ob_display, [focus_indicator.left window],
                          x, y, w, h);
        [a_focus_indicator texture][0].data.lineart.x1 = w-1;
        [a_focus_indicator texture][0].data.lineart.y1 = 0;
        [a_focus_indicator texture][0].data.lineart.x2 = 0;
        [a_focus_indicator texture][0].data.lineart.y2 = 0;
        [a_focus_indicator texture][1].data.lineart.x1 = 0;
        [a_focus_indicator texture][1].data.lineart.y1 = 0;
        [a_focus_indicator texture][1].data.lineart.x2 = 0;
        [a_focus_indicator texture][1].data.lineart.y2 = h-1;
        [a_focus_indicator texture][2].data.lineart.x1 = 0;
        [a_focus_indicator texture][2].data.lineart.y1 = h-1;
        [a_focus_indicator texture][2].data.lineart.x2 = w-1;
        [a_focus_indicator texture][2].data.lineart.y2 = h-1;
        [a_focus_indicator texture][3].data.lineart.x1 = w-1;
        [a_focus_indicator texture][3].data.lineart.y1 = wt-1;
        [a_focus_indicator texture][3].data.lineart.x2 = w-1;
        [a_focus_indicator texture][3].data.lineart.y2 = h - wb;
        [a_focus_indicator paint: [focus_indicator.left window] width: w height:  h];
        x = [[focus_cycle_target frame] area].x +
            [[focus_cycle_target frame] area].width - wr;
        y = [[focus_cycle_target frame] area].y;
        w = wr;
        h = [[focus_cycle_target frame] area].height ;

        XMoveResizeWindow(ob_display, [focus_indicator.right window],
                          x, y, w, h);
        [a_focus_indicator texture][0].data.lineart.x1 = 0;
        [a_focus_indicator texture][0].data.lineart.y1 = 0;
        [a_focus_indicator texture][0].data.lineart.x2 = w-1;
        [a_focus_indicator texture][0].data.lineart.y2 = 0;
        [a_focus_indicator texture][1].data.lineart.x1 = w-1;
        [a_focus_indicator texture][1].data.lineart.y1 = 0;
        [a_focus_indicator texture][1].data.lineart.x2 = w-1;
        [a_focus_indicator texture][1].data.lineart.y2 = h-1;
        [a_focus_indicator texture][2].data.lineart.x1 = w-1;
        [a_focus_indicator texture][2].data.lineart.y1 = h-1;
        [a_focus_indicator texture][2].data.lineart.x2 = 0;
        [a_focus_indicator texture][2].data.lineart.y2 = h-1;
        [a_focus_indicator texture][3].data.lineart.x1 = 0;
        [a_focus_indicator texture][3].data.lineart.y1 = wt-1;
        [a_focus_indicator texture][3].data.lineart.x2 = 0;
        [a_focus_indicator texture][3].data.lineart.y2 = h - wb;
        [a_focus_indicator paint: [focus_indicator.right window] width: w height: h];

        x = [[focus_cycle_target frame] area].x;
        y = [[focus_cycle_target frame] area].y +
            [[focus_cycle_target frame] area].height - wb;
        w = [[focus_cycle_target frame] area].width;
        h = wb;

        XMoveResizeWindow(ob_display, [focus_indicator.bottom window],
                          x, y, w, h);
        [a_focus_indicator texture][0].data.lineart.x1 = 0;
        [a_focus_indicator texture][0].data.lineart.y1 = 0;
        [a_focus_indicator texture][0].data.lineart.x2 = 0;
        [a_focus_indicator texture][0].data.lineart.y2 = h-1;
        [a_focus_indicator texture][1].data.lineart.x1 = 0;
        [a_focus_indicator texture][1].data.lineart.y1 = h-1;
        [a_focus_indicator texture][1].data.lineart.x2 = w-1;
        [a_focus_indicator texture][1].data.lineart.y2 = h-1;
        [a_focus_indicator texture][2].data.lineart.x1 = w-1;
        [a_focus_indicator texture][2].data.lineart.y1 = h-1;
        [a_focus_indicator texture][2].data.lineart.x2 = w-1;
        [a_focus_indicator texture][2].data.lineart.y2 = 0;
        [a_focus_indicator texture][3].data.lineart.x1 = wl-1;
        [a_focus_indicator texture][3].data.lineart.y1 = 0;
        [a_focus_indicator texture][3].data.lineart.x2 = w - wr;
        [a_focus_indicator texture][3].data.lineart.y2 = 0;
        [a_focus_indicator paint: [focus_indicator.bottom window] width: w height: h];

        XMapWindow(ob_display, [focus_indicator.top window]);
        XMapWindow(ob_display, [focus_indicator.left window]);
        XMapWindow(ob_display, [focus_indicator.right window]);
        XMapWindow(ob_display, [focus_indicator.bottom window]);
    }
}

- (void) cycleForward: (BOOL) forward linear: (BOOL) linear
          interactive: (BOOL) interactive dialog: (BOOL) dialog
	         done: (BOOL) done cancel: (BOOL) cancel 
               opaque: (BOOL) opaque
{
    static AZClient *first = nil;
    static AZClient *t = nil;
    NSArray *list = nil;
    AZClient *ft = nil;
    AZScreen *screen = [AZScreen defaultScreen];
    BOOL use_clist = NO;

    if (interactive) {
        if (cancel) {
            focus_cycle_target = nil;
            goto done_cycle;
        } else if (done)
            goto done_cycle;

        if ([(NSArray *)[focus_order objectAtIndex: [screen desktop]] count] == 0)
            goto done_cycle;

        if (!first) first = focus_client;

        if (linear) 
	{
	  use_clist = YES;
	  list = nil;
	}
        else        
	{
	  use_clist = NO;
	  list = [focus_order objectAtIndex: [screen desktop]];
	}
    } else {
        if ([(NSArray *)[focus_order objectAtIndex: [screen desktop]] count] == 0)
            goto done_cycle;
	use_clist = YES;
	list = nil;
    }
    if (!focus_cycle_target) focus_cycle_target = focus_client;

    if (use_clist)
    {
      AZClientManager *cManager = [AZClientManager defaultManager];
      int c_start = NSNotFound, c_index = NSNotFound;
      int count = [cManager count];
      int temp = [cManager indexOfClient: focus_cycle_target];
      if (temp == NSNotFound) /* switched desktops or something ? */
      {
	if (count == 0) goto done_cycle;
        if (forward)
	{
          c_start = c_index = count-1;
	}
	else
	{
	  c_start = c_index = 0;
	}
      }
      else
      {
        c_start = c_index = temp;
      }

      do {
        if (forward)
	{
	  c_index++;
	  if (c_index >= count) c_index = 0;
	}
	else
	{
	  c_index--;
	  if (c_index < 0) c_index = count-1;
	}

	ft = [cManager clientAtIndex: c_index];
	if ([self validFocusTarget: ft]) {
            if (interactive) {
	        if (ft != focus_cycle_target) { /* prevents flicker */
	            focus_cycle_target = ft;
		    if (opaque == YES)
		      [focus_cycle_target raise];
		    [self cycleDrawIndicator];
	        }
		[self popupCycle: ft show: dialog];
	        return;
	    } else if (ft != focus_cycle_target) {
	        focus_cycle_target = ft;
	        done = YES;
	        break;
	    }
        }
      } while (c_index != c_start);
    }
    else
    {
      int c_start = NSNotFound, c_index = NSNotFound;
      int count = [list count];
      int temp = [list indexOfObject: focus_cycle_target];
      if (temp == NSNotFound) /* switched desktops or something ? */
      {
	if (count == 0) goto done_cycle;
        if (forward)
	{
          c_start = c_index = count-1;
	}
	else
	{
	  c_start = c_index = 0;
	}
      }
      else
      {
        c_start = c_index = temp;
      }

      do {
        if (forward)
	{
	  c_index++;
	  if (c_index >= count) c_index = 0;
	}
	else
	{
	  c_index--;
	  if (c_index < 0) c_index = count-1;
	}

	ft = [list objectAtIndex: c_index];
	if ([self validFocusTarget: ft]) {
            if (interactive) {
	        if (ft != focus_cycle_target) { /* prevents flicker */
	            focus_cycle_target = ft;
		    if (opaque == YES)
		      [focus_cycle_target raise];
		    [self cycleDrawIndicator];
	        }
		[self popupCycle: ft show: dialog];
	        return;
	    } else if (ft != focus_cycle_target) {
	        focus_cycle_target = ft;
	        done = YES;
	        break;
	    }
        }
      } while (c_index != c_start);
    }

done_cycle:
    if (done && focus_cycle_target)
	[focus_cycle_target activateHere: NO user: YES];

    t = nil;
    first = nil;
    focus_cycle_target = nil;

    if (interactive) {
	[self cycleDrawIndicator];
	[self popupCycle: ft show: NO];
    }

    return;
}

- (void) directionalCycle: (ObDirection) dir interactive: (BOOL) interactive
                 dialog: (BOOL) dialog done: (BOOL) done cancel: (BOOL) cancel
{
    static AZClient *first = nil;
    AZClient *ft = nil;
    AZScreen *screen = [AZScreen defaultScreen];

    if (!interactive)
        return;

    if (cancel) {
        focus_cycle_target = nil;
        goto done_cycle;
    } else if (done)
        goto done_cycle;

    if ([(NSArray *)[focus_order objectAtIndex: [screen desktop]] count] == 0)
        goto done_cycle;

    if (!first) first = focus_client;
    if (!focus_cycle_target) focus_cycle_target = focus_client;

    if (focus_cycle_target)
	ft = [focus_cycle_target findDirectional: dir];
    else {
	NSArray *order = [focus_order objectAtIndex: [screen desktop]];
	int i, count = [order count];
	for (i = 0; i < count; i++) {
	  AZClient *c = [order objectAtIndex: i];
          if ([self validFocusTarget: c])
                ft = c;
	}
    }
        
    if (ft) {
        if (ft != focus_cycle_target) {/* prevents flicker */
            focus_cycle_target = ft;
	    [self cycleDrawIndicator];
        }
    }
    if (focus_cycle_target) {
	[self popupCycle: focus_cycle_target show: dialog];
        if (dialog)
            return;
    }


done_cycle:
    if (done && focus_cycle_target)
	[focus_cycle_target activateHere: NO user: YES];

    first = nil;
    focus_cycle_target = nil;

    [self cycleDrawIndicator];
    [self popupCycle: ft show: NO];

    return;
}

- (void) focusOrderAdd: (AZClient *) c
{
    unsigned int d, i;
    unsigned int count = [[AZScreen defaultScreen] numberOfDesktops];

    if ([c iconic])
	[self focusOrderToTop: c];
    else {
        d = [c desktop];
        if (d == DESKTOP_ALL) {
            for (i = 0; i < count; ++i) {
		NSMutableArray *order = [focus_order objectAtIndex: i];
		NSAssert([order indexOfObject: c] == NSNotFound, @"Client exists in focus_order already.");
	        if ([order count] && [[order objectAtIndex: 0] iconic])
		    [order insertObject: c atIndex: 0];
		else if ([order count] == 0)
		    [order addObject: c];
		else {
		    [order insertObject: c atIndex: 1];
		}
            }
        } else {
	    NSMutableArray *order = [focus_order objectAtIndex: d];
	    NSAssert([order indexOfObject: c] == NSNotFound, @"Client exists in focus_order already.");
	    if ([order count] && [[order objectAtIndex: 0] iconic])
	        [order insertObject: c atIndex: 0];
	    else if ([order count] == 0)
	        [order addObject: c];
	    else {
	        [order insertObject: c atIndex: 1];
	    }
        }
    }
}

- (void) focusOrderRemove: (AZClient *) c
{
    unsigned int d, i;
    unsigned int count = [[AZScreen defaultScreen] numberOfDesktops];

    d = [c desktop];
    if (d == DESKTOP_ALL) {
        for (i = 0; i < count; ++i)
            [[focus_order objectAtIndex: i] removeObject: c];
    } else
        [[focus_order objectAtIndex: d] removeObject: c];
}

- (void) focusOrderToTop: (AZClient *) c
{
    unsigned int d, i;
    unsigned int count = [[AZScreen defaultScreen] numberOfDesktops];

    d = [c desktop];
    if (d == DESKTOP_ALL) {
        for (i = 0; i < count; ++i)
            [self toTop: c desktop: i];
    } else
	[self toTop: c desktop: d];
}

- (void) focusOrderToBottom: (AZClient *) c
{
    unsigned int d, i;
    unsigned int count = [[AZScreen defaultScreen] numberOfDesktops];

    d = [c desktop];
    if (d == DESKTOP_ALL) {
        for (i = 0; i < count; ++i)
	    [self toBottom: c desktop: i];
    } else
	[self toBottom: c desktop: d];
}

- (int) numberOfFocusOrderInScreen: (int) d
{
  return [(NSArray *)[focus_order objectAtIndex: d] count];
}

- (AZClient *) focusOrder: (int) index inScreen: (int) d
{
  return [[focus_order objectAtIndex: d] objectAtIndex: index];
}

- (void) setNumberOfScreens: (int) num old: (int) old
{
  NSAssert(old == [focus_order count], @"Internal Error: number of focus_order doesn't match old number");
  int i;
  for (i = old-1; i >= num; i--) {
    [[focus_order objectAtIndex: i] removeAllObjects];
    [focus_order removeObjectAtIndex: i];
  }

  /* set the new lists to be empty */
  for (i = old; i < num; ++i)
    [focus_order addObject: AUTORELEASE([[NSMutableArray alloc] init])];
  NSAssert(num == [focus_order count], @"Internal Error: number of focus_order doesn't match new number");
}

/* accessories */
- (void) set_focus_client: (AZClient *) f { focus_client = f; }
- (void) set_focus_hilite: (AZClient *) f { focus_hilite = f; }
- (void) set_focus_cycle_target: (AZClient *) f { focus_cycle_target = f; }
- (AZClient *) focus_client { return focus_client; }
- (AZClient *) focus_hilite { return focus_hilite; }
- (AZClient *) focus_cycle_target { return focus_cycle_target; }

- (id) init
{
  self = [super init];
  focus_order = [[NSMutableArray alloc] init];
  return self;
}

- (void) dealloc
{
  DESTROY(focus_order);
  [super dealloc];
}

+ (AZFocusManager *) defaultManager
{
  if (sharedInstance == nil)
  {
    sharedInstance = [[AZFocusManager alloc] init];
  }
  return sharedInstance;
}

@end

@implementation AZFocusManager (AZPrivate)

- (void) pushToTop: (AZClient *) client
{
    unsigned int desktop;

    desktop = [client desktop];
    if (desktop == DESKTOP_ALL) desktop = [[AZScreen defaultScreen] desktop];
    [[focus_order objectAtIndex: desktop] removeObject: client];
    [[focus_order objectAtIndex: desktop] insertObject: client atIndex: 0];
}

/* finds the first transient that isn't 'skip' and ensure's that client_normal
 is true for it */
- (AZClient *) findTransientRecursive: (AZClient *) c : (AZClient *) top
                                     : (AZClient *) skip
{
    AZClient *ret, *temp;

    int j, jcount = [[c transients] count];
    for (j = 0; j < jcount; j++) {
	temp = [[c transients] objectAtIndex: j];
	if (temp == top) return nil;
	ret = [self findTransientRecursive: temp : top : skip];
	if (ret && ret != skip && [ret normal]) return ret;
	if (temp != skip && [temp normal]) return temp;
    }
    return nil;
}

- (AZClient *) fallbackTransient: (AZClient *) top : (AZClient *) old
{
    AZClient *target = [self findTransientRecursive: top : top : old];
    if (!target) {
        /* make sure client_normal is true always */
	if (![top normal])
            return nil;
        target = top; /* no transient, keep the top */
    }
    if ([target canFocus])
        return target;
    else
        return nil;
}

- (void) popupCycle: (AZClient *) c show: (BOOL) show
{
    if (!show) {
	[focus_cycle_popup hide];
    } else {
        Rect *a;
        AZClient *p = c;
        NSString *title = nil;

	a = [[AZScreen defaultScreen] physicalAreaOfMonitor: 0];
	[focus_cycle_popup positionWithGravity: CenterGravity
                                             x: a->x + a->width / 2 
			                     y: a->y + a->height / 2];
        /* XXX the size and the font extents need to be related on some level
         */
	[focus_cycle_popup sizeWithWidth: POPUP_WIDTH height: POPUP_HEIGHT];

        /* use the transient's parent's title/icon */
        while ([p transient_for] && [p transient_for] != OB_TRAN_GROUP)
            p = [p transient_for];

        if (p != c && [([c iconic] ? [c icon_title] : [c title]) length] != 0)
	    ASSIGN(title, ([p iconic] ? [p icon_title] : [p title]));
	  [focus_cycle_popup showText: (title ? title : ([c iconic] ? [c icon_title] : [c title]))
		                 icon: [p iconWithWidth: 48 height: 48]];
	DESTROY(title);
    }
}

- (BOOL) validFocusTarget: (AZClient *) ft
{
    /* we don't use client_can_focus here, because that doesn't let you
       focus an iconic window, but we want to be able to, so we just check
       if the focus flags on the window allow it, and its on the current
       desktop */
    if (([ft type] == OB_CLIENT_TYPE_NORMAL ||
         [ft type] == OB_CLIENT_TYPE_DIALOG ||
         (![ft hasGroupSiblings] &&
          ([ft type] == OB_CLIENT_TYPE_TOOLBAR ||
           [ft type] == OB_CLIENT_TYPE_MENU ||
           [ft type] == OB_CLIENT_TYPE_UTILITY))) &&
        (([ft can_focus] || [ft focus_notify]) &&
         ![ft skip_pager] &&
         ([ft desktop] == [[AZScreen defaultScreen] desktop] || [ft desktop] == DESKTOP_ALL)) &&
        ft == [ft focusTarget])
        return YES;

    return NO;
}

- (void) toTop: (AZClient *) c desktop: (unsigned int) d
{
    [[focus_order objectAtIndex: d] removeObject: c];
    if (![c iconic]) {
	[[focus_order objectAtIndex: d] insertObject: c atIndex: 0];
    } else {
	NSMutableArray *order = [focus_order objectAtIndex: d];
	int i, count = [order count];
	BOOL found = NO;
        /* insert before first iconic window */
	for (i = 0; i < count; i++) {
	  AZClient *temp = [order objectAtIndex: i];
	  if ([temp iconic]) {
	    found = YES;
	    break;
	  }
	}
	if (found) {
	  [order insertObject: c atIndex: i];
	} else {
	  [order addObject: c];
	}
    }
}

- (void) toBottom: (AZClient *) c desktop: (unsigned int) d
{
    [[focus_order objectAtIndex: d] removeObject: c];
    if ([c iconic]) {
	[[focus_order objectAtIndex: d] addObject: c];
    } else {
	NSMutableArray *order = [focus_order objectAtIndex: d];
	int i, count = [order count];
	BOOL found = NO;
        /* insert before first iconic window */
	for (i = 0; i < count; i++) {
	  AZClient *temp = [order objectAtIndex: i];
	  if ([temp iconic]) {
	    found = YES;
	    break;
	  }
	}
	if (found) {
	  [order insertObject: c atIndex: i];
	} else {
	  [order addObject: c];
	}
    }
}

- (void) clientDestroy: (NSNotification *) not
{
    /* end cycling if the target disappears */
    AZClient *client = [not object];
    if (focus_cycle_target == client)
      [self cycleForward: YES linear: YES interactive: YES
  	    dialog: YES done: YES cancel: YES opaque: NO];
}

@end
