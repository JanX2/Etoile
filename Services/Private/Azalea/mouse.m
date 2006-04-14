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

#import "AZEventHandler.h"
#import "AZDebug.h"
#import "AZClientManager.h"
#include "openbox.h"
#include "config.h"
#include "action.h"
#include "prop.h"
#include "grab.h"
#include "translate.h"
#include "mouse.h"
#include <glib.h>

typedef struct {
    unsigned int state;
    unsigned int button;
    GSList *actions[OB_NUM_MOUSE_ACTIONS]; /* lists of Action pointers */
} ObMouseBinding;

#define FRAME_CONTEXT(co, cl) ((cl && [cl type] != OB_CLIENT_TYPE_DESKTOP) ? \
                               co == OB_FRAME_CONTEXT_FRAME : NO)
#define CLIENT_CONTEXT(co, cl) ((cl && [cl type] == OB_CLIENT_TYPE_DESKTOP) ? \
                                co == OB_FRAME_CONTEXT_DESKTOP : \
                                co == OB_FRAME_CONTEXT_CLIENT)

/* Array of GSList*s of ObMouseBinding*s. */
static GSList *bound_contexts[OB_FRAME_NUM_CONTEXTS];

ObFrameContext mouse_button_frame_context(ObFrameContext context,
                                          unsigned int button)
{
    GSList *it;
    ObFrameContext x = context;

    for (it = bound_contexts[context]; it; it = g_slist_next(it)) {
        ObMouseBinding *b = it->data;

        if (b->button == button)
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
        g_assert_not_reached();
    }

    return x;
}

void mouse_grab_for_client(AZClient *client, BOOL grab)
{
    int i;
    GSList *it;

    for (i = 0; i < OB_FRAME_NUM_CONTEXTS; ++i)
        for (it = bound_contexts[i]; it; it = g_slist_next(it)) {
            /* grab/ungrab the button */
            ObMouseBinding *b = it->data;
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
                grab_button_full(b->button, b->state, win, mask, mode,
                                 OB_CURSOR_NONE);
            else
                ungrab_button(b->button, b->state, win);
        }
}

static void grab_all_clients(BOOL grab)
{
  AZClientManager *cManager = [AZClientManager defaultManager];
  int i, count = [cManager count];
  for (i = 0; i < count; i++)
  {
    AZClient *data = [cManager clientAtIndex: i];
    mouse_grab_for_client(data, grab);
  }
}

void mouse_unbind_all()
{
    int i;
    GSList *it;
    
    for(i = 0; i < OB_FRAME_NUM_CONTEXTS; ++i) {
        for (it = bound_contexts[i]; it; it = g_slist_next(it)) {
            ObMouseBinding *b = it->data;
            int j;

            for (j = 0; j < OB_NUM_MOUSE_ACTIONS; ++j) {
                GSList *it;

                for (it = b->actions[j]; it; it = g_slist_next(it))
                    action_unref(it->data);
                g_slist_free(b->actions[j]);
            }
            g_free(b);
        }
        g_slist_free(bound_contexts[i]);
        bound_contexts[i] = NULL;
    }
}

static BOOL fire_binding(ObMouseAction a, ObFrameContext context,
                             AZClient *c, unsigned int state,
                             unsigned int button, int x, int y)
{
    GSList *it;
    ObMouseBinding *b;

    for (it = bound_contexts[context]; it; it = g_slist_next(it)) {
        b = it->data;
        if (b->state == state && b->button == button)
            break;
    }
    /* if not bound, then nothing to do! */
    if (it == NULL) return NO;

    action_run_mouse(b->actions[a], c, context, state, button, x, y);
    return YES;
}

void mouse_event(AZClient *client, XEvent *e)
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
        context = mouse_button_frame_context(context, e->xbutton.button);

        px = e->xbutton.x_root;
        py = e->xbutton.y_root;
        button = e->xbutton.button;
        state = e->xbutton.state;

        fire_binding(OB_MOUSE_ACTION_PRESS, context,
                     client, e->xbutton.state,
                     e->xbutton.button,
                     e->xbutton.x_root, e->xbutton.y_root);

        if (CLIENT_CONTEXT(context, client)) {
            /* Replay the event, so it goes to the client*/
            XAllowEvents(ob_display, ReplayPointer, [[AZEventHandler defaultHandler] eventLastTime]/*event_lasttime*/);
            /* Fall through to the release case! */
        } else
            break;

    case ButtonRelease:
        context = frame_context(client, e->xany.window);
        context = mouse_button_frame_context(context, e->xbutton.button);

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
        fire_binding(OB_MOUSE_ACTION_RELEASE, context,
                     client, e->xbutton.state,
                     e->xbutton.button,
                     e->xbutton.x_root, e->xbutton.y_root);
        if (click)
            fire_binding(OB_MOUSE_ACTION_CLICK, context,
                         client, e->xbutton.state,
                         e->xbutton.button,
                         e->xbutton.x_root,
                         e->xbutton.y_root);
        if (dclick)
            fire_binding(OB_MOUSE_ACTION_DOUBLE_CLICK, context,
                         client, e->xbutton.state,
                         e->xbutton.button,
                         e->xbutton.x_root,
                         e->xbutton.y_root);
        break;

    case MotionNotify:
        if (button) {
            context = frame_context(client, e->xany.window);
            context = mouse_button_frame_context(context, button);

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

                fire_binding(OB_MOUSE_ACTION_MOTION, context,
                             client, state, button, px, py);
                button = 0;
                state = 0;
            }
        }
        break;

    default:
        g_assert_not_reached();
    }
}

BOOL mouse_bind(const gchar *buttonstr, const gchar *contextstr,
                    ObMouseAction mact, ObAction *action)
{
    unsigned int state, button;
    ObFrameContext context;
    ObMouseBinding *b;
    GSList *it;

    if (!translate_button(buttonstr, &state, &button)) {
        g_warning("invalid button '%s'", buttonstr);
        return NO;
    }

    context = frame_context_from_string(contextstr);
    if (!context) {
        g_warning("invalid context '%s'", contextstr);
        return NO;
    }

    for (it = bound_contexts[context]; it; it = g_slist_next(it)) {
        b = it->data;
        if (b->state == state && b->button == button) {
            b->actions[mact] = g_slist_append(b->actions[mact], action);
            return YES;
        }
    }

    /* when there are no modifiers in the binding, then the action cannot
       be interactive */
    if (!state && action->data.any.interactive) {
        action->data.any.interactive = NO;
        action->data.inter.final = YES;
    }

    /* add the binding */
    b = g_new0(ObMouseBinding, 1);
    b->state = state;
    b->button = button;
    b->actions[mact] = g_slist_append(NULL, action);
    bound_contexts[context] = g_slist_append(bound_contexts[context], b);

    return YES;
}

void mouse_startup(BOOL reconfig)
{
    grab_all_clients(YES);
}

void mouse_shutdown(BOOL reconfig)
{
    grab_all_clients(NO);
    mouse_unbind_all();
}
