// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   mouse.c for the Openbox window manager
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

#import "AZMouseHandler.h"
#import "AZEventHandler.h"
#import "AZDebug.h"
#import "AZClientManager.h"
#import "openbox.h"
#import "config.h"
#import "action.h"
#import "prop.h"
#import "grab.h"
#import "translate.h"

@interface AZMouseBinding: NSObject
{
    unsigned int state;
    unsigned int button;
    NSMutableArray *actions[OB_NUM_MOUSE_ACTIONS]; /* lists of Action pointers */
}
- (unsigned int) state;
- (unsigned int) button;
- (void) set_state: (unsigned int) state;
- (void) set_button: (unsigned int) button;
- (NSMutableArray **) actions;
@end

@implementation AZMouseBinding
- (unsigned int) state { return state; }
- (unsigned int) button { return button; }
- (void) set_state: (unsigned int) s { state = s; }
- (void) set_button: (unsigned int) b { button = b; }
- (NSMutableArray **) actions { return actions; }
@end

#define FRAME_CONTEXT(co, cl) ((cl && [cl type] != OB_CLIENT_TYPE_DESKTOP) ? \
                               co == OB_FRAME_CONTEXT_FRAME : NO)
#define CLIENT_CONTEXT(co, cl) ((cl && [cl type] == OB_CLIENT_TYPE_DESKTOP) ? \
                                co == OB_FRAME_CONTEXT_DESKTOP : \
                                co == OB_FRAME_CONTEXT_CLIENT)

static AZMouseHandler *sharedInstance = nil;

@interface AZMouseHandler (AZPrivate)
- (void) grabAllClients: (BOOL) grab;
- (BOOL) fireBinding: (ObMouseAction) a context: (ObFrameContext) context
             client: (AZClient *) c state: (unsigned int) state
	     button: (unsigned int) button x: (int) x y: (int) y;
@end

@implementation AZMouseHandler

+ (AZMouseHandler *) defaultHandler
{
  if (sharedInstance == nil)
    sharedInstance = [[AZMouseHandler alloc] init];
  return sharedInstance;
}

- (ObFrameContext) frameContext: (ObFrameContext) context 
                     withButton: (unsigned int) button
{
    ObFrameContext x = context;

    NSArray *array = bound_contexts[context];
    int i, count = [array count];
    for (i = 0; i < count; i++) {
        AZMouseBinding *b = [array objectAtIndex: i];
        if ([b button] == button)
            return context;
    }

    switch (context) {
    case OB_FRAME_CONTEXT_NONE:
    case OB_FRAME_CONTEXT_DESKTOP:
    case OB_FRAME_CONTEXT_CLIENT:
    case OB_FRAME_CONTEXT_TITLEBAR:
    case OB_FRAME_CONTEXT_HANDLE:
    case OB_FRAME_CONTEXT_FRAME:
    case OB_FRAME_CONTEXT_MOVE_RESIZE:
        break;
    case OB_FRAME_CONTEXT_BLCORNER:
    case OB_FRAME_CONTEXT_BRCORNER:
        x = OB_FRAME_CONTEXT_HANDLE;
        break;
    case OB_FRAME_CONTEXT_TLCORNER:
    case OB_FRAME_CONTEXT_TRCORNER:
    case OB_FRAME_CONTEXT_MAXIMIZE:
    case OB_FRAME_CONTEXT_ALLDESKTOPS:
    case OB_FRAME_CONTEXT_SHADE:
    case OB_FRAME_CONTEXT_ICONIFY:
    case OB_FRAME_CONTEXT_ICON:
    case OB_FRAME_CONTEXT_CLOSE:
        x = OB_FRAME_CONTEXT_TITLEBAR;
        break;
    case OB_FRAME_NUM_CONTEXTS:
	NSAssert(0, @"Should not reach here");
    }

    return x;
}

- (void) grab: (BOOL) grab forClient: (AZClient *) client
{
    int i;

    for (i = 0; i < OB_FRAME_NUM_CONTEXTS; ++i) {
	NSArray *array = bound_contexts[i];
        int j, jcount = [array count];
	for (j = 0; j < jcount; j++) {
            /* grab/ungrab the button */
            AZMouseBinding *b = [array objectAtIndex: j];
            Window win;
            int mode;
            unsigned int mask;

            if (FRAME_CONTEXT(i, client)) {
                win = [[client frame] window];
                mode = GrabModeAsync;
                mask = ButtonPressMask | ButtonMotionMask | ButtonReleaseMask;
            } else if (CLIENT_CONTEXT(i, client)) {
                win = [[client frame] plate];
                mode = GrabModeSync; /* this is handled in event */
                mask = ButtonPressMask; /* can't catch more than this with Sync
                                           mode the release event is
                                           manufactured in event() */
            } else continue;

            if (grab)
                grab_button_full([b button], [b state], win, mask, mode,
                                 OB_CURSOR_NONE);
            else
                ungrab_button([b button], [b state], win);
        }
    }
}

- (void) unbindAll
{
    int i;
    
    for(i = 0; i < OB_FRAME_NUM_CONTEXTS; ++i) {
	NSArray *array = bound_contexts[i];
	int k, kcount = [array count];
	for (k = 0; k < kcount; k++) {
            AZMouseBinding *b = [array objectAtIndex: k];
            int j;

            for (j = 0; j < OB_NUM_MOUSE_ACTIONS; ++j) {
		DESTROY([b actions][j]);
            }
	    DESTROY(b);
        }
	DESTROY(bound_contexts[i]);
    }
}

- (void) processEvent: (XEvent *) e forClient: (AZClient *) client
{
    static Time ltime;
    static unsigned int button = 0, state = 0, lbutton = 0;
    static Window lwindow = None;
    static int px, py;

    ObFrameContext context;
    BOOL click = NO;
    BOOL dclick = NO;

    switch (e->type) {
    case ButtonPress:
        context = frame_context(client, e->xany.window);
        context = [self frameContext: context withButton: e->xbutton.button];

        px = e->xbutton.x_root;
        py = e->xbutton.y_root;
        button = e->xbutton.button;
        state = e->xbutton.state;

	[self fireBinding: OB_MOUSE_ACTION_PRESS context: context
                     client: client state: e->xbutton.state
                     button: e->xbutton.button
                     x: e->xbutton.x_root y: e->xbutton.y_root];

        if (CLIENT_CONTEXT(context, client)) {
            /* Replay the event, so it goes to the client*/
            XAllowEvents(ob_display, ReplayPointer, [[AZEventHandler defaultHandler] eventLastTime]/*event_lasttime*/);
            /* Fall through to the release case! */
        } else
            break;

    case ButtonRelease:
        context = frame_context(client, e->xany.window);
        context = [self frameContext: context withButton: e->xbutton.button];

        if (e->xbutton.button == button) {
            /* clicks are only valid if its released over the window */
            int junk1, junk2;
            Window wjunk;
            unsigned int ujunk, b, w, h;
            /* this can cause errors to occur when the window closes */
	    AZXErrorSetIgnore(YES);
            junk1 = XGetGeometry(ob_display, e->xbutton.window,
                                 &wjunk, &junk1, &junk2, &w, &h, &b, &ujunk);
	    AZXErrorSetIgnore(NO);
            if (junk1) {
                if (e->xbutton.x >= (signed)-b &&
                    e->xbutton.y >= (signed)-b &&
                    e->xbutton.x < (signed)(w+b) &&
                    e->xbutton.y < (signed)(h+b)) {
                    click = YES;
                    /* double clicks happen if there were 2 in a row! */
                    if (lbutton == button &&
                        lwindow == e->xbutton.window &&
                        e->xbutton.time - config_mouse_dclicktime <=
                        ltime) {
                        dclick = YES;
                        lbutton = 0;
                    } else {
                        lbutton = button;
                        lwindow = e->xbutton.window;
                    }
                } else {
                    lbutton = 0;
                    lwindow = None;
                }
            }

            button = 0;
            state = 0;
            ltime = e->xbutton.time;
        }
	[self fireBinding: OB_MOUSE_ACTION_RELEASE context: context
                     client: client state: e->xbutton.state
                     button: e->xbutton.button
                     x: e->xbutton.x_root y: e->xbutton.y_root];
        if (click)
            [self fireBinding: OB_MOUSE_ACTION_CLICK context: context
                         client: client state: e->xbutton.state
                         button: e->xbutton.button
                         x: e->xbutton.x_root y: e->xbutton.y_root];
        if (dclick)
            [self fireBinding: OB_MOUSE_ACTION_DOUBLE_CLICK context: context
                         client: client state: e->xbutton.state
                         button: e->xbutton.button
                         x: e->xbutton.x_root y: e->xbutton.y_root];
        break;

    case MotionNotify:
        if (button) {
            context = frame_context(client, e->xany.window);
            context = [self frameContext: context withButton: button];

            if (ABS(e->xmotion.x_root - px) >=
                config_mouse_threshold ||
                ABS(e->xmotion.y_root - py) >=
                config_mouse_threshold) {

                /* You can't drag on buttons */
                if (context == OB_FRAME_CONTEXT_MAXIMIZE ||
                    context == OB_FRAME_CONTEXT_ALLDESKTOPS ||
                    context == OB_FRAME_CONTEXT_SHADE ||
                    context == OB_FRAME_CONTEXT_ICONIFY ||
                    context == OB_FRAME_CONTEXT_ICON ||
                    context == OB_FRAME_CONTEXT_CLOSE)
                    break;

                [self fireBinding: OB_MOUSE_ACTION_MOTION context: context
                             client: client state: state
			     button: button x: px y: py];
                button = 0;
                state = 0;
            }
        }
        break;

    default:
	NSAssert(0, @"Should not reach here");
    }
}

- (BOOL) bind: (const char *) buttonstr context: (const char *) contextstr
           mouseAction: (ObMouseAction) mact action: (AZAction *) action
{
    unsigned int state, button;
    ObFrameContext context;
    AZMouseBinding *b;

    if (!translate_button([NSString stringWithCString: buttonstr], &state, &button)) {
        g_warning("invalid button '%s'", buttonstr);
        return NO;
    }

    context = frame_context_from_string(contextstr);
    if (!context) {
        g_warning("invalid context '%s'", contextstr);
        return NO;
    }

    NSArray *array = bound_contexts[context];
    int i, count = [array count];
    for (i = 0; i < count; i++) {
	b = [array objectAtIndex: i];
        if ([b state] == state && [b button] == button) {
	    if ([b actions][mact] == nil) {
	      [b actions][mact] = [[NSMutableArray alloc] init];
	    }
            [[b actions][mact] addObject: action];
            return YES;
        }
    }

    /* when there are no modifiers in the binding, then the action cannot
       be interactive */
    if (!state && [action data].any.interactive) {
        [action data_pointer]->any.interactive = NO;
        [action data_pointer]->inter.final = YES;
    }

    /* add the binding */
    b = [[AZMouseBinding alloc] init];
    [b set_state: state];
    [b set_button: button];
    [b actions][mact] = [[NSMutableArray alloc] init];
    [[b actions][mact] addObject: action];
    if (bound_contexts[context] == nil) {
      bound_contexts[context] = [[NSMutableArray alloc] init];
    }
    [bound_contexts[context] addObject: b];
    /* Release in -unbindAll*/

    return YES;
}

- (void) startup: (BOOL) reconfig
{
    [self grabAllClients: YES];
}

- (void) shutdown: (BOOL) reconfig
{
    [self grabAllClients: NO];
    [self unbindAll];
}

@end

@implementation AZMouseHandler (AZPrivate)

- (void) grabAllClients: (BOOL) grab
{
  AZClientManager *cManager = [AZClientManager defaultManager];
  int i, count = [cManager count];
  for (i = 0; i < count; i++)
  {
    AZClient *data = [cManager clientAtIndex: i];
    [self grab: grab forClient: data];
  }
}

- (BOOL) fireBinding: (ObMouseAction) a context: (ObFrameContext) context
             client: (AZClient *) c state: (unsigned int) state
	     button: (unsigned int) button x: (int) x y: (int) y
{
    AZMouseBinding *b;
    NSArray *array = bound_contexts[context];
    int i, count = [array count];
    BOOL found = NO;

    for (i = 0; i < count; i++) {
        b = [array objectAtIndex: i];
        if ([b state] == state && [b button] == button) {
	    found = YES;
            break;
	}
    }
    /* if not bound, then nothing to do! */
    if (found == NO) return NO;

    action_run_mouse([b actions][a], c, context, state, button, x, y);
    return YES;
}

@end
