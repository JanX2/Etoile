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

/* The time for the current event being processed */
Time event_curtime = CurrentTime;

BOOL event_time_after(Time t1, Time t2)
{
    if ((t1 == CurrentTime) || (t2 == CurrentTime))
	NSLog(@"Internal Error: t1 or t2 should not be CurrentTime");
    /*
      Timestamp values wrap around (after about 49.7 days). The server, given
      its current time is represented by timestamp T, always interprets
      timestamps from clients by treating half of the timestamp space as being
      later in time than T.
      - http://tronche.com/gui/x/xlib/input/pointer-grabbing.html
    */

    /* TIME_HALF is half of the number space of a Time type variable */
#define TIME_HALF (Time)(1 << (sizeof(Time)*8-1))

    if (t2 >= TIME_HALF)
        /* t2 is in the second half so t1 might wrap around and be smaller than
           t2 */
        return t1 >= t2 || t1 < (t2 + TIME_HALF);
    else
        /* t2 is in the first half so t1 has to come after it */
        return t1 >= t2 && t1 < (t2 + TIME_HALF);
}

static Bool look_for_focusin(Display *d, XEvent *e, XPointer arg);

static AZEventHandler *sharedInstance;

@interface AZEventHandler (AZPrivate)
- (void) handleRootEvent: (XEvent *) e;
- (void) handleMenuEvent: (XEvent *) e;
- (void) handleClient: (AZClient *) c event: (XEvent *) e;
- (void) handleGroup: (AZGroup *) g event: (XEvent *) e;

- (AZMenuFrame *) findActiveMenu;
- (AZMenuFrame *) findActiveOrLastMenu;
- (Window) getWindow: (XEvent *) e;
- (void) hackMods: (XEvent *) e;
- (BOOL) wantedFocusEvent: (XEvent *) e;
- (BOOL) ignoreEvent: (XEvent *) e forClient: (AZClient *) client;

/* callback */
- (void) processEvent: (XEvent *) e data: (void *) data;
#if 0 // Not used in OpenBox3
- (void) clientDestroy: (NSNotification *) not;
#endif

- (void) menuTimerAction: (id) sender;
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

#if 0 // Not used in OpenBox3
    [[NSNotificationCenter defaultCenter] addObserver: self
	    selector: @selector(clientDestroy:)
	    name: AZClientDestroyNotification
	    object: nil];
#endif
}

- (void) shutdown: (BOOL) reconfig
{
    if (reconfig) return;

#ifdef USE_SM
    IceRemoveConnectionWatch(ice_watch, NULL);
#endif

#if 0 // Not used in OpenBox3
    [[NSNotificationCenter defaultCenter] removeObserver: self];
#endif

    XFreeModifiermap(modmap);
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

- (void) setCurrentTime: (XEvent *) e
{
    Time t = CurrentTime;

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

    event_curtime = t;
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

    [self setCurrentTime: e];
    [self hackMods: e];
    if ([self ignoreEvent: e forClient: client]) {
        if (ed)
            ed->ignored = YES;
        return;
    } else if (ed)
            ed->ignored = NO;

    /* deal with it in the kernel */
    AZFocusManager *fManager = [AZFocusManager defaultManager];
    if (e->type == FocusIn) {
        if (client && client != [fManager focus_client]) {
	    [[client frame] adjustFocusWithHilite: YES];
	    [fManager setClient: client];
	    [client calcLayer];
        }
    } else if (e->type == FocusOut) {
        BOOL nomove = NO;
        XEvent ce;

        /* Look for the followup FocusIn */
        if (!XCheckIfEvent(ob_display, &ce, look_for_focusin, NULL)) {
            /* There is no FocusIn, this means focus went to a window that
               is not being managed, or a window on another screen. */
            /* nothing is focused */
	    [fManager setClient: nil];
        } else if (ce.xany.window == e->xany.window) {
            /* If focus didn't actually move anywhere, there is nothing to do*/
            nomove = YES;
        } else if (ce.xfocus.detail == NotifyPointerRoot ||
                   ce.xfocus.detail == NotifyDetailNone ||
                   ce.xfocus.detail == NotifyInferior) {
            /* Focus has been reverted to the root window or nothing
               FocusOut events come after UnmapNotify, so we don't need to
               worry about focusing an invalid window
             */
	    [fManager fallback: YES];
        } else {
            /* Focus did move, so process the FocusIn event */
            ObEventData ed = { .ignored = NO };
	    [self processEvent: &ce data: &ed];
            if (ed.ignored) {
                /* The FocusIn was ignored, this means it was on a window
                   that isn't a client. */
                [fManager fallback: YES];
            }
        }

        if (client && !nomove) {
	    [[client frame] adjustFocusWithHilite: NO];
            /* focus_set_client has already been called for sure */
	    [client calcLayer];
        }
    } else if (group) {
        [self handleGroup: group event:  e];
    } else if (client) {
        [self handleClient: client event:  e];
    } else if (window == RootWindow(ob_display, ob_screen)) {
        [self handleRootEvent: e];
    } else if (e->type == MapRequest) {
	[[AZClientManager defaultManager] manageWindow: window];
    } else if (e->type == ConfigureRequest) {
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
		{
            [self handleMenuEvent: e];
		}
        else 
		{
			AZKeyboardHandler *kHandler = [AZKeyboardHandler defaultHandler];
			if (![kHandler processInteractiveGrab: e forClient: &client]) 
			{
				AZMoveResizeHandler *mrHandler = [AZMoveResizeHandler defaultHandler];
			if ([mrHandler moveresize_in_progress]) 
			{
				[mrHandler event: e];

				/* make further actions work on the client being 
				   moved/resized */
				client = [mrHandler moveresize_client];
			}

			menu_can_hide = NO;
			ASSIGN(menuTimer, [NSTimer scheduledTimerWithTimeInterval: config_menu_hide_delay
			                           target: self
			                           selector: @selector(menuTimerAction:)
			                           userInfo: nil
			                           repeats: NO]);
				

                if (e->type == ButtonPress || e->type == ButtonRelease ||
                    e->type == MotionNotify) {
                    [[AZMouseHandler defaultHandler] processEvent: e forClient: client];
		} else if (e->type == KeyPress) {
		    AZFocusManager *fManager = [AZFocusManager defaultManager];
		    AZClient *focus_cycle_target = [fManager focus_cycle_target];
		    [kHandler processEvent: e
			    forClient: (focus_cycle_target ? focus_cycle_target: client)];
		}
            }
        }
    }
    /* if something happens and it's not from an XEvent, then we don't know
       the time */
    event_curtime = CurrentTime;
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
	        event_curtime = e->xclient.data.l[1];
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
//    AZFocusManager *fManager = [AZFocusManager defaultManager];
     
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
#if 0 // Removed in OpenBox3
    case FocusIn:
        if (client != [fManager focus_client]) {
	    [fManager setClient: client];
	    [[client frame] adjustFocusWithHilite: YES];
	    [client calcLayer];
        }
        break;
    case FocusOut:
        /* Look for the followup FocusIn */
        if (!XCheckIfEvent(ob_display, &ce, look_for_focusin, NULL)) {
            /* There is no FocusIn, this means focus went to a window that
               is not being managed, or a window on another screen. */
            //ob_debug("Focus went to a black hole !\n");
        } else if (ce.xany.window == e->xany.window) {
            /* If focus didn't actually move anywhere, there is nothing to do*/
            break;
        } else if (ce.xfocus.detail == NotifyPointerRoot ||
                 ce.xfocus.detail == NotifyDetailNone) {
            //ob_debug("Focus went to root\n");
            /* Focus has been reverted to the root window or nothing, so fall
               back to something other than the window which just had it. */
            [fManager fallback: NO];
        } else if (ce.xfocus.detail == NotifyInferior) {
            //ob_debug("Focus went to parent\n");
            /* Focus has been reverted to parent, which is our frame window,
               or the root window, so fall back to something other than the
               window which had it. */
            [fManager fallback: NO];
        } else {
            /* Focus did move, so process the FocusIn event */
            ObEventData ed;
	    ed.ignored = NO; 
	    [self processEvent: &ce data: &ed];
            if (ed.ignored) {
                /* The FocusIn was ignored, this means it was on a window
                   that isn't a client. */
                /* ob_debug("Focus went to an unmanaged window 0x%x !\n",
                         ce.xfocus.window); */
                [fManager fallback: YES];
            }
        }
	{
          /* This client is no longer focused, so show that */
  	  AZFocusManager *fManager = [AZFocusManager defaultManager];
	  [fManager set_focus_hilite: nil];
	  [[client frame] adjustFocusWithHilite: NO];
	  [client calcLayer];
	}
        break;
#endif
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
            if ([[AZKeyboardHandler defaultHandler] interactivelyGrabbed])
                break;
	    /* Used by focus follow mouse */
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
            if ([[AZKeyboardHandler defaultHandler] interactivelyGrabbed])
                break;
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
	       /* Only reach here for focus follow mouse */
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
                /* Apps are so rude. And this is totally disconnected from
                   activation/focus. Bleh. */
		// GNUstep need this because it has NSWindowAbove, Below, Out
		[client lower];
                break;

            case Above:
            case TopIf:
            default:
                /* Apps are so rude. And this is totally disconnected from
                   activation/focus. Bleh. */
		// GNUstep need this because it has NSWindowAbove, Below, Out
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
            /* XXX make use of data.l[2] ! */
	    event_curtime = e->xclient.data.l[1];
            [client activateHere: NO 
	                    user: (e->xclient.data.l[0] == 0 ||
                                   e->xclient.data.l[0] == 2)];
        } else if (msgtype == prop_atoms.net_wm_moveresize) {
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
            else if ((Atom)e->xclient.data.l[2] ==
                     prop_atoms.net_wm_moveresize_cancel)
	    {
		[[AZMoveResizeHandler defaultHandler] end: YES];
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
        } else if (msgtype == prop_atoms.net_wm_user_time) {
            [client updateUserTime];
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
		[e execute: ev->xbutton.state time: ev->xbutton.time];
            else
		AZMenuFrameHideAll();
        }
        break;
    case MotionNotify:
        if ((f = AZMenuFrameUnder(ev->xmotion.x_root, ev->xmotion.y_root))) 
	{
            if ((e = AZMenuEntryFrameUnder(ev->xmotion.x_root,
                                            ev->xmotion.y_root)))
	    {
		/* XXX menu_frame_entry_move_on_screen(f); */
		[f selectMenuEntryFrame: e];
	    }
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
		[[f selected] execute: ev->xkey.state time: ev->xkey.time];
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

- (void) menuTimerAction: (id) sender
{
	menu_can_hide = YES;
}

#if 0 // Not used in OpenBox3
- (void) clientDestroy: (NSNotification *) not
{
  AZClient *client = [not object];

  if (client == [[AZFocusManager defaultManager] focus_hilite])
    [[AZFocusManager defaultManager] set_focus_hilite: nil];
}
#endif

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

- (BOOL) wantedFocusEvent: (XEvent *) e
{
    int mode = e->xfocus.mode;
    int detail = e->xfocus.detail;
    Window win = e->xany.window;

    if (e->type == FocusIn) {

        /* These are ones we never want.. */

        /* This means focus was given by a keyboard/mouse grab. */
        if (mode == NotifyGrab)
            return NO;
        /* This means focus was given back from a keyboard/mouse grab. */
        if (mode == NotifyUngrab)
            return NO;

        /* These are the ones we want.. */

        if (win == RootWindow(ob_display, ob_screen)) {
            /* This means focus reverted off of a client */
            if (detail == NotifyPointerRoot || detail == NotifyDetailNone ||
                detail == NotifyInferior)
                return YES;
            else
                return NO;
        }

        /* This means focus moved from the root window to a client */
        if (detail == NotifyVirtual)
            return YES;
        /* This means focus moved from one client to another */
        if (detail == NotifyNonlinearVirtual)
            return YES;

        /* Otherwise.. */
        return NO;
    } else {
	NSAssert(e->type == FocusOut, @"Not a FocusOut event");


        /* These are ones we never want.. */

        /* This means focus was taken by a keyboard/mouse grab. */
        if (mode == NotifyGrab)
            return NO;

        /* Focus left the root window revertedto state */
        if (win == RootWindow(ob_display, ob_screen))
            return NO;

        /* These are the ones we want.. */

        /* This means focus moved from a client to the root window */
        if (detail == NotifyVirtual)
            return YES;
        /* This means focus moved from one client to another */
        if (detail == NotifyNonlinearVirtual)
            return YES;
        /* This means focus had moved to our frame window and now moved off */
        if (detail == NotifyNonlinear)
            return YES;

        /* Otherwise.. */
        return NO;
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
        if (![self wantedFocusEvent: e])
            return YES;
	break;
    case FocusOut:
        if (![self wantedFocusEvent: e])
            return YES;
        break;
    }
    return NO;
}

@end

/* X protocal callback */
static Bool look_for_focusin(Display *d, XEvent *e, XPointer arg)
{
    return (e->type == FocusIn && 
            [[AZEventHandler defaultHandler] wantedFocusEvent: e]);
}
