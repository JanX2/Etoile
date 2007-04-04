/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZEventHandler.h for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   event.c for the Openbox window manager
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

#import "AZEventHandler.h"
#import "AZMainLoop.h"
#import "AZScreen.h"
#import "AZDebug.h"
#import "AZGroup.h"
#import "AZClientManager.h"
#import "AZClient+GNUstep.h"
#import "AZFrame+Render.h"
#import "AZMoveResizeHandler.h"
#import "AZFocusManager.h"
#import "AZMenuFrame.h"
#import "AZMenu.h"
#import "AZMouseHandler.h"
#import "openbox.h"
#import "config.h"
#import "prop.h"
#import "extensions.h"
#import "AZKeyboardHandler.h"

#import <X11/keysym.h>
#import <X11/Xatom.h>

#ifdef HAVE_SYS_SELECT_H
#  include <sys/select.h>
#endif
#ifdef HAVE_SIGNAL_H
#  include <signal.h>
#endif
#ifdef XKB
#  include <X11/XKBlib.h>
#endif

#ifdef USE_SM
#include <X11/ICE/ICElib.h>
#endif

typedef struct
{
    BOOL ignored;
} ObEventData;

#define INVALID_FOCUSIN(e) ((e)->xfocus.detail == NotifyInferior || \
                            (e)->xfocus.detail == NotifyAncestor || \
                            (e)->xfocus.detail > NotifyNonlinearVirtual)
#define INVALID_FOCUSOUT(e) ((e)->xfocus.mode == NotifyGrab || \
                             (e)->xfocus.detail == NotifyInferior || \
                             (e)->xfocus.detail == NotifyAncestor || \
                             (e)->xfocus.detail > NotifyNonlinearVirtual)

/*! Table of the constant modifier masks */
static const int mask_table[] = {
    ShiftMask, LockMask, ControlMask, Mod1Mask,
    Mod2Mask, Mod3Mask, Mod4Mask, Mod5Mask
};


#ifdef USE_SM
static void ice_handler(int fd, void *conn)
{
    Bool b;
    IceProcessMessages(conn, NULL, &b);
}

static void ice_watch(IceConn conn, IcePointer data, Bool opening,
                      IcePointer *watch_data)
{
    static int fd = -1;
    AZMainLoop *mainLoop = [AZMainLoop mainLoop];

    if (opening) {
        fd = IceConnectionNumber(conn);
	[mainLoop addFdHandler: ice_handler
		         forFd: fd
			  data: conn];
    } else {
	[mainLoop removeFdHandlerForFd: fd];
        fd = -1;
    }
}
#endif

static AZEventHandler *sharedInstance;

@interface AZEventHandler (AZPrivate)
- (void) handleRootEvent: (XEvent *) e;
- (void) handleMenuEvent: (XEvent *) e;
- (void) handleClient: (AZClient *) c event: (XEvent *) e;
- (void) handleGroup: (AZGroup *) g event: (XEvent *) e;

- (AZMenuFrame *) findActiveMenu;
- (AZMenuFrame *) findActiveOrLastMenu;
- (Window) getWindow: (XEvent *) e;
- (void) setLastTime: (XEvent *) e;
- (void) hackMods: (XEvent *) e;
- (BOOL) ignoreEvent: (XEvent *) e forClient: (AZClient *) client;

/* callback */
- (void) processEvent: (XEvent *) e data: (void *) data;
- (void) clientDestroy: (NSNotification *) not;
- (BOOL) focusDelayFunc: (id) data;
- (BOOL) menuHideDelayFunc: (id) data;
@end

@implementation AZEventHandler

- (void) processXEvent: (XEvent *) e
{
  [self processEvent: e data: NULL];
}

+ (AZEventHandler *) defaultHandler
{
  if (sharedInstance == nil)
  {
    sharedInstance = [[AZEventHandler alloc] init];
  }
  return sharedInstance;
}

- (id) init
{
  self = [super init];
  event_lasttime = 0;
  event_curtime = CurrentTime;
  return self;
}

- (void) dealloc
{
  [super dealloc];
}

- (void) startup: (BOOL) reconfig
{
    if (reconfig) return;

    mask_table_size = sizeof(mask_table) / sizeof(mask_table[0]);
     
    /* get lock masks that are defined by the display (not constant) */
    modmap = XGetModifierMapping(ob_display);
    NSAssert(modmap != NULL, @"Cannot get ModifierMapping");
    if (modmap && modmap->max_keypermod > 0) {
        size_t cnt;
        const size_t size = mask_table_size * modmap->max_keypermod;
        /* get the values of the keyboard lock modifiers
           Note: Caps lock is not retrieved the same way as Scroll and Num
           lock since it doesn't need to be. */
        const KeyCode num_lock = XKeysymToKeycode(ob_display, XK_Num_Lock);
        const KeyCode scroll_lock = XKeysymToKeycode(ob_display,
                                                     XK_Scroll_Lock);

        for (cnt = 0; cnt < size; ++cnt) {
            if (! modmap->modifiermap[cnt]) continue;

            if (num_lock == modmap->modifiermap[cnt])
                NumLockMask = mask_table[cnt / modmap->max_keypermod];
            if (scroll_lock == modmap->modifiermap[cnt])
                ScrollLockMask = mask_table[cnt / modmap->max_keypermod];
        }
    }

    [[AZMainLoop mainLoop] addXHandler: self];

#ifdef USE_SM
    IceAddConnectionWatch(ice_watch, NULL);
#endif

    [[NSNotificationCenter defaultCenter] addObserver: self
	    selector: @selector(clientDestroy:)
	    name: AZClientDestroyNotification
	    object: nil];
}

- (void) shutdown: (BOOL) reconfig
{
    if (reconfig) return;

#ifdef USE_SM
    IceRemoveConnectionWatch(ice_watch, NULL);
#endif

    [[NSNotificationCenter defaultCenter] removeObserver: self];

    XFreeModifiermap(modmap);
}

- (void) enterClient: (AZClient *) client;
{
    NSAssert(config_focus_follow == YES, @"enterClient:");

    if ([client normal] && [client canFocus]) {
        if (config_focus_delay) {
	  AZMainLoop *mainLoop = [AZMainLoop mainLoop];
	  [mainLoop removeTimeout: self handler: @selector(focusDelayFunc:)];
	  [mainLoop addTimeout: self handler: @selector(focusDelayFunc:)
		         microseconds: config_focus_delay
			 data: client 
			 notify: NULL];
        } else
	    [self focusDelayFunc: client];
    }
}

- (void) haltFocusDelay
{
  [[AZMainLoop mainLoop] removeTimeout: self handler: @selector(focusDelayFunc:)];
}

- (void) ignoreQueuedEnters
{
    NSMutableArray *saved = [[NSMutableArray alloc] init];
    int i, count;
    XEvent *e;
                
    XSync(ob_display, NO);

    /* count the events */
    while (YES) {
	e = calloc(sizeof(XEvent), 1);
        if (XCheckTypedEvent(ob_display, EnterNotify, e)) {
            id _win;
            
	    _win = [window_map objectForKey: [NSNumber numberWithInt: e->xany.window]];
            if (_win && [_win isKindOfClass: [AZClient class]])
                ++ignore_enter_focus;
            
	    [saved addObject: [NSValue valueWithPointer: e]];
        } else {
	    free(e);
	    e = NULL;
            break;
        }
    }
    /* put the events back */
    count = [saved count];
    for (i = 0; i < count; i++) {
	e = [[saved objectAtIndex: i] pointerValue];
        XPutBackEvent(ob_display, e);
	free(e);
	e = NULL;
    }
    DESTROY(saved);
}

- (Time) eventLastTime
{
  return event_lasttime;
}

- (Time) eventCurrentTime
{
  return event_curtime;
}

- (unsigned int) numLockMask
{
  return NumLockMask;
}

- (unsigned int) scrollLockMask
{
  return ScrollLockMask;
}

- (id) copyWithZone: (NSZone *) zone
{
  return RETAIN(self);
}

@end

@implementation AZEventHandler (AZPrivate)

- (void) processEvent: (XEvent *) ec data: (void *) data
{
    Window window;
    AZGroup *group = nil;
    AZClient *client = nil;
    XEvent ee, *e;
    ObEventData *ed = data;

    /* make a copy we can mangle */
    ee = *ec;
    e = &ee;

    window = [self getWindow: e];
    if (!(e->type == PropertyNotify &&
          (group = [[AZGroupManager defaultManager] groupWithLeader: window])))
    {
	id _win = nil;
        if ((_win = [window_map objectForKey: [NSNumber numberWithInt: window]])) {
	    if ([_win isKindOfClass: [AZClient class]]) {
		    client = _win;
	    } else {
                /*Window_Menu:*/
                /*Window_Internal: */
                /* not to be used for events */
		NSAssert(NO, @"Should not reach here");
	    }
	}
    }

    [self setLastTime: e];
    [self hackMods: e];
    if ([self ignoreEvent: e forClient: client]) {
        if (ed)
            ed->ignored = YES;
        return;
    } else if (ed)
            ed->ignored = NO;

    /* deal with it in the kernel */
    if (group)
        [self handleGroup: group event:  e];
    else if (client) 
        [self handleClient: client event:  e];
    else if (window == RootWindow(ob_display, ob_screen))
        [self handleRootEvent: e];
    else if (e->type == MapRequest) 
	[[AZClientManager defaultManager] manageWindow: window];
    else if (e->type == ConfigureRequest) {
        /* unhandled configure requests must be used to configure the
           window directly */
        XWindowChanges xwc;

        xwc.x = e->xconfigurerequest.x;
        xwc.y = e->xconfigurerequest.y;
        xwc.width = e->xconfigurerequest.width;
        xwc.height = e->xconfigurerequest.height;
        xwc.border_width = e->xconfigurerequest.border_width;
        xwc.sibling = e->xconfigurerequest.above;
        xwc.stack_mode = e->xconfigurerequest.detail;
       
        /* we are not to be held responsible if someone sends us an
           invalid request! */
	AZXErrorSetIgnore(YES);
        XConfigureWindow(ob_display, window,
                         e->xconfigurerequest.value_mask, &xwc);
	AZXErrorSetIgnore(NO);
    }

    /* user input (action-bound) events */
    if (e->type == ButtonPress || e->type == ButtonRelease ||
        e->type == MotionNotify || e->type == KeyPress ||
        e->type == KeyRelease)
    {
        if ([[AZMenuFrame visibleFrames] count])
            [self handleMenuEvent: e];
        else {
	    AZKeyboardHandler *kHandler = [AZKeyboardHandler defaultHandler];
	    if (![kHandler processInteractiveGrab: e forClient: &client]) {
		AZMoveResizeHandler *mrHandler = [AZMoveResizeHandler defaultHandler];
		if ([mrHandler moveresize_in_progress]) {
 		   [mrHandler event: e];

                    /* make further actions work on the client being
                       moved/resized */
		    client = [mrHandler moveresize_client];
                }

                menu_can_hide = NO;
		[[AZMainLoop mainLoop] addTimeout: self 
			     handler: @selector(menuHideDelayFunc:)
	                     microseconds: config_menu_hide_delay * 1000
			     data: nil notify: NULL];

                if (e->type == ButtonPress || e->type == ButtonRelease ||
                    e->type == MotionNotify) {
                    [[AZMouseHandler defaultHandler] processEvent: e forClient: client];
		} else if (e->type == KeyPress) {
		    AZFocusManager *fManager = [AZFocusManager defaultManager];
		    AZClient *focus_cycle_target = [fManager focus_cycle_target];
		    AZClient *focus_hilite = [fManager focus_hilite];
		    [kHandler processEvent: e
			    forClient: (focus_cycle_target ? focus_cycle_target: (focus_hilite ? focus_hilite : client))];
		}
            }
        }
    }
}

- (void) handleRootEvent: (XEvent *) e
{
    Atom msgtype;
    AZScreen *screen = [AZScreen defaultScreen];
     
    switch(e->type) {
    case SelectionClear:
        AZDebug("Another WM has requested to replace us. Exiting.\n");
        ob_exit_replace();
        break;

    case ClientMessage:
        if (e->xclient.format != 32) break;

        msgtype = e->xclient.message_type;
        if (msgtype == prop_atoms.net_current_desktop) {
            unsigned int d = e->xclient.data.l[0];
            if (d < [screen numberOfDesktops])
	    {
		[screen setDesktop: d];
	    }
        } else if (msgtype == prop_atoms.net_number_of_desktops) {
            unsigned int d = e->xclient.data.l[0];
            if (d > 0)
	    {
		[screen setNumberOfDesktops: d];
	    }
        } else if (msgtype == prop_atoms.net_showing_desktop) {
	    [screen showDesktop: (e->xclient.data.l[0] != 0)];
        } else if (msgtype == prop_atoms.ob_control) {
            if (e->xclient.data.l[0] == 1) /* reconfigure */
		ob_reconfigure();
            else if (e->xclient.data.l[0] == 2) /* restart */
		ob_restart();
        }
        break;
    case PropertyNotify:
        if (e->xproperty.atom == prop_atoms.net_desktop_names)
	{
	    [screen updateDesktopNames];
	}
        else if (e->xproperty.atom == prop_atoms.net_desktop_layout)
	{
	    [screen updateLayout];
	}
        break;
    case ConfigureNotify:
#ifdef XRANDR
        XRRUpdateConfiguration(e);
#endif
	[screen resize];
        break;
    default:
        ;
    }
}

- (void) handleGroup: (AZGroup *) group event: (XEvent *) e
{
    //NSAssert(e->type == PropertyNotify, @"Not a PropertyNotify");

    int i, count = [[group members] count];
    for (i = 0; i < count; i++)
      [self handleClient: [group memberAtIndex: i] event: e];
}

- (void) handleClient: (AZClient *) client event: (XEvent *) e
{
    XEvent ce;
    Atom msgtype;
    int i=0;
    ObFrameContext con;
     
    switch (e->type) {
    case VisibilityNotify:
        [[client frame] set_obscured: (e->xvisibility.state != VisibilityUnobscured)];
        break;
    case ButtonPress:
    case ButtonRelease:
        /* Wheel buttons don't draw because they are an instant click, so it
           is a waste of resources to go drawing it. */
        if (!(e->xbutton.button == 4 || e->xbutton.button == 5)) {
            con = frame_context(client, e->xbutton.window);
            con = [[AZMouseHandler defaultHandler] frameContext: con withButton: e->xbutton.button];
            switch (con) {
            case OB_FRAME_CONTEXT_MAXIMIZE:
                [[client frame] set_max_press: (e->type == ButtonPress)];
		[[client frame] render];
                break;
            case OB_FRAME_CONTEXT_CLOSE:
                [[client frame] set_close_press: (e->type == ButtonPress)];
		[[client frame] render];
                break;
            case OB_FRAME_CONTEXT_ICONIFY:
                [[client frame] set_iconify_press: (e->type == ButtonPress)];
		[[client frame] render];
                break;
            case OB_FRAME_CONTEXT_ALLDESKTOPS:
                [[client frame] set_desk_press: (e->type == ButtonPress)];
		[[client frame] render];
                break; 
            case OB_FRAME_CONTEXT_SHADE:
                [[client frame] set_shade_press: (e->type == ButtonPress)];
		[[client frame] render];
                break;
            default:
                /* nothing changes with clicks for any other contexts */
                break;
            }
        }
        break;
    case FocusIn:
	{
#ifdef DEBUG_FOCUS
        AZDebug("FocusIn on client for %lx (client %lx) mode %d detail %d\n",
                 e->xfocus.window, client->window,
                 e->xfocus.mode, e->xfocus.detail);
#endif
	AZFocusManager *fManager = [AZFocusManager defaultManager];
        if (client != [fManager focus_client]) {
	    [fManager setClient: client];
	    [[client frame] adjustFocusWithHilite: YES];
	    [client calcLayer];
        }
	}
        break;
    case FocusOut:
#ifdef DEBUG_FOCUS
        AZDebug("FocusOut on client for %lx (client %lx) mode %d detail %d\n",
                 e->xfocus.window, client->window,
                 e->xfocus.mode, e->xfocus.detail);
#endif
	{
  	  AZFocusManager *fManager = [AZFocusManager defaultManager];
	  [fManager set_focus_hilite: nil];
	  [[client frame] adjustFocusWithHilite: NO];
	  [client calcLayer];
	}
        break;
    case LeaveNotify:
        con = frame_context(client, e->xcrossing.window);
        switch (con) {
        case OB_FRAME_CONTEXT_MAXIMIZE:
            [[client frame] set_max_hover: NO];
	    [[client frame] adjustState];
            break;
        case OB_FRAME_CONTEXT_ALLDESKTOPS:
            [[client frame] set_desk_hover: NO];
	    [[client frame] adjustState];
            break;
        case OB_FRAME_CONTEXT_SHADE:
            [[client frame] set_shade_hover: NO];
	    [[client frame] adjustState];
            break;
        case OB_FRAME_CONTEXT_ICONIFY:
            [[client frame] set_iconify_hover: NO];
	    [[client frame] adjustState];
            break;
        case OB_FRAME_CONTEXT_CLOSE:
            [[client frame] set_close_hover: NO];
	    [[client frame] adjustState];
            break;
        case OB_FRAME_CONTEXT_FRAME:
            if (config_focus_follow && config_focus_delay)
	    {
	      [[AZMainLoop mainLoop] removeTimeout: self 
		               handler: @selector(focusDelayFunc:)
		                     data: client cancel: YES];
	    }
            break;
        default:
            break;
        }
        break;
    case EnterNotify:
    {
        BOOL nofocus = NO;

        if (ignore_enter_focus) {
            ignore_enter_focus--;
            nofocus = YES;
        }

        con = frame_context(client, e->xcrossing.window);
        switch (con) {
        case OB_FRAME_CONTEXT_MAXIMIZE:
            [[client frame] set_max_hover: YES];
	    [[client frame] adjustState];
            break;
        case OB_FRAME_CONTEXT_ALLDESKTOPS:
            [[client frame] set_desk_hover: YES];
	    [[client frame] adjustState];
            break;
        case OB_FRAME_CONTEXT_SHADE:
            [[client frame] set_shade_hover: YES];
	    [[client frame] adjustState];
            break;
        case OB_FRAME_CONTEXT_ICONIFY:
            [[client frame] set_iconify_hover: YES];
	    [[client frame] adjustState];
            break;
        case OB_FRAME_CONTEXT_CLOSE:
            [[client frame] set_close_hover: YES];
	    [[client frame] adjustState];
            break;
        case OB_FRAME_CONTEXT_FRAME:
            if (e->xcrossing.mode == NotifyGrab ||
                e->xcrossing.mode == NotifyUngrab)
            {
#ifdef DEBUG_FOCUS
                AZDebug("%sNotify mode %d detail %d on %lx IGNORED\n",
                         (e->type == EnterNotify ? "Enter" : "Leave"),
                         e->xcrossing.mode,
                         e->xcrossing.detail, client?client->window:0);
#endif
            } else {
#ifdef DEBUG_FOCUS
                AZDebug("%sNotify mode %d detail %d on %lx, "
                         "focusing window: %d\n",
                         (e->type == EnterNotify ? "Enter" : "Leave"),
                         e->xcrossing.mode,
                         e->xcrossing.detail, (client?client->window:0),
                         !nofocus);
#endif
                if (!nofocus && config_focus_follow)
		{
		    [self enterClient: client];
		}
            }
            break;
        default:
            break;
        }
        break;
    }
    case ConfigureRequest:
        /* compress these */
        while (XCheckTypedWindowEvent(ob_display, [client window],
                                      ConfigureRequest, &ce)) {
            ++i;
            /* XXX if this causes bad things.. we can compress config req's
               with the same mask. */
            e->xconfigurerequest.value_mask |=
                ce.xconfigurerequest.value_mask;
            if (ce.xconfigurerequest.value_mask & CWX)
                e->xconfigurerequest.x = ce.xconfigurerequest.x;
            if (ce.xconfigurerequest.value_mask & CWY)
                e->xconfigurerequest.y = ce.xconfigurerequest.y;
            if (ce.xconfigurerequest.value_mask & CWWidth)
                e->xconfigurerequest.width = ce.xconfigurerequest.width;
            if (ce.xconfigurerequest.value_mask & CWHeight)
                e->xconfigurerequest.height = ce.xconfigurerequest.height;
            if (ce.xconfigurerequest.value_mask & CWBorderWidth)
                e->xconfigurerequest.border_width =
                    ce.xconfigurerequest.border_width;
            if (ce.xconfigurerequest.value_mask & CWStackMode)
                e->xconfigurerequest.detail = ce.xconfigurerequest.detail;
        }

        /* if we are iconic (or shaded (fvwm does this)) ignore the event */
        if ([client iconic] || [client shaded]) return;

        /* resize, then move, as specified in the EWMH section 7.7 */
        if (e->xconfigurerequest.value_mask & (CWWidth | CWHeight |
                                               CWX | CWY |
                                               CWBorderWidth)) {
            int x, y, w, h;
            ObCorner corner;

            if (e->xconfigurerequest.value_mask & CWBorderWidth)
                [client set_border_width: e->xconfigurerequest.border_width];

            x = (e->xconfigurerequest.value_mask & CWX) ?
                e->xconfigurerequest.x : [client area].x;
            y = (e->xconfigurerequest.value_mask & CWY) ?
                e->xconfigurerequest.y : [client area].y;
            w = (e->xconfigurerequest.value_mask & CWWidth) ?
                e->xconfigurerequest.width : [client area].width;
            h = (e->xconfigurerequest.value_mask & CWHeight) ?
                e->xconfigurerequest.height : [client area].height;

            {
                int newx = x;
                int newy = y;
                int fw = w +
                     [[client frame] size].left + [[client frame] size].right;
                int fh = h +
                     [[client frame] size].top + [[client frame] size].bottom;
                /* make this rude for size-only changes but not for position
                   changes.. */
                BOOL moving = ((e->xconfigurerequest.value_mask & CWX) ||
                               (e->xconfigurerequest.value_mask & CWY));

		[client findOnScreenAtX: &newx y: &newy
			width: fw height: fh rude: !moving];

                if (e->xconfigurerequest.value_mask & CWX)
                    x = newx;
                if (e->xconfigurerequest.value_mask & CWY)
                    y = newy;
            }

            switch ([client gravity]) {
            case NorthEastGravity:
            case EastGravity:
                corner = OB_CORNER_TOPRIGHT;
                break;
            case SouthWestGravity:
            case SouthGravity:
                corner = OB_CORNER_BOTTOMLEFT;
                break;
            case SouthEastGravity:
                corner = OB_CORNER_BOTTOMRIGHT;
                break;
            default:     /* NorthWest, Static, etc */
                corner = OB_CORNER_TOPLEFT;
            }

	    [client configureToCorner: corner
		    x: x y: y width: w height: h
		    user: NO final: YES forceReply: YES];
        }

        if (e->xconfigurerequest.value_mask & CWStackMode) {
            switch (e->xconfigurerequest.detail) {
            case Below:
            case BottomIf:
		[client lower];
                break;

            case Above:
            case TopIf:
            default:
		[client raise];
                break;
            }
        }
        break;
    case UnmapNotify:
        if ([client ignore_unmaps]) {
            [client set_ignore_unmaps: [client ignore_unmaps]-1];
            break;
        }
        [[AZClientManager defaultManager] unmanageClient: client];
        break;
    case DestroyNotify:
        [[AZClientManager defaultManager] unmanageClient: client];
        break;
    case ReparentNotify:
        /* this is when the client is first taken captive in the frame */
        if (e->xreparent.parent == [[client frame] plate]) break;

        /*
          This event is quite rare and is usually handled in unmapHandler.
          However, if the window is unmapped when the reparent event occurs,
          the window manager never sees it because an unmap event is not sent
          to an already unmapped window.
        */

        /* we don't want the reparent event, put it back on the stack for the
           X server to deal with after we unmanage the window */
        XPutBackEvent(ob_display, e);
     
	[[AZClientManager defaultManager] unmanageClient: client];
        break;
    case MapRequest:
        AZDebug("MapRequest for 0x%lx\n", [client window]);
        if (![client iconic]) break; /* this normally doesn't happen, but if it
                                       does, we don't want it!
                                       it can happen now when the window is on
                                       another desktop, but we still don't
                                       want it! */
	[client activateHere: NO user: YES];
        break;
    case ClientMessage:
        /* validate cuz we query stuff off the client here */
	if (![client validate]) break;

        if (e->xclient.format != 32) return;

        msgtype = e->xclient.message_type;
        if (msgtype == prop_atoms.wm_change_state) {
            /* compress changes into a single change */
            while (XCheckTypedWindowEvent(ob_display, [client window],
                                          e->type, &ce)) {
                /* XXX: it would be nice to compress ALL messages of a
                   type, not just messages in a row without other
                   message types between. */
                if (ce.xclient.message_type != msgtype) {
                    XPutBackEvent(ob_display, &ce);
                    break;
                }
                e->xclient = ce.xclient;
            }
	    [client setWmState: e->xclient.data.l[0]];
        } else if (msgtype == prop_atoms.net_wm_desktop) {
            /* compress changes into a single change */
            while (XCheckTypedWindowEvent(ob_display, [client window],
                                          e->type, &ce)) {
                /* XXX: it would be nice to compress ALL messages of a
                   type, not just messages in a row without other
                   message types between. */
                if (ce.xclient.message_type != msgtype) {
                    XPutBackEvent(ob_display, &ce);
                    break;
                }
                e->xclient = ce.xclient;
            }
            if ((unsigned)e->xclient.data.l[0] < [[AZScreen defaultScreen] numberOfDesktops] ||
                (unsigned)e->xclient.data.l[0] == DESKTOP_ALL)
		[client setDesktop: (unsigned)e->xclient.data.l[0]
			             hide: NO];
        } else if (msgtype == prop_atoms.net_wm_state) {
            /* can't compress these */
            AZDebug("net_wm_state %s %ld %ld for 0x%lx\n",
                     (e->xclient.data.l[0] == 0 ? "Remove" :
                      e->xclient.data.l[0] == 1 ? "Add" :
                      e->xclient.data.l[0] == 2 ? "Toggle" : "INVALID"),
                     e->xclient.data.l[1], e->xclient.data.l[2],
                     [client window]);
	    [client setState: e->xclient.data.l[0]
		           data1: e->xclient.data.l[1]
			   data2: e->xclient.data.l[2]];
        } else if (msgtype == prop_atoms.net_close_window) {
            AZDebug("net_close_window for 0x%lx\n", [client window]);
	    [client close];
        } else if (msgtype == prop_atoms.net_active_window) {
            AZDebug("net_active_window for 0x%lx\n", [client window]);
            /* XXX make use of data.l[1] and [2] ! */
            [client activateHere: NO 
	                    user: (e->xclient.data.l[0] == 0 ||
                                   e->xclient.data.l[0] == 2)];
        } else if (msgtype == prop_atoms.net_wm_moveresize) {
            AZDebug("net_wm_moveresize for 0x%lx\n", [client window]);
            if ((Atom)e->xclient.data.l[2] ==
                prop_atoms.net_wm_moveresize_size_topleft ||
                (Atom)e->xclient.data.l[2] ==
                prop_atoms.net_wm_moveresize_size_top ||
                (Atom)e->xclient.data.l[2] ==
                prop_atoms.net_wm_moveresize_size_topright ||
                (Atom)e->xclient.data.l[2] ==
                prop_atoms.net_wm_moveresize_size_right ||
                (Atom)e->xclient.data.l[2] ==
                prop_atoms.net_wm_moveresize_size_right ||
                (Atom)e->xclient.data.l[2] ==
                prop_atoms.net_wm_moveresize_size_bottomright ||
                (Atom)e->xclient.data.l[2] ==
                prop_atoms.net_wm_moveresize_size_bottom ||
                (Atom)e->xclient.data.l[2] ==
                prop_atoms.net_wm_moveresize_size_bottomleft ||
                (Atom)e->xclient.data.l[2] ==
                prop_atoms.net_wm_moveresize_size_left ||
                (Atom)e->xclient.data.l[2] ==
                prop_atoms.net_wm_moveresize_move ||
                (Atom)e->xclient.data.l[2] ==
                prop_atoms.net_wm_moveresize_size_keyboard ||
                (Atom)e->xclient.data.l[2] ==
                prop_atoms.net_wm_moveresize_move_keyboard) {

		[[AZMoveResizeHandler defaultHandler]
			startWithClient: client
			x: e->xclient.data.l[0]
			y: e->xclient.data.l[1]
		       button: e->xclient.data.l[3]
                       corner: e->xclient.data.l[2]];
            }
        } else if (msgtype == prop_atoms.net_moveresize_window) {
            int oldg = [client gravity];
            int tmpg, x, y, w, h;

            if (e->xclient.data.l[0] & 0xff)
                tmpg = e->xclient.data.l[0] & 0xff;
            else
                tmpg = oldg;

            if (e->xclient.data.l[0] & 1 << 8)
                x = e->xclient.data.l[1];
            else
                x = [client area].x;
            if (e->xclient.data.l[0] & 1 << 9)
                y = e->xclient.data.l[2];
            else
                y = [client area].y;
            if (e->xclient.data.l[0] & 1 << 10)
                w = e->xclient.data.l[3];
            else
                w = [client area].width;
            if (e->xclient.data.l[0] & 1 << 11)
                h = e->xclient.data.l[4];
            else
                h = [client area].height;
            [client set_gravity: tmpg];

            {
                int newx = x;
                int newy = y;
                int fw = w +
                     [[client frame] size].left + [[client frame] size].right;
                int fh = h +
                     [[client frame] size].top + [[client frame] size].bottom;
		[client findOnScreenAtX: &newx y: &newy
			width: fw height: fh rude: [client normal]];

                if (e->xclient.data.l[0] & 1 << 8)
                    x = newx;
                if (e->xclient.data.l[0] & 1 << 9)
                    y = newy;
            }

	    [client configureToCorner: OB_CORNER_TOPLEFT
		    x: x y: y width: w height: h user: NO final: YES];

            [client set_gravity: oldg];
        }
        break;
    case PropertyNotify:
        /* validate cuz we query stuff off the client here */
	if (![client validate]) break;
  
        /* compress changes to a single property into a single change */
        while (XCheckTypedWindowEvent(ob_display, [client window],
                                      e->type, &ce)) {
            Atom a, b;

            /* XXX: it would be nice to compress ALL changes to a property,
               not just changes in a row without other props between. */

            a = ce.xproperty.atom;
            b = e->xproperty.atom;

            if (a == b)
                continue;
            if ((a == prop_atoms.net_wm_name ||
                 a == prop_atoms.wm_name ||
                 a == prop_atoms.net_wm_icon_name ||
                 a == prop_atoms.wm_icon_name)
                &&
                (b == prop_atoms.net_wm_name ||
                 b == prop_atoms.wm_name ||
                 b == prop_atoms.net_wm_icon_name ||
                 b == prop_atoms.wm_icon_name)) {
                continue;
            }
            if (a == prop_atoms.net_wm_icon &&
                b == prop_atoms.net_wm_icon)
                continue;

            XPutBackEvent(ob_display, &ce);
            break;
        }

        msgtype = e->xproperty.atom;
        if (msgtype == XA_WM_NORMAL_HINTS) {
	    [client updateNormalHints];
            /* normal hints can make a window non-resizable */
	    [client setupDecorAndFunctions];
        } else if (msgtype == XA_WM_HINTS) {
	    [client updateWmhints];
        } else if (msgtype == XA_WM_TRANSIENT_FOR) {
	    [client updateTransientFor];
	    [client getType];
            /* type may have changed, so update the layer */
	    [client calcLayer];
	    [client setupDecorAndFunctions];
        } else if (msgtype == prop_atoms.net_wm_name ||
                   msgtype == prop_atoms.wm_name ||
                   msgtype == prop_atoms.net_wm_icon_name ||
                   msgtype == prop_atoms.wm_icon_name) {
	    [client updateTitle];
        } else if (msgtype == prop_atoms.wm_class) {
	    [client updateClass];
        } else if (msgtype == prop_atoms.wm_protocols) {
	    [client updateProtocols];
	    [client setupDecorAndFunctions];
        } else if (msgtype == prop_atoms.net_wm_strut) {
	    [client updateStrut];
        } else if (msgtype == prop_atoms.net_wm_icon) {
	    [client updateIcons];
        } else if (msgtype == prop_atoms.sm_client_id) {
	    [client updateSmClientId];
        } else if (msgtype == prop_atoms.gnustep_wm_attr) {
	    [client updateGNUstepWMAttributes];
	}
    default:
        ;
#ifdef SHAPE
        if (extensions_shape && e->type == extensions_shape_event_basep) {
            [client set_shaped: ((XShapeEvent*)e)->shaped];
	    [[client frame] adjustShape];
        }
#endif
    }
}

- (AZMenuFrame *) findActiveMenu
{
    AZMenuFrame *ret = nil;
    NSArray *visibles = [AZMenuFrame visibleFrames];
    int i, count = [visibles count];

    for (i = 0; i < count; i++) {
	ret = [visibles objectAtIndex: i];
        if ([ret selected])
            break;
        ret = nil;
    }
    return ret;
}

- (AZMenuFrame *) findActiveOrLastMenu
{
    AZMenuFrame *ret = nil;
    NSArray *visibles = [AZMenuFrame visibleFrames];

    ret = [self findActiveMenu];
    if (!ret && [visibles count])
        ret = [visibles objectAtIndex: 0];
    return ret;
}

- (void) handleMenuEvent: (XEvent *) ev
{
    AZMenuFrame *f;
    AZMenuEntryFrame *e;

    switch (ev->type) {
    case ButtonRelease:
        if (menu_can_hide) {
            if ((e = AZMenuEntryFrameUnder(ev->xbutton.x_root,
                                            ev->xbutton.y_root)))
		[e execute: ev->xbutton.state];
            else
		AZMenuFrameHideAll();
        }
        break;
    case MotionNotify:
        if ((f = AZMenuFrameUnder(ev->xmotion.x_root, ev->xmotion.y_root))) {
	    [f moveOnScreen];
            if ((e = AZMenuEntryFrameUnder(ev->xmotion.x_root,
                                            ev->xmotion.y_root)))
		[f selectMenuEntryFrame: e];
        }
        {
            AZMenuFrame *a;

            a = [self findActiveMenu];
            if (a && a != f &&
                [[[a selected] entry] type] != OB_MENU_ENTRY_TYPE_SUBMENU)
            {
		[a selectMenuEntryFrame: nil];
            }
        }
        break;
    case KeyPress:
        if (ev->xkey.keycode == ob_keycode(OB_KEY_ESCAPE))
	    AZMenuFrameHideAll();
        else if (ev->xkey.keycode == ob_keycode(OB_KEY_RETURN)) {
            AZMenuFrame *f;
            if ((f = [self findActiveMenu]))
		[[f selected] execute: ev->xkey.state];
        } else if (ev->xkey.keycode == ob_keycode(OB_KEY_LEFT)) {
            AZMenuFrame *f;
            if ((f = [self findActiveOrLastMenu]) && [f parent])
		[f selectMenuEntryFrame: nil];
        } else if (ev->xkey.keycode == ob_keycode(OB_KEY_RIGHT)) {
            AZMenuFrame *f;
            if ((f = [self findActiveOrLastMenu]) && [f child])
		[[f child] selectNext];
        } else if (ev->xkey.keycode == ob_keycode(OB_KEY_UP)) {
            AZMenuFrame *f;
            if ((f = [self findActiveOrLastMenu]))
		[f selectPrevious];
        } else if (ev->xkey.keycode == ob_keycode(OB_KEY_DOWN)) {
            AZMenuFrame *f;
            if ((f = [self findActiveOrLastMenu]))
		[f selectNext];
        }
        break;
    }
}

- (BOOL) menuHideDelayFunc: (id) data
{
    menu_can_hide = YES;
    return NO; /* no repeat */
}

- (BOOL) focusDelayFunc: (id) data
{
    AZClient *c = data;

    if ([[AZFocusManager defaultManager] focus_client] != c) {
	[c focus];
        if (config_focus_raise)
	    [c raise];
    }
    return NO; /* no repeat */
}

- (void) clientDestroy: (NSNotification *) not
{
  AZClient *client = [not object];
  [[AZMainLoop mainLoop] removeTimeout: self handler: @selector(focusDelayFunc:)
	                 data: client cancel: YES];

  if (client == [[AZFocusManager defaultManager] focus_hilite])
    [[AZFocusManager defaultManager] set_focus_hilite: nil];
}

- (Window) getWindow: (XEvent *) e
{
    Window window;

    /* pick a window */
    switch (e->type) {
    case SelectionClear:
        window = RootWindow(ob_display, ob_screen);
        break;
    case MapRequest:
        window = e->xmap.window;
        break;
    case UnmapNotify:
        window = e->xunmap.window;
        break;
    case DestroyNotify:
        window = e->xdestroywindow.window;
        break;
    case ConfigureRequest:
        window = e->xconfigurerequest.window;
        break;
    case ConfigureNotify:
        window = e->xconfigure.window;
        break;
    default:
#ifdef XKB
        if (extensions_xkb && e->type == extensions_xkb_event_basep) {
            switch (((XkbAnyEvent*)e)->xkb_type) {
            case XkbBellNotify:
                window = ((XkbBellNotifyEvent*)e)->window;
            default:
                window = None;
            }
        } else
#endif
            window = e->xany.window;
    }
    return window;
}

- (void) setLastTime: (XEvent *) e
{
    Time t = 0;

    /* grab the lasttime and hack up the state */
    switch (e->type) {
    case ButtonPress:
    case ButtonRelease:
        t = e->xbutton.time;
        break;
    case KeyPress:
        t = e->xkey.time;
        break;
    case KeyRelease:
        t = e->xkey.time;
        break;
    case MotionNotify:
        t = e->xmotion.time;
        break;
    case PropertyNotify:
        t = e->xproperty.time;
        break;
    case EnterNotify:
    case LeaveNotify:
        t = e->xcrossing.time;
        break;
    default:
        /* if more event types are anticipated, get their timestamp
           explicitly */
        break;
    }

    if (t > event_lasttime) {
        event_lasttime = t;
        event_curtime = event_lasttime;
    } else if (t == 0) {
        event_curtime = event_lasttime;
    } else {
        event_curtime = t;
    }
}

#define STRIP_MODS(s) \
        s &= ~(LockMask | NumLockMask | ScrollLockMask), \
        /* kill off the Button1Mask etc, only want the modifiers */ \
        s &= (ControlMask | ShiftMask | Mod1Mask | \
              Mod2Mask | Mod3Mask | Mod4Mask | Mod5Mask) \

- (void) hackMods: (XEvent *) e
{
#ifdef XKB
    XkbStateRec xkb_state;
#endif
    KeyCode *kp;
    int i, k;

    switch (e->type) {
    case ButtonPress:
    case ButtonRelease:
        STRIP_MODS(e->xbutton.state);
        break;
    case KeyPress:
        STRIP_MODS(e->xkey.state);
        break;
    case KeyRelease:
        STRIP_MODS(e->xkey.state);
        /* remove from the state the mask of the modifier being released, if
           it is a modifier key being released (this is a little ugly..) */
#ifdef XKB
        if (XkbGetState(ob_display, XkbUseCoreKbd, &xkb_state) == Success) {
            e->xkey.state = xkb_state.compat_state;
            break;
        }
#endif
        kp = modmap->modifiermap;
        for (i = 0; i < mask_table_size; ++i) {
            for (k = 0; k < modmap->max_keypermod; ++k) {
                if (*kp == e->xkey.keycode) { /* found the keycode */
                    /* remove the mask for it */
                    e->xkey.state &= ~mask_table[i];
                    /* cause the first loop to break; */
                    i = mask_table_size;
                    break; /* get outta here! */
                }
                ++kp;
            }
        }
        break;
    case MotionNotify:
        STRIP_MODS(e->xmotion.state);
        /* compress events */
        {
            XEvent ce;
            while (XCheckTypedWindowEvent(ob_display, e->xmotion.window,
                                          e->type, &ce)) {
                e->xmotion.x_root = ce.xmotion.x_root;
                e->xmotion.y_root = ce.xmotion.y_root;
            }
        }
        break;
    }
}

- (BOOL) ignoreEvent: (XEvent *) e forClient: (AZClient *) client
{
    switch(e->type) {
    case EnterNotify:
    case LeaveNotify:
        if (e->xcrossing.detail == NotifyInferior)
            return YES;
        break;
    case FocusIn:
        /* NotifyAncestor is not ignored in FocusIn like it is in FocusOut
           because of RevertToPointerRoot. If the focus ends up reverting to
           pointer root on a workspace change, then the FocusIn event that we
           want will be of type NotifyAncestor. This situation does not occur
           for FocusOut, so it is safely ignored there.
        */
        if (INVALID_FOCUSIN(e) ||
            client == nil) {
#ifdef DEBUG_FOCUS
            AZDebug("FocusIn on %lx mode %d detail %d IGNORED\n",
                     e->xfocus.window, e->xfocus.mode, e->xfocus.detail);
#endif
            /* says a client was not found for the event (or a valid FocusIn
               event was not found.
            */
            e->xfocus.window = None;
            return YES;
        }

#ifdef DEBUG_FOCUS
        AZDebug("FocusIn on %lx mode %d detail %d\n", e->xfocus.window,
                 e->xfocus.mode, e->xfocus.detail);
#endif
        break;
    case FocusOut:
        if (INVALID_FOCUSOUT(e)) {
#ifdef DEBUG_FOCUS
        AZDebug("FocusOut on %lx mode %d detail %d IGNORED\n",
                 e->xfocus.window, e->xfocus.mode, e->xfocus.detail);
#endif
            return YES;
        }

#ifdef DEBUG_FOCUS
        AZDebug("FocusOut on %lx mode %d detail %d\n",
                 e->xfocus.window, e->xfocus.mode, e->xfocus.detail);
#endif
        {
            XEvent fe;
            BOOL fallback = YES;

            while (YES) {
                if (!XCheckTypedWindowEvent(ob_display, e->xfocus.window,
                                            FocusOut, &fe))
                    if (!XCheckTypedEvent(ob_display, FocusIn, &fe))
                        break;
                if (fe.type == FocusOut) {
#ifdef DEBUG_FOCUS
                    AZDebug("found pending FocusOut\n");
#endif
                    if (!INVALID_FOCUSOUT(&fe)) {
                        /* if there is a VALID FocusOut still coming, don't
                           fallback focus yet, we'll deal with it then */
                        XPutBackEvent(ob_display, &fe);
                        fallback = NO;
                        break;
                    }
                } else {
#ifdef DEBUG_FOCUS
                    AZDebug("found pending FocusIn\n");
#endif
                    /* is the focused window getting a FocusOut/In back to
                       itself?
                    */
                    if (fe.xfocus.window == e->xfocus.window &&
                        ![self ignoreEvent: &fe forClient: client]) {
                        /*
                          if focus_client is not set, then we can't do
                          this. we need the FocusIn. This happens in the
                          case when the set_focus_client(NULL) in the
                          focus_fallback function fires and then
                          focus_fallback picks the currently focused
                          window (such as on a SendToDesktop-esque action.
                        */
                        if ([[AZFocusManager defaultManager] focus_client]) {
#ifdef DEBUG_FOCUS
                            AZDebug("focused window got an Out/In back to "
                                     "itself IGNORED both\n");
#endif
                            return YES;
                        } else {
			    [self processEvent: &fe data: NULL];
#ifdef DEBUG_FOCUS
                            AZDebug("focused window got an Out/In back to "
                                     "itself but focus_client was null "
                                     "IGNORED just the Out\n");
#endif
                            return YES;
                        }
                    }

                    {
                        ObEventData d;

                        /* once all the FocusOut's have been dealt with, if
                           there is a FocusIn still left and it is valid, then
                           use it */
			[self processEvent: &fe data: &d];
                        if (!d.ignored) {
#ifdef DEBUG_FOCUS
                            AZDebug("FocusIn was OK, so don't fallback\n");
#endif
                            fallback = NO;
                            break;
                        }
                    }
                }
            }
            if (fallback) {
#ifdef DEBUG_FOCUS
                AZDebug("no valid FocusIn and no FocusOut events found, "
                         "falling back\n");
#endif
		[[AZFocusManager defaultManager] fallback: OB_FOCUS_FALLBACK_NOFOCUS];
            }
        }
        break;
    }
    return NO;
}

@end

