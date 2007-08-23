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
- (void) popupCycle: (AZClient *) c show: (BOOL) show;
- (BOOL) validFocusTarget: (AZClient *) ft;
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
	[self focusNothing];

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
    DESTROY(focus_cycle_popup);

    if (!reconfig) {
	[[NSNotificationCenter defaultCenter] removeObserver: self];

// FIXME: should we clean up focus_order ?
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
    AZScreen *screen = [AZScreen defaultScreen];

    /* uninstall the old colormap, and install the new one */
    [screen installColormap: focus_client install: NO];
    [screen installColormap: client install: YES];

    /* in the middle of cycling..? kill it. CurrentTime is fine, time won't
       be used.
    */
    if (focus_cycle_target)
	[self cycleForward: YES linear: YES interactive: YES
	      dialog: YES done: YES cancel: YES opaque: NO];

    focus_client = client;

    /* move to the top of the list */
    if (client != nil)
    {
        /* move to the top of the list */
	[self pushToTop: client];
        /* remove hiliting from the window when it gets focused */
	[client hilite: NO];
    }

    /* set the NET_ACTIVE_WINDOW hint, but preserve it on shutdown */
    if (ob_state() != OB_STATE_EXITING) {
        active = client ? [client window] : None;
        PROP_SET32(RootWindow(ob_display, ob_screen),
                   net_active_window, window, active);
    }
}

- (AZClient *) fallbackTarget: (BOOL) allow_refocus old: (AZClient *) old
{
    AZClient *desktop = nil;
    AZScreen *screen = [AZScreen defaultScreen];

    if (allow_refocus && old && [old desktop] == DESKTOP_ALL && [old normal])
    {
        return old;
    }

    int i;
    for (i = 0; i < [focus_order count]; i++)
    {
	AZClient *c = [focus_order objectAtIndex: i];
	if (allow_refocus || c != old)
	{
            /* fallback focus to a window if:
               1. it is actually focusable, cuz if it's not then we're sending
               focus off to nothing
               2. it is validated. if the window is about to disappear, then
               don't try focus it.
               3. it is visible on the current desktop. this ignores
               omnipresent windows, which are problematic in their own rite.
               4. it's not iconic
               5. it is a normal type window, don't fall back onto a dock or
               a splashscreen or a desktop window (save the desktop as a
               backup fallback though)
            */
            if ([c canFocus] && ![c iconic])
            {
                if ([c desktop] == [screen desktop] && [c normal]) 
		{
                    return c;
                } 
		else if (([c desktop] == [screen desktop] ||
			  [c desktop] == DESKTOP_ALL) &&
			 [c type] == OB_CLIENT_TYPE_DESKTOP && desktop == nil)
		{
                    desktop = c;
		}
            }
        }
    }

    /* as a last resort fallback to the desktop window if there is one.
       (if there's more than one, then the one most recently focused.)
    */
    return desktop;
}

- (void) fallback: (BOOL) allow_refocus
{
    AZClient *new;
    AZClient *old = focus_client;

    /* unfocus any focused clients.. they can be focused by Pointer events
       and such, and then when I try focus them, I won't get a FocusIn event
       at all for them.
    */
    [self focusNothing];

    if ((new = [self fallbackTarget: allow_refocus old: old]))
	[new focus];
}

- (void) focusNothing
{
    /* Install our own colormap */
    AZScreen *screen = [AZScreen defaultScreen];
    if (focus_client != nil) {
	[screen installColormap: focus_client install: NO];
	[screen installColormap: nil install: YES];
    }

    focus_client = nil;

    /* when nothing will be focused, send focus to the backup target */
    XSetInputFocus(ob_display, [screen supportXWindow], RevertToPointerRoot,
                   event_curtime);
}

- (void) cycleDrawIndicator
{
    if (!focus_cycle_target) {
        XUnmapWindow(ob_display, [focus_indicator.top window]);
        XUnmapWindow(ob_display, [focus_indicator.left window]);
        XUnmapWindow(ob_display, [focus_indicator.right window]);
        XUnmapWindow(ob_display, [focus_indicator.bottom window]);

        /* kill enter events cause by this unmapping */
        [[AZEventHandler defaultHandler] ignoreQueuedEnters];
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
    BOOL use_clist = NO;

    if (interactive) {
        if (cancel) {
            focus_cycle_target = nil;
            goto done_cycle;
        } else if (done)
            goto done_cycle;

        if ([focus_order count] == 0)
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
	  list = focus_order;
	}
    } else {
        if ([focus_order count] == 0)
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

    if (!interactive)
        return;

    if (cancel) {
        focus_cycle_target = nil;
        goto done_cycle;
    } else if (done)
        goto done_cycle;

    if ([focus_order count] == 0)
        goto done_cycle;

    if (!first) first = focus_client;
    if (!focus_cycle_target) focus_cycle_target = focus_client;

    if (focus_cycle_target)
    {
	ft = [focus_cycle_target findDirectional: dir];
    }
    else 
    {
	int i;
	for (i = 0; i < [focus_order count]; i++) 
	{
	  AZClient *c = [focus_order objectAtIndex: i];
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
    if ([c iconic])
    {
	[self focusOrderToTop: c];
    }
    else 
    {
	if ([focus_order containsObject: c] == YES)
	    NSLog(@"Internal Error: client %@ already in focus order", c);

        /* if there are any iconic windows, put this above them in the order,
           but if there are not, then put it under the currently focused one */
        if ([focus_order count] && 
	    [(AZClient*)[focus_order objectAtIndex: 0] iconic])
	{
	    [focus_order insertObject: c atIndex: 0];
	}
        else
	{
	    if ([focus_order count])
		[focus_order insertObject: c atIndex: 1];
	    else
		[focus_order addObject: c];
	}
    }
}

- (void) focusOrderRemove: (AZClient *) c
{
    [focus_order removeObject: c];
    if (c == focus_client)
	focus_client = nil;
}

- (void) focusOrderToTop: (AZClient *) c
{
    RETAIN(c);
    [focus_order removeObject: c];
    if (![c iconic])
    {
      [focus_order insertObject: c atIndex: 0];
    }
    else
    {
      /* insert before first iconic window */
      BOOL found = NO;
      int i;
      for (i = 0; i < [focus_order count]; i++)
      {
	AZClient *ct = [focus_order objectAtIndex: i];
	if ([ct iconic])
        {
          found = YES;
          break;
        }
      }
      if (found == YES)
        [focus_order insertObject: c atIndex: i];
      else
        [focus_order addObject: c];
    }
    RELEASE(c);
}

- (void) focusOrderToBottom: (AZClient *) c
{
    RETAIN(c);
    [focus_order removeObject: c];
    if ([c iconic])
    {
      [focus_order addObject: c];
    }
    else
    {
      BOOL found = NO;
      int i;
      for (i = 0; i < [focus_order count]; i++)
      {
	AZClient *ct = [focus_order objectAtIndex: i];
	if ([ct iconic])
        {
          found = YES;
          break;
        }
      }
      if (found == YES)
        [focus_order insertObject: c atIndex: i];
      else
        [focus_order addObject: c];
    }
    RELEASE(c);
}

- (AZClient *) focusOrderFindFirst: (unsigned int) desktop
{
    int i;
    for (i = 0; i < [focus_order count]; i++)
    {
	AZClient *c = [focus_order objectAtIndex: i];
	if ([c desktop] == desktop || [c desktop] == DESKTOP_ALL)
	    return c;
    }
    return nil;
}

/* accessories */
- (void) set_focus_client: (AZClient *) f { focus_client = f; }
- (void) set_focus_cycle_target: (AZClient *) f { focus_cycle_target = f; }
- (AZClient *) focus_client { return focus_client; }
- (AZClient *) focus_cycle_target { return focus_cycle_target; }

- (NSArray *) focus_order { return focus_order; }

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
    RETAIN(client);
    [focus_order removeObject: client];
    [focus_order insertObject: client atIndex: 0];
    RELEASE(client);
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

- (void) clientDestroy: (NSNotification *) not
{
    /* end cycling if the target disappears. CurrentTime is fine, time won't
       be used
    */
    AZClient *client = [not object];
    if (focus_cycle_target == client)
      [self cycleForward: YES linear: YES interactive: YES
  	    dialog: YES done: YES cancel: YES opaque: NO];
}

@end
