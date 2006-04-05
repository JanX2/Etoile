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
#import "openbox.h"
#import "AZMainLoop.h"
#import "AZScreen.h"
#import "AZDebug.h"
#import "AZStacking.h"
#import "prop.h"
#import "config.h"

#define DOCK_EVENT_MASK (ButtonPressMask | ButtonReleaseMask | \
                         EnterWindowMask | LeaveWindowMask)
#define DOCKAPP_EVENT_MASK (StructureNotifyMask)

static AZDock *sharedInstance;

/* callback */
static BOOL hide_timeout(void *data);
static BOOL show_timeout(void *data);

@interface AZDock (AZPrivate)
- (BOOL) hideTimeout;
- (BOOL) showTimeout;
@end

@implementation AZDock

- (void) startup: (BOOL) reconfig
{
    XSetWindowAttributes attrib;

    if (reconfig) {
        GList *it;

        XSetWindowBorder(ob_display, frame,
                         RrColorPixel(ob_rr_theme->b_color));
        XSetWindowBorderWidth(ob_display, frame, ob_rr_theme->bwidth);

        RrAppearanceFree(a_frame);
        a_frame = RrAppearanceCopy(ob_rr_theme->a_unfocused_title);

	_self.type = Window_Dock;
	_self.dock = self;
        [[AZStacking stacking] addWindow: (DOCK_AS_WINDOW(&_self))];

	[self configure];
	[self setHide: YES];

	int i, count = [dock_apps count];
	for (i = 0; i < count; i++)
	{
	  [(AZDockApp *)[dock_apps objectAtIndex: i] grabButton: YES];
	}
        return;
    }

    STRUT_PARTIAL_SET(dock_strut, 0, 0, 0, 0,
                      0, 0, 0, 0, 0, 0, 0, 0);

    obwin.type = Window_Dock;

    hidden = YES;

    attrib.event_mask = DOCK_EVENT_MASK;
    attrib.override_redirect = True;
    frame = XCreateWindow(ob_display, RootWindow(ob_display, ob_screen),
                                0, 0, 1, 1, 0,
                                RrDepth(ob_rr_inst), InputOutput,
                                RrVisual(ob_rr_inst),
                                CWOverrideRedirect | CWEventMask,
                                &attrib);
    a_frame = RrAppearanceCopy(ob_rr_theme->a_unfocused_title);
    XSetWindowBorder(ob_display, frame,
                     RrColorPixel(ob_rr_theme->b_color));
    XSetWindowBorderWidth(ob_display, frame, ob_rr_theme->bwidth);

    _self.type = Window_Dock;
    _self.dock = self;

    g_hash_table_insert(window_map, &frame, self);
    [[AZStacking stacking] addWindow: (DOCK_AS_WINDOW(&_self))];
}

- (void) shutdown: (BOOL) reconfig
{
    if (reconfig) {
        GList *it;

        [[AZStacking stacking] removeWindow: (DOCK_AS_WINDOW(&_self))];

	int i, count = [dock_apps count];
	for (i = 0; i < count; i++)
	{
	  [(AZDockApp *)[dock_apps objectAtIndex: i] grabButton: NO];
	}

        return;
    }

    XDestroyWindow(ob_display, frame);
    RrAppearanceFree(a_frame);
    [[AZStacking stacking] removeWindow: (ObWindow *)(&_self)];
    g_hash_table_remove(window_map, &frame);
}

- (void) addWindow: (Window) win hints: (XWMHints *) wmhints
{
    AZDockApp *app;
    XWindowAttributes attrib;
    char **data;

    app = [[AZDockApp alloc] init];
    [app setType: Window_DockApp];
    [app setWindow: win];
    [app setIconWindow: (wmhints->flags & IconWindowHint) ?
        wmhints->icon_window : win];

    if (PROP_GETSS([app window], wm_class, locale, &data)) {
        if (data[0]) {
	    [app setName: g_strdup(data[0])];
            if (data[1])
	      [app setClass: g_strdup(data[1])];
        }
        g_strfreev(data);     
    }

    if ([app name] == NULL) [app setName: g_strdup("")];
    if ([app class] == NULL) [app setClass: g_strdup("")];
    
    if (XGetWindowAttributes(ob_display, [app iconWindow], &attrib)) {
        [app setW: attrib.width];
        [app setH: attrib.height];
    } else {
        [app setW: 64];
        [app setH: 64];
    }

    [dock_apps addObject: app];
    [self configure];

    XReparentWindow(ob_display, [app iconWindow], frame, [app x], [app y]);
    /*
      This is the same case as in frame.c for client windows. When Openbox is
      starting, the window is already mapped so we see unmap events occur for
      it. There are 2 unmap events generated that we see, one with the 'event'
      member set the root window, and one set to the client, but both get
      handled and need to be ignored.
    */
    if (ob_state() == OB_STATE_STARTING)
    {
      [app setIgnoreUnmaps: [app ignoreUnmaps]+2];
    }

    if ([app window] != [app iconWindow]) {
        /* have to map it so that it can be re-managed on a restart */
        XMoveWindow(ob_display, [app window], -1000, -1000);
        XMapWindow(ob_display, [app window]);
    }
    XMapWindow(ob_display, [app iconWindow]);
    XSync(ob_display, False);

    /* specify that if we exit, the window should not be destroyed and should
       be reparented back to root automatically */
    XChangeSaveSet(ob_display, [app iconWindow], SetModeInsert);
    XSelectInput(ob_display, [app iconWindow], DOCKAPP_EVENT_MASK);

    [app grabButton: YES];

    /* Fake dock_app struct */
    g_hash_table_insert(window_map, [app iconWindowPointer], app);

    AZDebug("Managed Dock App: 0x%lx (%s)\n", [app iconWindow], [app class]);
}

- (void) removeAll
{
  int i, count = [dock_apps count];
  for (i = count-1; i > -1; i--)
  {
    [self remove: [dock_apps objectAtIndex: i] reparent: YES];
  }
}

- (void) remove: (AZDockApp *) app reparent: (BOOL) reparent
{
    [app grabButton: NO];
    XSelectInput(ob_display, [app iconWindow], NoEventMask);
    /* remove the window from our save set */
    XChangeSaveSet(ob_display, [app iconWindow], SetModeDelete);
    XSync(ob_display, False);

    g_hash_table_remove(window_map, [app iconWindowPointer]);

    if (reparent)
        XReparentWindow(ob_display, [app iconWindow],
                        RootWindow(ob_display, ob_screen), [app x], [app y]);

    [dock_apps removeObject: app];
    [self configure];

    AZDebug("Unmanaged Dock App: 0x%lx (%s)\n", [app iconWindow], [app class]);

    g_free([app name]);
    g_free([app class]);
    DESTROY(app);
    //g_free(app);
}

- (void) configure
{
    GList *it;
    int spot;
    int gravity;
    int minw, minh;
    int strw, strh;
    Rect *a;

    RrMinsize(a_frame, &minw, &minh);

    w = h = 0;

    /* get the size */
    int i, count = [dock_apps count];
    for (i = 0; i < count; i++) {
        AZDockApp *app = [dock_apps objectAtIndex: i];
        switch (config_dock_orient) {
        case OB_ORIENTATION_HORZ:
            w += [app w];
            h = MAX(h, [app h]);
            break;
        case OB_ORIENTATION_VERT:
            w = MAX(w, [app w]);
            h += [app h];
            break;
        }
    }

    spot = (config_dock_orient == OB_ORIENTATION_HORZ ? minw : minh) / 2;

    /* position the apps */
    count = [dock_apps count];
    for (i = 0; i < count; i++) {
        AZDockApp *app = [dock_apps objectAtIndex: i];
        switch (config_dock_orient) {
        case OB_ORIENTATION_HORZ:
            [app setX: spot];
            [app setY: (h - [app h]) / 2];
            spot += [app w];
            break;
        case OB_ORIENTATION_VERT:
            [app setX: (w - [app w]) / 2];
            [app setY: spot];
            spot += [app h];
            break;
        }

        XMoveWindow(ob_display, [app iconWindow], [app x], [app y]);
    }

    /* used for calculating offsets */
    w += ob_rr_theme->bwidth * 2;
    h += ob_rr_theme->bwidth * 2;

    a = [[AZScreen defaultScreen] physicalArea];

    /* calculate position */
    if (config_dock_floating) {
        x = config_dock_x;
        y = config_dock_y;
        gravity = NorthWestGravity;
    } else {
        switch (config_dock_pos) {
        case OB_DIRECTION_NORTHWEST:
            x = 0;
            y = 0;
            gravity = NorthWestGravity;
            break;
        case OB_DIRECTION_NORTH:
            x = a->width / 2;
            y = 0;
            gravity = NorthGravity;
            break;
        case OB_DIRECTION_NORTHEAST:
            x = a->width;
            y = 0;
            gravity = NorthEastGravity;
            break;
        case OB_DIRECTION_WEST:
            x = 0;
            y = a->height / 2;
            gravity = WestGravity;
            break;
        case OB_DIRECTION_EAST:
            x = a->width;
            y = a->height / 2;
            gravity = EastGravity;
            break;
        case OB_DIRECTION_SOUTHWEST:
            x = 0;
            y = a->height;
            gravity = SouthWestGravity;
            break;
        case OB_DIRECTION_SOUTH:
            x = a->width / 2;
            y = a->height;
            gravity = SouthGravity;
            break;
        case OB_DIRECTION_SOUTHEAST:
            x = a->width;
            y = a->height;
            gravity = SouthEastGravity;
            break;
        }
    }

    switch(gravity) {
    case NorthGravity:
    case CenterGravity:
    case SouthGravity:
        x -= w / 2;
        break;
    case NorthEastGravity:
    case EastGravity:
    case SouthEastGravity:
        x -= w;
        break;
    }
    switch(gravity) {
    case WestGravity:
    case CenterGravity:
    case EastGravity:
        y -= h / 2;
        break;
    case SouthWestGravity:
    case SouthGravity:
    case SouthEastGravity:
        y -= h;
        break;
    }

    if (config_dock_hide && hidden) {
        if (!config_dock_floating) {
            switch (config_dock_pos) {
            case OB_DIRECTION_NORTHWEST:
                switch (config_dock_orient) {
                case OB_ORIENTATION_HORZ:
                    y -= h - ob_rr_theme->bwidth;
                    break;
                case OB_ORIENTATION_VERT:
                    x -= w - ob_rr_theme->bwidth;
                    break;
                }
                break;
            case OB_DIRECTION_NORTH:
                y -= h - ob_rr_theme->bwidth;
                break;
            case OB_DIRECTION_NORTHEAST:
                switch (config_dock_orient) {
                case OB_ORIENTATION_HORZ:
                    y -= h - ob_rr_theme->bwidth;
                    break;
                case OB_ORIENTATION_VERT:
                    x += w - ob_rr_theme->bwidth;
                    break;
                }
                break;
            case OB_DIRECTION_WEST:
                x -= w - ob_rr_theme->bwidth;
                break;
            case OB_DIRECTION_EAST:
                x += w - ob_rr_theme->bwidth;
                break;
            case OB_DIRECTION_SOUTHWEST:
                switch (config_dock_orient) {
                case OB_ORIENTATION_HORZ:
                    y += h - ob_rr_theme->bwidth;
                    break;
                case OB_ORIENTATION_VERT:
                    x -= w - ob_rr_theme->bwidth;
                    break;
                } break;
            case OB_DIRECTION_SOUTH:
                y += h - ob_rr_theme->bwidth;
                break;
            case OB_DIRECTION_SOUTHEAST:
                switch (config_dock_orient) {
                case OB_ORIENTATION_HORZ:
                    y += h - ob_rr_theme->bwidth;
                    break;
                case OB_ORIENTATION_VERT:
                    x += w - ob_rr_theme->bwidth;
                    break;
                }
                break;
            }    
        }
    }

    if (!config_dock_floating && config_dock_hide) {
        strw = ob_rr_theme->bwidth;
        strh = ob_rr_theme->bwidth;
    } else {
        strw = w;
        strh = h;
    }

    /* set the strut */
    if ([dock_apps count] == 0) {
        STRUT_PARTIAL_SET(dock_strut, 0, 0, 0, 0,
                          0, 0, 0, 0, 0, 0, 0, 0);
    } else if (config_dock_floating || config_dock_nostrut) {
        STRUT_PARTIAL_SET(dock_strut, 0, 0, 0, 0,
                          0, 0, 0, 0, 0, 0, 0, 0);
    } else {
        switch (config_dock_pos) {
        case OB_DIRECTION_NORTHWEST:
            switch (config_dock_orient) {
            case OB_ORIENTATION_HORZ:
                STRUT_PARTIAL_SET(dock_strut, 0, strh, 0, 0,
                                  0, 0, x, x + w - 1,
                                  0, 0, 0, 0);
                break;
            case OB_ORIENTATION_VERT:
                STRUT_PARTIAL_SET(dock_strut, strw, 0, 0, 0,
                                  y, y + h - 1,
                                  0, 0, 0, 0, 0, 0);
                break;
            }
            break;
        case OB_DIRECTION_NORTH:
            STRUT_PARTIAL_SET(dock_strut, 0, strh, 0, 0,
                              x, x + w - 1,
                              0, 0, 0, 0, 0, 0);
            break;
        case OB_DIRECTION_NORTHEAST:
            switch (config_dock_orient) {
            case OB_ORIENTATION_HORZ:
                STRUT_PARTIAL_SET(dock_strut, 0, strh, 0, 0,
                                  0, 0, x, x + w -1,
                                  0, 0, 0, 0);
                break;
            case OB_ORIENTATION_VERT:
                STRUT_PARTIAL_SET(dock_strut, 0, 0, strw, 0,
                                  0, 0, 0, 0,
                                  y, y + h - 1, 0, 0);
                break;
            }
            break;
        case OB_DIRECTION_WEST:
            STRUT_PARTIAL_SET(dock_strut, strw, 0, 0, 0,
                              y, y + h - 1,
                              0, 0, 0, 0, 0, 0);
            break;
        case OB_DIRECTION_EAST:
            STRUT_PARTIAL_SET(dock_strut, 0, 0, strw, 0,
                              0, 0, 0, 0,
                              y, y + h - 1, 0, 0);
            break;
        case OB_DIRECTION_SOUTHWEST:
            switch (config_dock_orient) {
            case OB_ORIENTATION_HORZ:
                STRUT_PARTIAL_SET(dock_strut, 0, 0, 0, strh,
                                  0, 0, 0, 0, 0, 0,
                                  x, x + w - 1);
                break;
            case OB_ORIENTATION_VERT:
                STRUT_PARTIAL_SET(dock_strut, strw, 0, 0, 0,
                                  y, y + h - 1,
                                  0, 0, 0, 0, 0, 0);
                break;
            }
            break;
        case OB_DIRECTION_SOUTH:
            STRUT_PARTIAL_SET(dock_strut, 0, 0, 0, strh,
                              0, 0, 0, 0, 0, 0,
                              x, x + w - 1);
            break;
        case OB_DIRECTION_SOUTHEAST:
            switch (config_dock_orient) {
            case OB_ORIENTATION_HORZ:
                STRUT_PARTIAL_SET(dock_strut, 0, 0, 0, strh,
                                  0, 0, 0, 0, 0, 0,
                                  x, x + w - 1);
                break;
            case OB_ORIENTATION_VERT:
                STRUT_PARTIAL_SET(dock_strut, 0, 0, strw, 0,
                                  0, 0, 0, 0,
                                  y, y + h - 1, 0, 0);
                break;
            }
            break;
        }
    }

    w += minw;
    h += minh;

    /* not used for actually sizing shit */
    w -= ob_rr_theme->bwidth * 2;
    h -= ob_rr_theme->bwidth * 2;

    if ([dock_apps count]) {
        g_assert(w > 0);
        g_assert(h > 0);

        XMoveResizeWindow(ob_display, frame,
                          x, y, w, h);

        RrPaint(a_frame, frame, w, h);
        XMapWindow(ob_display, frame);
    } else
        XUnmapWindow(ob_display, frame);

    /* but they are useful outside of this function! */
    w += ob_rr_theme->bwidth * 2;
    h += ob_rr_theme->bwidth * 2;

    [[AZScreen defaultScreen] updateAreas];
}

- (void) setHide: (BOOL) hide
{
  AZMainLoop *mainLoop = [AZMainLoop mainLoop];
    if (!hide) {
        if (hidden && config_dock_hide) {
	  [mainLoop addTimeoutHandler: (GSourceFunc)show_timeout
		         microseconds: config_dock_show_delay
		 	         data: NULL notify: NULL];
        } else if (!hidden && config_dock_hide) {
	    [mainLoop removeTimeoutHandler: (GSourceFunc)hide_timeout];
        }
    } else {
        if (!hidden && config_dock_hide) {
	  [mainLoop addTimeoutHandler: (GSourceFunc)hide_timeout
		         microseconds: config_dock_hide_delay
		 	         data: NULL notify: NULL];
        } else if (hidden && config_dock_hide) {
	    [mainLoop removeTimeoutHandler: (GSourceFunc)show_timeout];
        }
    }
}

- (int) x { return x; }
- (int) y { return y; }
- (int) w { return w; }
- (int) h { return h; }
- (StrutPartial) strut { return dock_strut; }
- (Window) frame { return frame; }

- (NSArray *) dockApplications
{
  return dock_apps;
}

- (void) moveDockApp: (AZDockApp *) app toIndex: (int) index
{
  int orig = [dock_apps indexOfObject: app];

  if ((orig == NSNotFound) || (orig == index))
    return;
  
  RETAIN(app);
  [dock_apps removeObjectAtIndex: orig];
  if (orig < index) index--;
  [dock_apps insertObject: app atIndex: index];
  RELEASE(app);
}

- (struct _AZDockStruct *) _self
{
  return &_self;
}

- (id) init
{
  self = [super init];
  dock_apps = [[NSMutableArray alloc] init];
  return self;
}

- (void) dealloc
{
  DESTROY(dock_apps);
  [super dealloc];
}

+ (AZDock *) defaultDock
{
  if (sharedInstance == nil)
  {
    sharedInstance = [[AZDock alloc] init];
  }
  return sharedInstance;
}

@end

@implementation AZDock (AZPrivate)
- (BOOL) hideTimeout
{
    /* hide */
    hidden = TRUE;
    [self configure];

    return NO; /* don't repeat */
}

- (BOOL) showTimeout
{
    /* show */
    hidden = NO;
    [self configure];

    return NO; /* don't repeat */
}
@end

static BOOL hide_timeout(void *data)
{
  // data is not set
  [[AZDock defaultDock] hideTimeout];
}

static BOOL show_timeout(void *data)
{
  [[AZDock defaultDock] showTimeout];
}

