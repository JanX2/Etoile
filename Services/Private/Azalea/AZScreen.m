/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZScreen.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   screen.h for the Openbox window manager
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
#import "AZStartupHandler.h"
#import "AZEventHandler.h"
#import "AZDebug.h"
#import "AZClientManager.h"
#import "AZStacking.h"
#import "AZPopUp.h"
#import "AZMoveResizeHandler.h"
#import "AZFocusManager.h"
#import "openbox.h"
#import "prop.h"
#import "config.h"

#import <XWindowServerKit/XScreen.h>

/*! The event mask to grab on the root window */
#define ROOT_EVENTMASK (StructureNotifyMask | PropertyChangeMask | \
                        EnterWindowMask | LeaveWindowMask | \
                        SubstructureNotifyMask | SubstructureRedirectMask | \
                        ButtonPressMask | ButtonReleaseMask | ButtonMotionMask)

static inline void
screen_area_add_strut_left(const StrutPartial *s, const Rect *monitor_area,
                           int edge, Strut *ret);
static inline void
screen_area_add_strut_top(const StrutPartial *s, const Rect *monitor_area,
                           int edge, Strut *ret);
static inline void
screen_area_add_strut_right(const StrutPartial *s, const Rect *monitor_area,
                           int edge, Strut *ret);
static inline void
screen_area_add_strut_bottom(const StrutPartial *s, const Rect *monitor_area,
                           int edge, Strut *ret);

static AZScreen *sharedInstance;

@interface AZScreen (AZPrivate)
- (BOOL) replaceWM;
- (void) getRowCol: (unsigned int) d row: (unsigned int *) r col: (unsigned int *) c;
- (unsigned int) translateRow: (unsigned int) r col: (unsigned int) c;
@end

@implementation AZScreen

+ (AZScreen *) defaultScreen
{
  if (sharedInstance == nil)
  {
    sharedInstance = [[AZScreen alloc] init];
  }
  return sharedInstance;
}

- (BOOL) screenAnnex
{
    XSetWindowAttributes attrib;
    pid_t pid;
    int i, num_support;
    unsigned long *supported;

    /* create the netwm support window */
    attrib.override_redirect = YES;
    screen_support_win = XCreateWindow(ob_display,
                                       RootWindow(ob_display, ob_screen),
                                       -100, -100, 1, 1, 0,
                                       CopyFromParent, InputOutput,
                                       CopyFromParent,
                                       CWOverrideRedirect, &attrib);
    XMapRaised(ob_display, screen_support_win);

    if (![self replaceWM]) {
        XDestroyWindow(ob_display, screen_support_win);
        return NO;
    }

    AZXErrorSetIgnore(YES);
    xerror_occured = NO;
    XSelectInput(ob_display, RootWindow(ob_display, ob_screen),
                 ROOT_EVENTMASK);
    AZXErrorSetIgnore(NO);
    if (xerror_occured) {
        NSLog(@"A window manager is already running on screen %d", ob_screen);
        XDestroyWindow(ob_display, screen_support_win);
        return NO;
    }


    [self setRootCursor];

    /* set the OPENBOX_PID hint */
    pid = getpid();
    PROP_SET32(RootWindow(ob_display, ob_screen),
               openbox_pid, cardinal, pid);

    /* set supporting window */
    PROP_SET32(RootWindow(ob_display, ob_screen),
               net_supporting_wm_check, window, screen_support_win);

    /* set properties on the supporting window */
    PROP_SETS(screen_support_win, net_wm_name, "Openbox");
    PROP_SET32(screen_support_win, net_supporting_wm_check,
               window, screen_support_win);

    /* set the _NET_SUPPORTED_ATOMS hint */
    num_support = 54;
    i = 0;
    supported = calloc(sizeof(unsigned long), num_support);
    supported[i++] = prop_atoms.net_current_desktop;
    supported[i++] = prop_atoms.net_number_of_desktops;
    supported[i++] = prop_atoms.net_desktop_geometry;
    supported[i++] = prop_atoms.net_desktop_viewport;
    supported[i++] = prop_atoms.net_active_window;
    supported[i++] = prop_atoms.net_workarea;
    supported[i++] = prop_atoms.net_client_list;
    supported[i++] = prop_atoms.net_client_list_stacking;
    supported[i++] = prop_atoms.net_desktop_names;
    supported[i++] = prop_atoms.net_close_window;
    supported[i++] = prop_atoms.net_desktop_layout;
    supported[i++] = prop_atoms.net_showing_desktop;
    supported[i++] = prop_atoms.net_wm_name;
    supported[i++] = prop_atoms.net_wm_visible_name;
    supported[i++] = prop_atoms.net_wm_icon_name;
    supported[i++] = prop_atoms.net_wm_visible_icon_name;
    supported[i++] = prop_atoms.net_wm_desktop;
    supported[i++] = prop_atoms.net_wm_strut;
    supported[i++] = prop_atoms.net_wm_window_type;
    supported[i++] = prop_atoms.net_wm_window_type_desktop;
    supported[i++] = prop_atoms.net_wm_window_type_dock;
    supported[i++] = prop_atoms.net_wm_window_type_toolbar;
    supported[i++] = prop_atoms.net_wm_window_type_menu;
    supported[i++] = prop_atoms.net_wm_window_type_utility;
    supported[i++] = prop_atoms.net_wm_window_type_splash;
    supported[i++] = prop_atoms.net_wm_window_type_dialog;
    supported[i++] = prop_atoms.net_wm_window_type_normal;
    supported[i++] = prop_atoms.net_wm_allowed_actions;
    supported[i++] = prop_atoms.net_wm_action_move;
    supported[i++] = prop_atoms.net_wm_action_resize;
    supported[i++] = prop_atoms.net_wm_action_minimize;
    supported[i++] = prop_atoms.net_wm_action_shade;
    supported[i++] = prop_atoms.net_wm_action_maximize_horz;
    supported[i++] = prop_atoms.net_wm_action_maximize_vert;
    supported[i++] = prop_atoms.net_wm_action_fullscreen;
    supported[i++] = prop_atoms.net_wm_action_change_desktop;
    supported[i++] = prop_atoms.net_wm_action_close;
    supported[i++] = prop_atoms.net_wm_state;
    supported[i++] = prop_atoms.net_wm_state_modal;
    supported[i++] = prop_atoms.net_wm_state_maximized_vert;
    supported[i++] = prop_atoms.net_wm_state_maximized_horz;
    supported[i++] = prop_atoms.net_wm_state_shaded;
    supported[i++] = prop_atoms.net_wm_state_skip_taskbar;
    supported[i++] = prop_atoms.net_wm_state_skip_pager;
    supported[i++] = prop_atoms.net_wm_state_hidden;
    supported[i++] = prop_atoms.net_wm_state_fullscreen;
    supported[i++] = prop_atoms.net_wm_state_above;
    supported[i++] = prop_atoms.net_wm_state_below;
    supported[i++] = prop_atoms.net_wm_state_demands_attention;
    supported[i++] = prop_atoms.net_moveresize_window;
    supported[i++] = prop_atoms.net_wm_moveresize;
    supported[i++] = prop_atoms.net_wm_user_time;
    supported[i++] = prop_atoms.net_frame_extents;
    supported[i++] = prop_atoms.ob_wm_state_undecorated;
    NSAssert(i == num_support, @"Out of range");
/*
  supported[] = prop_atoms.net_wm_action_stick;
*/

    PROP_SETA32(RootWindow(ob_display, ob_screen),
                net_supported, atom, supported, num_support);
    free(supported);

    return YES;
}

- (void) startup: (BOOL) reconfig
{
    unsigned int i, count;;

    desktop_cycle_popup = [[AZPagerPopUp alloc] initWithIcon: YES];

    if (!reconfig)
    {
        /* get the initial size */
	[self resize];
    }

    /* set the names */
    count = [config_desktops_names count];
    screen_desktop_names = [[NSMutableArray alloc] init];
    for (i = 0; i < count; i++) {
	NSString *_n = [config_desktops_names objectAtIndex: i];
        [screen_desktop_names addObject: _n];
    }
    PROP_SETSS(RootWindow(ob_display, ob_screen),
               net_desktop_names, screen_desktop_names);

    if (!reconfig)
        screen_num_desktops = 0;
    [self setNumberOfDesktops: config_desktops_num];
    if (!reconfig) {
        [self setDesktop:(MIN(config_screen_firstdesk, screen_num_desktops)-1)];

        /* don't start in showing-desktop mode */
        screen_showing_desktop = NO;
        PROP_SET32(RootWindow(ob_display, ob_screen),
                   net_showing_desktop, cardinal, screen_showing_desktop);

	[self updateLayout];
    }
}

- (void) shutdown: (BOOL) reconfig
{
    Rect **r;

    DESTROY(desktop_cycle_popup);

    if (!reconfig) {
        XSelectInput(ob_display, RootWindow(ob_display, ob_screen),
                     NoEventMask);

        /* we're not running here no more! */
        PROP_ERASE(RootWindow(ob_display, ob_screen), openbox_pid);
        /* not without us */
        PROP_ERASE(RootWindow(ob_display, ob_screen), net_supported);
        /* don't keep this mode */
        PROP_ERASE(RootWindow(ob_display, ob_screen), net_showing_desktop);

        XDestroyWindow(ob_display, screen_support_win);
    }

    DESTROY(screen_desktop_names);
    for (r = area; *r; ++r)
        free(*r);
    free(area);
    area = NULL;
}

- (void) resize
{
    static int oldw = 0, oldh = 0;
    int w, h;
    unsigned long geometry[2];

    w = WidthOfScreen(ScreenOfDisplay(ob_display, ob_screen));
    h = HeightOfScreen(ScreenOfDisplay(ob_display, ob_screen));

    if (w == oldw && h == oldh) return;

    oldw = w; oldh = h;

    /* Set the _NET_DESKTOP_GEOMETRY hint */
    screen_physical_size.width = geometry[0] = w;
    screen_physical_size.height = geometry[1] = h;
    PROP_SETA32(RootWindow(ob_display, ob_screen),
                net_desktop_geometry, cardinal, geometry, 2);

    if (ob_state() == OB_STATE_STARTING)
        return;

    [self updateAreas];

    AZClientManager *cManager = [AZClientManager defaultManager];
    int i, count = [cManager count];
    for (i = 0; i < count; i++)
    {
      AZClient *c = [cManager clientAtIndex: i];
      [c moveOnScreen: NO];
    }
}

- (void) setNumberOfDesktops: (unsigned int) num
{
    unsigned int old;
    unsigned long *viewport;

    NSAssert(num > 0, @"number of desktops is less than 0");

    if (screen_num_desktops == num) return;

    old = screen_num_desktops;
    screen_num_desktops = num;
    PROP_SET32(RootWindow(ob_display, ob_screen),
               net_number_of_desktops, cardinal, num);

    /* set the viewport hint */
    viewport = calloc(sizeof(unsigned long), num * 2);
    PROP_SETA32(RootWindow(ob_display, ob_screen),
                net_desktop_viewport, cardinal, viewport, num * 2);
    free(viewport);

    /* the number of rows/columns will differ */
    [self updateLayout];

    /* may be some unnamed desktops that we need to fill in with names */
    [self updateDesktopNames];

    /* move windows on desktops that will no longer exist! */
    AZClientManager *cManager = [AZClientManager defaultManager];
    int j, count = [cManager count];
    for (j = 0; j < count; j++)
    {
      AZClient *c = [cManager clientAtIndex: j];
        if ([c desktop] >= num && [c desktop] != DESKTOP_ALL)
	    [c setDesktop: num-1 hide: NO];
    }
 
    /* change our struts/area to match (after moving windows) */
    [self updateAreas];

    /* change our desktop if we're on one that no longer exists! */
    if (screen_desktop >= screen_num_desktops)
	[self setDesktop: num-1];

   /* update the focus lists */
    AZFocusManager *fManager = [AZFocusManager defaultManager];
    /* free our lists for the desktops which have disappeared */
    [fManager setNumberOfScreens: num old: old];
}

- (unsigned int) numberOfDesktops
{
  return screen_num_desktops;
}

- (void) setDesktop: (unsigned int) num
{
    int i, count;
    unsigned int old;
    AZStacking *stacking = [AZStacking stacking];
     
    NSAssert(num < screen_num_desktops, @"Set desktop out of range");

    old = screen_desktop;
    screen_desktop = num;
    PROP_SET32(RootWindow(ob_display, ob_screen),
               net_current_desktop, cardinal, num);

    if (old == num) return;

    screen_last_desktop = old;

#if 0
    [[NSDistributedNotificationCenter defaultCenter]
	    postNotificationName: XCurrentWorkspaceDidChangeNotification
	    object: nil];
    AZDebug("Moving to desktop %d\n", num+1);
#endif

    AZMoveResizeHandler *mrHandler = [AZMoveResizeHandler defaultHandler];
    if ([mrHandler moveresize_client])
      [[mrHandler moveresize_client] setDesktop: num hide: YES];

    /* show windows before hiding the rest to lessen the enter/leave events */

    /* show windows from top to bottom */
    count = [stacking count];
    for (i = 0; i < count; i++) {
	id <AZWindow> temp = [stacking windowAtIndex: i];
	if (WINDOW_IS_CLIENT(temp)) {
            AZClient *c = (AZClient *)temp;
	    if ([c shouldShow])
		[[c frame] show];
        }
    }

    /* hide windows from bottom to top */
    count = [stacking count];
    for (i = count-1; i > -1; i--) {
	id <AZWindow> temp = [stacking windowAtIndex: i];
        if (WINDOW_IS_CLIENT(temp)) {
            AZClient *c = (AZClient *) temp;
            if ([[c frame] visible] && ![c shouldShow])
		[[c frame] hide];
        }
    }

    [[AZEventHandler defaultHandler] ignoreQueuedEnters];

    AZFocusManager *fManager = [AZFocusManager defaultManager];
    [fManager set_focus_hilite: [fManager fallbackTarget: OB_FOCUS_FALLBACK_NOFOCUS]];
    if ([fManager focus_hilite]) {
	[[[fManager focus_hilite] frame] adjustFocusWithHilite: YES];

        /*!
          When this focus_client check is not used, you can end up with races,
          as demonstrated with gnome-panel, sometmies the window you click on
          another desktop ends up losing focus cuz of the focus change here.
        */
        /*if (!focus_client)*/
	[[fManager focus_hilite] focus];
    }
}

- (unsigned int) desktop
{
  return screen_desktop;
}

- (unsigned int) cycleDesktop: (ObDirection) dir
                         wrap: (BOOL) wrap
		       linear: (BOOL) linear
		       dialog: (BOOL) dialog
		         done: (BOOL) done
		       cancel: (BOOL) cancel
{
    static BOOL first = YES;
    static unsigned int origd, d;
    unsigned int r, c;

    if (cancel) {
        d = origd;
        goto done_cycle;
    } else if (done && dialog) {
        goto done_cycle;
    }
    if (first) {
        first = NO;
        d = origd = screen_desktop;
    }

    [self getRowCol: d row: &r col: &c];

    if (linear) {
        switch (dir) {
        case OB_DIRECTION_EAST:
            if (d < screen_num_desktops - 1)
                ++d;
            else if (wrap)
                d = 0;
            break;
        case OB_DIRECTION_WEST:
            if (d > 0)
                --d;
            else if (wrap)
                d = screen_num_desktops - 1;
            break;
        default:
            assert(0);
            return screen_desktop;
        }
    } else {
        switch (dir) {
        case OB_DIRECTION_EAST:
            ++c;
            if (c >= screen_desktop_layout.columns) {
                if (wrap) {
                    c = 0;
                } else {
                    d = screen_desktop;
                    goto show_cycle_dialog;
                }
            }
            d = [self translateRow: r col: c];
            if (d >= screen_num_desktops) {
                if (wrap) {
                    ++c;
                } else {
                    d = screen_desktop;
                    goto show_cycle_dialog;
                }
            }
            break;
        case OB_DIRECTION_WEST:
            --c;
            if (c >= screen_desktop_layout.columns) {
                if (wrap) {
                    c = screen_desktop_layout.columns - 1;
                } else {
                    d = screen_desktop;
                    goto show_cycle_dialog;
                }
            }
            d = [self translateRow: r col: c];
            if (d >= screen_num_desktops) {
                if (wrap) {
                    --c;
                } else {
                    d = screen_desktop;
                    goto show_cycle_dialog;
                }
            }
            break;
        case OB_DIRECTION_SOUTH:
            ++r;
            if (r >= screen_desktop_layout.rows) {
                if (wrap) {
                    r = 0;
                } else {
                    d = screen_desktop;
                    goto show_cycle_dialog;
                }
            }
            d = [self translateRow: r col: c];
            if (d >= screen_num_desktops) {
                if (wrap) {
                    ++r;
                } else {
                    d = screen_desktop;
                    goto show_cycle_dialog;
                }
            }
            break;
        case OB_DIRECTION_NORTH:
            --r;
            if (r >= screen_desktop_layout.rows) {
                if (wrap) {
                    r = screen_desktop_layout.rows - 1;
                } else {
                    d = screen_desktop;
                    goto show_cycle_dialog;
                }
            }
            d = [self translateRow: r col: c];
            if (d >= screen_num_desktops) {
                if (wrap) {
                    --r;
                } else {
                    d = screen_desktop;
                    goto show_cycle_dialog;
                }
            }
            break;
        default:
            assert(0);
            return d = screen_desktop;
        }

        d = [self translateRow: r col: c];
    }

show_cycle_dialog:
    if (dialog) {
	[self desktopPopup: d show: YES];
        return d;
    }

done_cycle:
    first = YES;

    [self desktopPopup: d show: NO];

    return d;
}

- (void) desktopPopup: (unsigned int) d
                 show: (BOOL) show
{
    Rect *a;

    if (!show) {
	[desktop_cycle_popup hide];
    } else {
	a = [self physicalAreaOfMonitor: 0];
	[desktop_cycle_popup positionWithGravity: CenterGravity
                             x: a->x + a->width / 2
			     y: a->y + a->height / 2];
        /* XXX the size and the font extents need to be related on some level
         */
	[desktop_cycle_popup sizeWithWidth: POPUP_WIDTH height: POPUP_HEIGHT];

	[desktop_cycle_popup setTextAlign: RR_JUSTIFY_CENTER];

	[desktop_cycle_popup showText: [screen_desktop_names objectAtIndex: d] desktop: d];
    }
}

- (void) showDesktop: (BOOL) show
{
    int i, count;
    AZStacking *stacking = [AZStacking stacking];

    if (show == screen_showing_desktop) return; /* no change */

    screen_showing_desktop = show;

    if (show) {
        /* bottom to top */
        count = [stacking count];
        for (i = count-1; i > -1 ; i--) {
            id <AZWindow> temp = [stacking windowAtIndex: i];
            if (WINDOW_IS_CLIENT(temp)) {
                AZClient *client = (AZClient *)temp;
                if ([[client frame] visible] && ![client shouldShow])
		    [[client frame] hide];
            }
        }
    } else {
        /* top to bottom */
    	count = [stacking count];
        for (i = 0; i < count; i++) {
	    id <AZWindow> temp = [stacking windowAtIndex: i];
            if (WINDOW_IS_CLIENT(temp)) {
                AZClient *client = (AZClient *)temp;
                if (![[client frame] visible] && [client shouldShow])
	            [[client frame] show];
            }
        }
    }

    AZFocusManager *fManager = [AZFocusManager defaultManager];

    if (show) {
        /* focus desktop */
	int i, count = [fManager numberOfFocusOrderInScreen: screen_desktop];
	for (i = 0; i < count; i++) {
	  AZClient *c = [fManager focusOrder: i inScreen: screen_desktop];
          if ([c type] == OB_CLIENT_TYPE_DESKTOP && [c focus])
                break;
	}
    } else {
        [fManager fallback: OB_FOCUS_FALLBACK_NOFOCUS];
    }

    show = !!show; /* make it boolean */
    PROP_SET32(RootWindow(ob_display, ob_screen),
               net_showing_desktop, cardinal, show);
}

- (BOOL) showingDesktop
{
  return screen_showing_desktop;
}

- (void) updateLayout
{
    ObOrientation orient;
    ObCorner corner;
    unsigned int rows;
    unsigned int cols;
    unsigned long *data;
    unsigned int num;
    BOOL valid = NO;

    if (PROP_GETA32(RootWindow(ob_display, ob_screen),
                    net_desktop_layout, cardinal, &data, &num)) {
        if (num == 3 || num == 4) {

            if (data[0] == prop_atoms.net_wm_orientation_vert)
                orient = OB_ORIENTATION_VERT;
            else if (data[0] == prop_atoms.net_wm_orientation_horz)
                orient = OB_ORIENTATION_HORZ;
            else
                goto screen_update_layout_bail;

            if (num < 4)
                corner = OB_CORNER_TOPLEFT;
            else {
                if (data[3] == prop_atoms.net_wm_topleft)
                    corner = OB_CORNER_TOPLEFT;
                else if (data[3] == prop_atoms.net_wm_topright)
                    corner = OB_CORNER_TOPRIGHT;
                else if (data[3] == prop_atoms.net_wm_bottomright)
                    corner = OB_CORNER_BOTTOMRIGHT;
                else if (data[3] == prop_atoms.net_wm_bottomleft)
                    corner = OB_CORNER_BOTTOMLEFT;
                else
                    goto screen_update_layout_bail;
            }

            cols = data[1];
            rows = data[2];

            /* fill in a zero rows/columns */
            if ((cols == 0 && rows == 0)) { /* both 0's is bad data.. */
                goto screen_update_layout_bail;
            } else {
                if (cols == 0) {
                    cols = screen_num_desktops / rows;
                    if (rows * cols < screen_num_desktops)
                        cols++;
                    if (rows * cols >= screen_num_desktops + cols)
                        rows--;
                } else if (rows == 0) {
                    rows = screen_num_desktops / cols;
                    if (cols * rows < screen_num_desktops)
                        rows++;
                    if (cols * rows >= screen_num_desktops + rows)
                        cols--;
                }
            }

            /* bounds checking */
            if (orient == OB_ORIENTATION_HORZ) {
                cols = MIN(screen_num_desktops, cols);
                rows = MIN(rows, (screen_num_desktops + cols - 1) / cols);
                cols = screen_num_desktops / rows +
                    !!(screen_num_desktops % rows);
            } else {
                rows = MIN(screen_num_desktops, rows);
                cols = MIN(cols, (screen_num_desktops + rows - 1) / rows);
                rows = screen_num_desktops / cols +
                    !!(screen_num_desktops % cols);
            }

            valid = YES;
        }
    screen_update_layout_bail:
        free(data);
    }

    if (!valid) {
        /* defaults */
        orient = OB_ORIENTATION_HORZ;
        corner = OB_CORNER_TOPLEFT;
        rows = 1;
        cols = screen_num_desktops;
    }

    screen_desktop_layout.orientation = orient;
    screen_desktop_layout.start_corner = corner;
    screen_desktop_layout.rows = rows;
    screen_desktop_layout.columns = cols;
}

- (void) updateDesktopNames
{
    unsigned int i;
    NSArray *_names = nil;

    /* empty the array */
    [screen_desktop_names removeAllObjects];

    if (PROP_GETSS(RootWindow(ob_display, ob_screen),
                   net_desktop_names, utf8, &_names)) {
        for (i = 0; i < [_names count] && i <= screen_num_desktops; ++i) {
	  [screen_desktop_names addObject: [_names objectAtIndex: i]];
	}
    } else {
        i = 0;
    }
    if (i <= screen_num_desktops) {
        for (; i < screen_num_desktops; ++i)
	    [screen_desktop_names addObject: [NSString stringWithFormat: @"Desktop %i", i+1]];
    }
}

- (void) installColormap: (AZClient*) client
                  install: (BOOL) install
{
    XWindowAttributes wa;

    if (client == nil) {
        if (install)
            XInstallColormap([ob_rr_inst display], [ob_rr_inst colormap]);
        else
            XUninstallColormap([ob_rr_inst display], [ob_rr_inst colormap]);
    } else {
        if (XGetWindowAttributes(ob_display, [client window], &wa) &&
            wa.colormap != None) {
	    AZXErrorSetIgnore(YES);
            if (install)
                XInstallColormap([ob_rr_inst display], wa.colormap);
            else
                XUninstallColormap([ob_rr_inst display], wa.colormap);
	    AZXErrorSetIgnore(NO);
        }
    }
}

- (void) updateAreas
{
    unsigned int i, x;
    unsigned long *dims;
    int o;

    free(monitor_area);
    extensions_xinerama_screens(&monitor_area, &screen_num_monitors);

    if (area) {
        for (i = 0; area[i]; ++i)
            free(area[i]);
        free(area);
    }

    area = calloc(sizeof(Rect*), screen_num_desktops + 2);
    for (i = 0; i < screen_num_desktops + 1; ++i)
        area[i] = calloc(sizeof(Rect), screen_num_monitors + 1);
    area[i] = NULL;
     
    dims = calloc(sizeof(unsigned long), 4 * screen_num_desktops);

    for (i = 0; i < screen_num_desktops + 1; ++i) {
        Strut *struts;
        int l, r, t, b;

        struts = calloc(sizeof(Strut), screen_num_monitors);

        /* calc the xinerama areas */
        for (x = 0; x < screen_num_monitors; ++x) {
            area[i][x] = monitor_area[x];
            if (x == 0) {
                l = monitor_area[x].x;
                t = monitor_area[x].y;
                r = monitor_area[x].x + monitor_area[x].width - 1;
                b = monitor_area[x].y + monitor_area[x].height - 1;
            } else {
                l = MIN(l, monitor_area[x].x);
                t = MIN(t, monitor_area[x].y);
                r = MAX(r, monitor_area[x].x + monitor_area[x].width - 1);
                b = MAX(b, monitor_area[x].y + monitor_area[x].height - 1);
            }
        }
        RECT_SET(area[i][x], l, t, r - l + 1, b - t + 1);

        /* apply the struts */

        /* find the left-most xin heads, i do this in 2 loops :| */
        o = area[i][0].x;
        for (x = 1; x < screen_num_monitors; ++x)
            o = MIN(o, area[i][x].x);

        for (x = 0; x < screen_num_monitors; ++x) {
            AZClientManager *cManager = [AZClientManager defaultManager];
            int j, count = [cManager count];
	    for (j = 0; j < count; j++)
	    {
		AZClient *c = [cManager clientAtIndex: j];
		StrutPartial _strut = [c strut];
                screen_area_add_strut_left(&_strut,
                                           &monitor_area[x],
                                           o + [c strut].left - area[i][x].x,
                                           &struts[x]);
		[c set_strut: _strut];
            }

            area[i][x].x += struts[x].left;
            area[i][x].width -= struts[x].left;
        }

        /* find the top-most xin heads, i do this in 2 loops :| */
        o = area[i][0].y;
        for (x = 1; x < screen_num_monitors; ++x)
            o = MIN(o, area[i][x].y);

        for (x = 0; x < screen_num_monitors; ++x) {
            AZClientManager *cManager = [AZClientManager defaultManager];
            int j, count = [cManager count];
	    for (j = 0; j < count; j++)
	    {
	        AZClient *c = [cManager clientAtIndex: j];
		StrutPartial _strut = [c strut];
                screen_area_add_strut_top(&_strut,
                                           &monitor_area[x],
                                           o + [c strut].top - area[i][x].y,
                                           &struts[x]);
		[c set_strut: _strut];
            }

            area[i][x].y += struts[x].top;
            area[i][x].height -= struts[x].top;
        }

        /* find the right-most xin heads, i do this in 2 loops :| */
        o = area[i][0].x + area[i][0].width - 1;
        for (x = 1; x < screen_num_monitors; ++x)
            o = MAX(o, area[i][x].x + area[i][x].width - 1);

        for (x = 0; x < screen_num_monitors; ++x) {
            AZClientManager *cManager = [AZClientManager defaultManager];
            int j, count = [cManager count];
	    for (j = 0; j < count; j++)
	    {
	        AZClient *c = [cManager clientAtIndex: j];
		StrutPartial _strut = [c strut];
                screen_area_add_strut_right(&_strut,
                                           &monitor_area[x],
                                           (area[i][x].x +
                                            area[i][x].width - 1) -
                                            (o - [c strut].right),
                                            &struts[x]);
		[c set_strut: _strut];
            }

            area[i][x].width -= struts[x].right;
        }

        /* find the bottom-most xin heads, i do this in 2 loops :| */
        o = area[i][0].y + area[i][0].height - 1;
        for (x = 1; x < screen_num_monitors; ++x)
            o = MAX(o, area[i][x].y + area[i][x].height - 1);

        for (x = 0; x < screen_num_monitors; ++x) {
            AZClientManager *cManager = [AZClientManager defaultManager];
            int j, count = [cManager count];
	    for (j = 0; j < count; j++)
	    {
	        AZClient *c = [cManager clientAtIndex: j];
		StrutPartial _strut = [c strut];
                screen_area_add_strut_bottom(&_strut,
                                             &monitor_area[x],
                                             (area[i][x].y +
                                              area[i][x].height - 1) - \
                                             (o - [c strut].bottom),
                                             &struts[x]);
		[c set_strut: _strut];
            }

            area[i][x].height -= struts[x].bottom;
        }

        l = RECT_LEFT(area[i][0]);
        t = RECT_TOP(area[i][0]);
        r = RECT_RIGHT(area[i][0]);
        b = RECT_BOTTOM(area[i][0]);
        for (x = 1; x < screen_num_monitors; ++x) {
            l = MIN(l, RECT_LEFT(area[i][x]));
            t = MIN(l, RECT_TOP(area[i][x]));
            r = MAX(r, RECT_RIGHT(area[i][x]));
            b = MAX(b, RECT_BOTTOM(area[i][x]));
        }
        RECT_SET(area[i][screen_num_monitors], l, t,
                 r - l + 1, b - t + 1);

        /* XXX optimize when this is run? */

        /* the area has changed, adjust all the maximized 
           windows */
        AZClientManager *cManager = [AZClientManager defaultManager];
        int j, count = [cManager count];
        for (j = 0; j < count; j++)
        {
            AZClient *c = [cManager clientAtIndex: j];
            if (i < screen_num_desktops) {
                if ([c desktop] == i)
		    [c reconfigure];
            } else if ([c desktop] == DESKTOP_ALL)
		[c reconfigure];
        }
        if (i < screen_num_desktops) {
            /* don't set these for the 'all desktops' area */
            dims[(i * 4) + 0] = area[i][screen_num_monitors].x;
            dims[(i * 4) + 1] = area[i][screen_num_monitors].y;
            dims[(i * 4) + 2] = area[i][screen_num_monitors].width;
            dims[(i * 4) + 3] = area[i][screen_num_monitors].height;
        }

        free(struts);
    }

    PROP_SETA32(RootWindow(ob_display, ob_screen), net_workarea, cardinal,
                dims, 4 * screen_num_desktops);

    free(dims);
}

- (Rect *) physicalArea
{
  return [self physicalAreaOfMonitor: screen_num_monitors];
}

- (Rect *) physicalAreaOfMonitor: (unsigned int) head
{
    if (head > screen_num_monitors)
        return NULL;
    return &monitor_area[head];
}

- (Rect *) areaOfDesktop: (unsigned int) desktop
{
  return [self areaOfDesktop: desktop
	       monitor: screen_num_monitors];
}

- (Rect *) areaOfDesktop: (unsigned int) desktop
                 monitor: (unsigned int) head
{
    if (head > screen_num_monitors)
        return NULL;
    if (desktop >= screen_num_desktops) {
        if (desktop == DESKTOP_ALL)
            return &area[screen_num_desktops][head];
        return NULL;
    }
    return &area[desktop][head];
}

- (void) setRootCursor
{
    if ([[AZStartupHandler defaultHandler] applicationStarting])
        XDefineCursor(ob_display, RootWindow(ob_display, ob_screen),
                      ob_cursor(OB_CURSOR_BUSY));
    else
        XDefineCursor(ob_display, RootWindow(ob_display, ob_screen),
                      ob_cursor(OB_CURSOR_POINTER));
}

- (BOOL) pointerPosAtX: (int *) x y: (int *) y
{
    Window w;
    int i;
    unsigned int u;

    return !!XQueryPointer(ob_display, RootWindow(ob_display, ob_screen),
                           &w, &w, x, y, &i, &i, &u);
}

- (unsigned int) lastDesktop
{
  return screen_last_desktop;
}

- (NSString *) nameOfDesktopAtIndex: (unsigned int) index
{
  return [screen_desktop_names objectAtIndex: index];
}

- (Window) supportXWindow
{
  return screen_support_win;
}

- (unsigned int) numberOfMonitors
{
  return screen_num_monitors;
}

- (DesktopLayout) desktopLayout
{
  return screen_desktop_layout;
}

@end

@implementation AZScreen (AZPrivate)
#if 0

#include "debug.h"
#include "grab.h"
#include "event.h"
#include "extensions.h"
#include "render/render.h"

#include <X11/Xlib.h>
#ifdef HAVE_UNISTD_H
#  include <sys/types.h>
#  include <unistd.h>
#endif
#include <assert.h>

#endif

- (BOOL) replaceWM
{
    Atom wm_sn_atom;
    Window current_wm_sn_owner;
    Time timestamp;

    wm_sn_atom = XInternAtom(ob_display, (char*)[[NSString stringWithFormat: @"WM_S%d", ob_screen] cString], NO);

    current_wm_sn_owner = XGetSelectionOwner(ob_display, wm_sn_atom);
    if (current_wm_sn_owner == screen_support_win)
        current_wm_sn_owner = None;
    if (current_wm_sn_owner) {
        if (!ob_replace_wm) {
            NSLog(@"Warning: A window manager is already running on screen %d",
                      ob_screen);
            return NO;
        }
	AZXErrorSetIgnore(YES);
        xerror_occured = NO;

        /* We want to find out when the current selection owner dies */
        XSelectInput(ob_display, current_wm_sn_owner, StructureNotifyMask);
        XSync(ob_display, NO);

	AZXErrorSetIgnore(NO);
        if (xerror_occured)
            current_wm_sn_owner = None;
    }

    {
        /* Generate a timestamp */
        XEvent event;

        XSelectInput(ob_display, screen_support_win, PropertyChangeMask);

        XChangeProperty(ob_display, screen_support_win,
                        prop_atoms.wm_class, prop_atoms.string,
                        8, PropModeAppend, NULL, 0);
        XWindowEvent(ob_display, screen_support_win,
                     PropertyChangeMask, &event);

        XSelectInput(ob_display, screen_support_win, NoEventMask);

        timestamp = event.xproperty.time;
    }

    XSetSelectionOwner(ob_display, wm_sn_atom, screen_support_win,
                       timestamp);

    if (XGetSelectionOwner(ob_display, wm_sn_atom) != screen_support_win) {
        NSLog(@"Warning: Could not acquire window manager selection on screen %d", ob_screen);
        return NO;
    }

    /* Wait for old window manager to go away */
    if (current_wm_sn_owner) {
      XEvent event;
      unsigned long wait = 0;
      const unsigned long timeout = USEC_PER_SEC * 15; /* wait for 15s max */

      while (wait < timeout) {
          if (XCheckWindowEvent(ob_display, current_wm_sn_owner,
                                StructureNotifyMask, &event) &&
              event.type == DestroyNotify)
              break;
          usleep(USEC_PER_SEC / 10);
          wait += USEC_PER_SEC / 10;
      }

      if (wait >= timeout) {
          NSLog(@"Timeout expired while waiting for the current WM to die "
                    "on screen %d", ob_screen);
          return NO;
      }
    }

    /* Send client message indicating that we are now the WM */
    prop_message(RootWindow(ob_display, ob_screen), prop_atoms.manager,
                 timestamp, wm_sn_atom, 0, 0, SubstructureNotifyMask);


    return YES;
}

- (void) getRowCol: (unsigned int) d
              row: (unsigned int *) r
	      col: (unsigned int *) c
{
    switch (screen_desktop_layout.orientation) {
    case OB_ORIENTATION_HORZ:
        switch (screen_desktop_layout.start_corner) {
        case OB_CORNER_TOPLEFT:
            *r = d / screen_desktop_layout.columns;
            *c = d % screen_desktop_layout.columns;
            break;
        case OB_CORNER_BOTTOMLEFT:
            *r = screen_desktop_layout.rows - 1 -
                d / screen_desktop_layout.columns;
            *c = d % screen_desktop_layout.columns;
            break;
        case OB_CORNER_TOPRIGHT:
            *r = d / screen_desktop_layout.columns;
            *c = screen_desktop_layout.columns - 1 -
                d % screen_desktop_layout.columns;
            break;
        case OB_CORNER_BOTTOMRIGHT:
            *r = screen_desktop_layout.rows - 1 -
                d / screen_desktop_layout.columns;
            *c = screen_desktop_layout.columns - 1 -
                d % screen_desktop_layout.columns;
            break;
        }
        break;
    case OB_ORIENTATION_VERT:
        switch (screen_desktop_layout.start_corner) {
        case OB_CORNER_TOPLEFT:
            *r = d % screen_desktop_layout.rows;
            *c = d / screen_desktop_layout.rows;
            break;
        case OB_CORNER_BOTTOMLEFT:
            *r = screen_desktop_layout.rows - 1 -
                d % screen_desktop_layout.rows;
            *c = d / screen_desktop_layout.rows;
            break;
        case OB_CORNER_TOPRIGHT:
            *r = d % screen_desktop_layout.rows;
            *c = screen_desktop_layout.columns - 1 -
                d / screen_desktop_layout.rows;
            break;
        case OB_CORNER_BOTTOMRIGHT:
            *r = screen_desktop_layout.rows - 1 -
                d % screen_desktop_layout.rows;
            *c = screen_desktop_layout.columns - 1 -
                d / screen_desktop_layout.rows;
            break;
        }
        break;
    }
}

- (unsigned int) translateRow: (unsigned int) r col: (unsigned int) c
{
    switch (screen_desktop_layout.orientation) {
    case OB_ORIENTATION_HORZ:
        switch (screen_desktop_layout.start_corner) {
        case OB_CORNER_TOPLEFT:
            return r % screen_desktop_layout.rows *
                screen_desktop_layout.columns +
                c % screen_desktop_layout.columns;
        case OB_CORNER_BOTTOMLEFT:
            return (screen_desktop_layout.rows - 1 -
                    r % screen_desktop_layout.rows) *
                screen_desktop_layout.columns +
                c % screen_desktop_layout.columns;
        case OB_CORNER_TOPRIGHT:
            return r % screen_desktop_layout.rows *
                screen_desktop_layout.columns +
                (screen_desktop_layout.columns - 1 -
                 c % screen_desktop_layout.columns);
        case OB_CORNER_BOTTOMRIGHT:
            return (screen_desktop_layout.rows - 1 -
                    r % screen_desktop_layout.rows) *
                screen_desktop_layout.columns +
                (screen_desktop_layout.columns - 1 -
                 c % screen_desktop_layout.columns);
        }
    case OB_ORIENTATION_VERT:
        switch (screen_desktop_layout.start_corner) {
        case OB_CORNER_TOPLEFT:
            return c % screen_desktop_layout.columns *
                screen_desktop_layout.rows +
                r % screen_desktop_layout.rows;
        case OB_CORNER_BOTTOMLEFT:
            return c % screen_desktop_layout.columns *
                screen_desktop_layout.rows +
                (screen_desktop_layout.rows - 1 -
                 r % screen_desktop_layout.rows);
        case OB_CORNER_TOPRIGHT:
            return (screen_desktop_layout.columns - 1 -
                    c % screen_desktop_layout.columns) *
                screen_desktop_layout.rows +
                r % screen_desktop_layout.rows;
        case OB_CORNER_BOTTOMRIGHT:
            return (screen_desktop_layout.columns - 1 -
                    c % screen_desktop_layout.columns) *
                screen_desktop_layout.rows +
                (screen_desktop_layout.rows - 1 -
                 r % screen_desktop_layout.rows);
        }
    }
    NSAssert(0, @"Should not reach");
    return 0;
}

@end

static inline void
screen_area_add_strut_left(const StrutPartial *s, const Rect *monitor_area,
                           int edge, Strut *ret)
{
    if (s->left &&
        ((s->left_end <= s->left_start) ||
         (RECT_TOP(*monitor_area) < s->left_end &&
          RECT_BOTTOM(*monitor_area) > s->left_start)))
        ret->left = MAX(ret->left, edge);
}

static inline void
screen_area_add_strut_top(const StrutPartial *s, const Rect *monitor_area,
                          int edge, Strut *ret)
{
    if (s->top &&
        ((s->top_end <= s->top_start) ||
         (RECT_LEFT(*monitor_area) < s->top_end &&
          RECT_RIGHT(*monitor_area) > s->top_start)))
        ret->top = MAX(ret->top, edge);
}

static inline void
screen_area_add_strut_right(const StrutPartial *s, const Rect *monitor_area,
                            int edge, Strut *ret)
{
    if (s->right &&
        ((s->right_end <= s->right_start) ||
         (RECT_TOP(*monitor_area) < s->right_end &&
          RECT_BOTTOM(*monitor_area) > s->right_start)))
        ret->right = MAX(ret->right, edge);
}

static inline void
screen_area_add_strut_bottom(const StrutPartial *s, const Rect *monitor_area,
                             int edge, Strut *ret)
{
    if (s->bottom &&
        ((s->bottom_end <= s->bottom_start) ||
         (RECT_LEFT(*monitor_area) < s->bottom_end &&
          RECT_RIGHT(*monitor_area) > s->bottom_start)))
        ret->bottom = MAX(ret->bottom, edge);
}

