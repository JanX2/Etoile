/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-
   
   AZClientManager.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   client.c for the Openbox window manager
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

#import "AZClientManager.h"
#import "AZClient+Place.h"
#import "AZClient+GNUstep.h"
#import "AZScreen.h"
#import "AZStartupHandler.h"
#import "AZEventHandler.h"
#import "AZGroup.h"
#import "AZStacking.h"
#import "AZFrame.h"
#import "AZFocusManager.h"
#import "AZKeyboardHandler.h"
#import "AZMouseHandler.h"
#import "config.h"
#import "openbox.h"
#import "grab.h"
#import "prop.h"
#import "AZMenuFrame.h"

#ifdef HAVE_UNISTD_H
#  include <unistd.h>
#endif

NSString *AZClientDestroyNotification = @"AZClientDestroyNotification";

/*! The event mask to grab on client windows */
#define CLIENT_EVENTMASK (PropertyChangeMask | StructureNotifyMask | \
                          ColormapChangeMask)

#define CLIENT_NOPROPAGATEMASK (ButtonPressMask | ButtonReleaseMask | \
                                ButtonMotionMask)

static AZClientManager *sharedInstance;

@implementation AZClientManager

- (void) startup: (BOOL) reconfig
{
  if (reconfig) return;

  [self setList];
}

- (void) shutdown: (BOOL) reconfig
{
}

- (void) setList
{
    Window *windows, *win_it;
    int i, count = [clist count];

    /* create an array of the window ids */
    if (count > 0) {
	windows = malloc(sizeof(Window)*count);
        win_it = windows;
	for (i = 0; i < count; i++, win_it++)
	  *win_it = [[clist objectAtIndex: i] window];
    } else
        windows = NULL;

    PROP_SETA32(RootWindow(ob_display, ob_screen),
                net_client_list, window, (unsigned long*)windows, count);

    if (windows)
        free(windows);

    [[AZStacking stacking] setList];
}

- (void) manageAll
{
    unsigned int i, j, nchild;
    Window w, *children;
    XWMHints *wmhints;
    XWindowAttributes attrib;

    XQueryTree(ob_display, RootWindow(ob_display, ob_screen),
               &w, &w, &children, &nchild);

    /* remove all icon windows from the list */
    for (i = 0; i < nchild; i++) {
        if (children[i] == None) continue;
        wmhints = XGetWMHints(ob_display, children[i]);
        if (wmhints) {
            if ((wmhints->flags & IconWindowHint) &&
                (wmhints->icon_window != children[i]))
                for (j = 0; j < nchild; j++)
                    if (children[j] == wmhints->icon_window) {
                        children[j] = None;
                        break;
                    }
            XFree(wmhints);
        }
    }

    for (i = 0; i < nchild; ++i) {
        if (children[i] == None)
            continue;
        if (XGetWindowAttributes(ob_display, children[i], &attrib)) {
            if (attrib.override_redirect) continue;

            if (attrib.map_state != IsUnmapped)
		[self manageWindow: children[i]];
        }
    }
    XFree(children);
}

- (void) manageWindow: (Window) window
{
    AZClient *client;
    XEvent e;
    XWindowAttributes attrib;
    XSetWindowAttributes attrib_set;
    XWMHints *wmhint;
    BOOL activate = NO;
    int newx, newy;
    AZScreen *screen = [AZScreen defaultScreen];
    AZFocusManager *fManager = [AZFocusManager defaultManager];

    grab_server(YES);

    /* check if it has already been unmapped by the time we started mapping.
       the grab does a sync so we don't have to here */
    if (XCheckTypedWindowEvent(ob_display, window, DestroyNotify, &e) ||
        XCheckTypedWindowEvent(ob_display, window, UnmapNotify, &e)) {
        XPutBackEvent(ob_display, &e);

	/* Trying to manage unmapped window. Aborting that. */
        grab_server(NO);
        return; /* don't manage it */
    }

    /* make sure it isn't an override-redirect window */
    if (!XGetWindowAttributes(ob_display, window, &attrib) ||
        attrib.override_redirect) {
        grab_server(NO);
        return; /* don't manage it */
    }
  
    /* is the window a docking app */
    if ((wmhint = XGetWMHints(ob_display, window))) 
    {
        if ((wmhint->flags & StateHint) &&
            wmhint->initial_state == WithdrawnState) 
	{
            [[workspace notificationCenter]
                       postNotificationName: @"AZDockletDidLaunchNotification"
                       object: workspace
                       userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
                   [NSString stringWithFormat: @"%d", window], @"AZXWindowID",
                                 nil]
                       ];
            grab_server(NO);
            XFree(wmhint);
            return;
        }
        XFree(wmhint);
    }

    AZDebug("Managing window: %lx\n", window);

    /* choose the events we want to receive on the CLIENT window */
    attrib_set.event_mask = CLIENT_EVENTMASK;
    attrib_set.do_not_propagate_mask = CLIENT_NOPROPAGATEMASK;
    XChangeWindowAttributes(ob_display, window,
                            CWEventMask|CWDontPropagate, &attrib_set);


    /* create the ObClient struct, and populate it from the hints on the
       window */
    client = [[AZClient alloc] init];
    [client set_window: window];

    /* non-zero defaults */
    [client set_wmstate: WithdrawnState]; /* make sure it gets updated first time */
    [client set_layer: -1];
    [client set_desktop: [screen numberOfDesktops]]; /* always an invalid value */
    [client set_user_time: CurrentTime]; 

    [client getAll];
    [client restoreSessionState];

    [client calcLayer];
 
    {
      Time t = [[AZStartupHandler defaultHandler] 
                 applicationStarted: (char*)[[client startup_id] cString]
                              class: (char*)[[client class] cString]];
      if (t) 
        [client set_user_time: t];
    }

    /* update the focus lists, do this before the call to change_state or
       it can end up in the list twice! */
    [fManager focusOrderAdd: client];

    /* remove the client's border (and adjust re gravity) */
    [client toggleBorder: NO];
     
    /* specify that if we exit, the window should not be destroyed and should
       be reparented back to root automatically */
    XChangeSaveSet(ob_display, window, SetModeInsert);

    /* create the decoration frame for the client window */
    [client set_frame: AUTORELEASE([[AZFrame alloc] initWithClient: client])];

    [[client frame] grabClient: client];

    /* do this after we have a frame.. it uses the frame to help determine the
       WM_STATE to apply. */
    [client changeState];

    grab_server(NO);

    [[AZStacking stacking] addWindowNonIntrusively: client];
    [client restoreSessionStacking];

    /* focus the new window? */
    if (ob_state() != OB_STATE_STARTING &&
        (config_focus_new || [client searchFocusParent]) &&
        /* note the check against Type_Normal/Dialog, not client_normal(client),
           which would also include other types. in this case we want more
           strict rules for focus */
        ([client type] == OB_CLIENT_TYPE_NORMAL ||
         [client type] == OB_CLIENT_TYPE_DIALOG))
    {        
        activate = YES;
    }

    /* get the current position */
    newx = [client area].x;
    newy = [client area].y;
 
    /* figure out placement for the window */
    if (ob_state() == OB_STATE_RUNNING) {
	BOOL transient = [client placeAtX: &newx y: &newy];

        /* make sure the window is visible. */
	[client findOnScreenAtX: &newx y: &newy
		width: [[client frame] area].width
		height: [[client frame] area].height
                             /* non-normal clients has less rules, and
                                windows that are being restored from a
                                session do also. we can assume you want
                                it back where you saved it. Clients saying
                                they placed themselves are subjected to
                                harder rules, ones that are placed by
                                place.c or by the user are allowed partially
                                off-screen and on xinerama divides (ie,
                                it is up to the placement routines to avoid
                                the xinerama divides) */
                        rude: transient ||
			     ((([client positioned] & PPosition) &&
                              !([client positioned] & USPosition)) &&
                             [client normal] &&
                             ![client session])];
    }

    /* do this after the window is placed, so the premax/prefullscreen numbers
       won't be all wacko!!
       also, this moves the window to the position where it has been placed
    */
    [client applyStartupStateAtX: newx y: newy];

    [[AZKeyboardHandler defaultHandler] grab: YES forClient: client];
    [[AZMouseHandler defaultHandler] grab: YES forClient: client];

    if (activate) {
	unsigned int last_time = [fManager focus_client] ? 
                   [[fManager focus_client] user_time] : CurrentTime;

        /* This is focus stealing prevention */

        /* If a nothing at all, or a parent was focused, then focus this
           always
        */
        if (![fManager focus_client] || [client searchFocusParent] != nil)
	{
            activate = YES;
	}
        else
        {
            /* If time stamp is old, don't steal focus */
            if ([client user_time] && last_time &&
                !event_time_after([client user_time], last_time))
            {
                activate = NO;
            }
            /* Don't steal focus from globally active clients.
               I stole this idea from KWin. It seems nice.
             */
            if (!([[fManager focus_client] can_focus] || 
	          [[fManager focus_client] focus_notify]))
                activate = NO;
        }

        if (activate)
        {
            /* since focus can change the stacking orders, if we focus the
               window then the standard raise it gets is not enough, we need
               to queue one for after the focus change takes place */
	    [client raise];
        } else {
            /* if the client isn't focused, then hilite it so the user
               knows it is there */
	    [client hilite: YES];
        }
    }
    else {
        /* This may look rather odd. Well it's because new windows are added
           to the stacking order non-intrusively. If we're not going to focus
           the new window or hilite it, then we raise it to the top. This will
           take affect for things that don't get focused like splash screens.
           Also if you don't have focus_new enabled, then it's going to get
           raised to the top. Legacy begets legacy I guess?
        */
	[client raise];
    }

    /* this has to happen before we try focus the window, but we want it to
       happen after the client's stacking has been determined or it looks bad
    */
    [client show];

    /* use client_focus instead of client_activate cuz client_activate does
       stuff like switch desktops etc and I'm not interested in all that when
       a window maps since its not based on an action from the user like
       clicking a window to activate is. so keep the new window out of the way
       but do focus it. */
    if (activate) {
	[client focus];
    }

    /* client_activate does this but we aren't using it so we have to do it
       here as well */
    if ([screen showingDesktop])
      [screen showDesktop: NO];

    /* add to client list/map */
    [clist addObject: client];
    [window_map setObject: client forKey: [NSNumber numberWithInt: [client window]]];

    /* this has to happen after we're in the client_list */
    if (STRUT_EXISTS([client strut]))
      [screen updateAreas];

    /* update the list hints */
    [self setList];

    [[workspace notificationCenter]
                       postNotificationName: @"AZXWindowDidLaunchNotification"
                       object: workspace
                       userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
           [NSString stringWithFormat: @"%d", window], @"AZXWindowID",
                                 nil]
                       ];
    AZDebug("Managed window 0x%lx (%s)\n", window, [client class]);
}

- (void) unmanageAll
{
  int i, count = [clist count];
  for (i = count-1; i > -1; i--)
  {
    [self unmanageClient: [clist objectAtIndex: i]];
  }
}

- (void) unmanageClient: (AZClient *) client
{
    NSAssert(client != NULL, @"Client cannot be nil");
    AZFocusManager *fManager = [AZFocusManager defaultManager];

    /* we dont want events no more. do this before hiding the frame so we
       don't generate more events */
    XSelectInput(ob_display, [client window], NoEventMask);
    [[client frame] hide];
    /* flush to send the hide to the server quickly */
    XFlush(ob_display);

    if ([fManager focus_client] == client) {
        /* ignore enter events from the unmap so it doesnt mess with the focus
         */
	[[AZEventHandler defaultHandler] ignoreQueuedEnters];
    }

    [[AZKeyboardHandler defaultHandler] grab: NO forClient: client];
    [[AZMouseHandler defaultHandler] grab: NO forClient: client];

    /* remove the window from our save set */
    XChangeSaveSet(ob_display, [client window], SetModeDelete);

    /* update the focus lists */
    [fManager focusOrderRemove: client];
    /* don't leave an invalid focus_client */
    if (self == [fManager focus_client])
        [fManager set_focus_client: nil];

    [clist removeObject: client];
    [[AZStacking stacking] removeWindow: client];
    [window_map removeObjectForKey: [NSNumber numberWithInt: [client window]]];

    /* once the client is out of the list, update the struts to remove its
       influence */
    if (STRUT_EXISTS([client strut]))
      [[AZScreen defaultScreen] updateAreas];

    [[NSNotificationCenter defaultCenter] postNotificationName: AZClientDestroyNotification
	    object: client];
    /* Taken from menu (AZMenu in the future). Since it uses global function,
     * it is not really suitable in object, or it will be called multiple
     * time in each object, which is not good */
    /* menus can be associated with a client, so close any that are since
       we are disappearing now */
    AZMenuFrameHideAllClient(client);

    /* tell our parent(s) that we're gone */
    if ([client transient_for] == OB_TRAN_GROUP) { /* transient of group */
	int i, count = [[[client group] members] count];
	for (i = 0; i < count; i++)
	{
	  AZClient *data = [[client group] memberAtIndex: i];
	  if (data != client)
	  {
            [data removeTransient: client];
	  }
	}
    } else if ([client transient_for]) {        /* transient of window */
	[[client transient_for] removeTransient: client];
    }

    /* tell our transients that we're gone */
    int k, kcount = [[client transients] count];
    AZClient *temp = nil;
    for (k = 0; k < kcount; k++) {
	temp = [[client transients] objectAtIndex: k];
        if ([temp transient_for] != OB_TRAN_GROUP) {
            [temp set_transient_for: NULL];
	    [temp calcLayer];
        }
    }

    /* remove from its group */
    if ([client group]) {
	[[AZGroupManager defaultManager] removeClient: client fromGroup: [client group]];
	[client set_group: nil];
    }

    /* give the client its border back */
    [client toggleBorder: YES];
    /* restore the window's original geometry so it is not lost */
    {
        Rect a = [client area];

        if ([client fullscreen])
            a = [client pre_fullscreen_area];
        else if ([client max_horz] || [client max_vert]) {
            if ([client max_horz]) {
                a.x = [client pre_max_area].x;
                a.width = [client pre_max_area].width;
            }
            if ([client max_vert]) {
                a.y = [client pre_max_area].y;
                a.height = [client pre_max_area].height;
            }
        }

        /* give the client its border back */
        [client toggleBorder: YES];

        [client set_fullscreen: NO];
	[client set_max_horz: NO];
	[client set_max_vert: NO];
	[client set_decorations: 0];  /* unmanaged windows have no decor */ 

	[client moveAndResizeToX: a.x y: a.y width: a.width height: a.height];
    }

    /* reparent the window out of the frame, and free the frame */
    [[client frame] releaseClient: client];
    [client set_frame: nil];

    if (ob_state() != OB_STATE_EXITING) {
        /* these values should not be persisted across a window
           unmapping/mapping */
        PROP_ERASE([client window], net_wm_desktop);
        PROP_ERASE([client window], net_wm_state);
        PROP_ERASE([client window], wm_state);
    } else {
        /* if we're left in an unmapped state, the client wont be mapped. this
           is bad, since we will no longer be managing the window on restart */
        XMapWindow(ob_display, [client window]);
    }


    AZDebug("Unmanaged window 0x%lx\n", [client window]);

    [[workspace notificationCenter]
                   postNotificationName: @"AZXWindowDidTerminateNotification"
                   object: workspace
                   userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
           [NSString stringWithFormat: @"%d", [client window]], @"AZXWindowID",
                                 nil]
                       ];

    /* free all data allocated in the client struct */
    [client removeAllTransients];
    [client removeAllIcons];
    DESTROY(client);
     
    /* update the list hints */
    [self setList];
}

- (AZClient *) clientAtIndex: (int) index
{
  return [clist objectAtIndex: index];
}

- (int) count
{
  return [clist count];
}

- (int) indexOfClient: (AZClient *) client
{
  return [clist indexOfObject: client];
}

- (id) init
{
  self = [super init];
  clist = [[NSMutableArray alloc] init];
  workspace = [NSWorkspace sharedWorkspace];
  return self;
}

- (void) dealloc
{
  DESTROY(clist);
  [super dealloc];
}

+ (AZClientManager *) defaultManager
{
  if (sharedInstance == nil)
  {
    sharedInstance = [[AZClientManager alloc] init];
  }
  return sharedInstance;
}

@end
