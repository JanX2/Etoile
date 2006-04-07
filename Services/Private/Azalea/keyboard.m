/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   keyboard.c for the Openbox window manager
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

#import "AZMainLoop.h"
#import "AZScreen.h"

#import "AZClientManager.h"
#include "openbox.h"
#include "grab.h"
#include "action.h"
#include "prop.h"
#include "config.h"
#include "keytree.h"
#include "keyboard.h"
#include "translate.h"

#include <glib.h>

KeyBindingTree *keyboard_firstnode;

typedef struct {
    unsigned int state;
    AZClient *client;
    GSList *actions;
    ObFrameContext context;
} ObInteractiveState;

static GSList *interactive_states;

static KeyBindingTree *curpos;

static void grab_for_window(Window win, BOOL grab)
{
    KeyBindingTree *p;

    ungrab_all_keys(win);

    if (grab) {
        p = curpos ? curpos->first_child : keyboard_firstnode;
        while (p) {
            grab_key(p->key, p->state, win, GrabModeAsync);
            p = p->next_sibling;
        }
        if (curpos)
            grab_key(config_keyboard_reset_keycode,
                     config_keyboard_reset_state,
                     win, GrabModeAsync);
    }
}

void keyboard_grab_for_client(AZClient *c, BOOL grab)
{
    grab_for_window([c window], grab);
}

static void grab_keys(BOOL grab)
{
    grab_for_window([[AZScreen defaultScreen] supportXWindow], grab);
    AZClientManager *cManager = [AZClientManager defaultManager];
    int i, count = [cManager count];
    for (i = 0; i < count; i++)
    {
      AZClient *data = [cManager clientAtIndex: i];
      grab_for_window([data window], grab);
    }
}

static gboolean chain_timeout(gpointer data)
{
    keyboard_reset_chains();

    return NO; /* don't repeat */
}

void keyboard_reset_chains()
{
    [[AZMainLoop mainLoop] removeTimeoutHandler: chain_timeout];

    if (curpos) {
        grab_keys(NO);
        curpos = NULL;
        grab_keys(YES);
    }
}

void keyboard_unbind_all()
{
    tree_destroy(keyboard_firstnode);
    keyboard_firstnode = NULL;
    grab_keys(NO);
    curpos = NULL;
}

BOOL keyboard_bind(GList *keylist, ObAction *action)
{
    KeyBindingTree *tree, *t;
    BOOL conflict;
    BOOL mods = YES;

    g_assert(keylist != NULL);
    g_assert(action != NULL);

    if (!(tree = tree_build(keylist)))
        return NO;

    if ((t = tree_find(tree, &conflict)) != NULL) {
        /* already bound to something, use the existing tree */
        tree_destroy(tree);
        tree = NULL;
    } else
        t = tree;

    if (conflict) {
        g_warning("conflict with binding");
        tree_destroy(tree);
        return NO;
    }

    /* find if every key in this chain has modifiers, and also find the
       bottom node of the tree */
    while (t->first_child) {
        if (!t->state)
            mods = NO;
        t = t->first_child;
    }

    /* when there are no modifiers in the binding, then the action cannot
       be interactive */
    if (!mods && action->data.any.interactive) {
        action->data.any.interactive = NO;
        action->data.inter.final = YES;
    }

    /* set the action */
    t->actions = g_slist_append(t->actions, action);
    /* assimilate this built tree into the main tree. assimilation
       destroys/uses the tree */
    if (tree) tree_assimilate(tree);

    return YES;
}

BOOL keyboard_interactive_grab(unsigned int state, AZClient *client,
                                   ObAction *action)
{
    ObInteractiveState *s;

    g_assert(action->data.any.interactive);

    if (!interactive_states) {
        if (!grab_keyboard(YES))
            return NO;
        if (!grab_pointer(YES, OB_CURSOR_NONE)) {
            grab_keyboard(NO);
            return NO;
        }
    }

    s = g_new(ObInteractiveState, 1);

    s->state = state;
    s->client = client;
    s->actions = g_slist_append(NULL, action);

    interactive_states = g_slist_append(interactive_states, s);

    return YES;
}

void keyboard_interactive_end(ObInteractiveState *s,
                              unsigned int state, BOOL cancel)
{
    action_run_interactive(s->actions, s->client, state, cancel, YES);

    g_slist_free(s->actions);
    g_free(s);

    interactive_states = g_slist_remove(interactive_states, s);

    if (!interactive_states) {
        grab_keyboard(NO);
        grab_pointer(NO, OB_CURSOR_NONE);
        keyboard_reset_chains();
    }
}

void keyboard_interactive_end_client(AZClient *client, gpointer data)
{
    GSList *it, *next;

    for (it = interactive_states; it; it = next) {
        ObInteractiveState *s = it->data;

        next = g_slist_next(it);

        if (s->client == client)
            s->client = nil;
    }
}

BOOL keyboard_process_interactive_grab(const XEvent *e, AZClient **client)
{
    GSList *it, *next;
    BOOL handled = NO;
    BOOL done = NO;
    BOOL cancel = NO;

    for (it = interactive_states; it; it = next) {
        ObInteractiveState *s = it->data;

        next = g_slist_next(it);
        
        if ((e->type == KeyRelease && 
             !(s->state & e->xkey.state)))
            done = YES;
        else if (e->type == KeyPress) {
            /*if (e->xkey.keycode == ob_keycode(OB_KEY_RETURN))
                done = YES;
            else */if (e->xkey.keycode == ob_keycode(OB_KEY_ESCAPE))
                cancel = done = YES;
        }
        if (done) {
            keyboard_interactive_end(s, e->xkey.state, cancel);

            handled = YES;
        } else
            *client = s->client;
    }

    return handled;
}

void keyboard_event(AZClient *client, const XEvent *e)
{
    KeyBindingTree *p;

    g_assert(e->type == KeyPress);

    if (e->xkey.keycode == config_keyboard_reset_keycode &&
        e->xkey.state == config_keyboard_reset_state)
    {
        keyboard_reset_chains();
        return;
    }

    if (curpos == NULL)
        p = keyboard_firstnode;
    else
        p = curpos->first_child;
    while (p) {
        if (p->key == e->xkey.keycode &&
            p->state == e->xkey.state)
        {
            if (p->first_child != NULL) { /* part of a chain */
		AZMainLoop *mainLoop = [AZMainLoop mainLoop];
		[mainLoop removeTimeoutHandler: chain_timeout];
                /* 5 second timeout for chains */
		[mainLoop addTimeoutHandler: chain_timeout
			     microseconds: 5 * G_USEC_PER_SEC
			     data: NULL
			     notify: NULL];
                grab_keys(NO);
                curpos = p;
                grab_keys(YES);
            } else {

                keyboard_reset_chains();

                action_run_key(p->actions, client, e->xkey.state,
                               e->xkey.x_root, e->xkey.y_root);
            }
            break;
        }
        p = p->next_sibling;
    }
}

void keyboard_startup(BOOL reconfig)
{
    grab_keys(YES);

    if (!reconfig)
	[[AZClientManager defaultManager] addDestructor: keyboard_interactive_end_client data: NULL];
}

void keyboard_shutdown(BOOL reconfig)
{
    GSList *it;

    if (!reconfig)
	[[AZClientManager defaultManager] removeDestructor: keyboard_interactive_end_client];

    for (it = interactive_states; it; it = g_slist_next(it))
        g_free(it->data);
    g_slist_free(interactive_states);
    interactive_states = NULL;

    [[AZMainLoop mainLoop] removeTimeoutHandler: chain_timeout];

    keyboard_unbind_all();
}

