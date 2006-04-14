// Modified by Yen-Ju
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
#import "openbox.h"
#import "grab.h"
#import "action.h"
#import "prop.h"
#import "config.h"
#import "AZKeyTree.h"
#import "AZKeyboardHandler.h"
#import "translate.h"

static AZKeyboardHandler *sharedInstance;

static gboolean chain_timeout(gpointer data)
{
    [[AZKeyboardHandler defaultHandler] resetChains];
    return NO; /* don't repeat */
}

@interface AZKeyboardHandler (AZPrivate)
- (void) grab: (BOOL) grab forWindow: (Window) win;
- (void) grabKeys: (BOOL) grab;
- (void) interactiveEnd: (ObInteractiveState *) s state: (unsigned int) state cancel: (BOOL) cancel;
- (void) clientDestroy: (NSNotification *) not;

@end

@implementation AZKeyboardHandler

- (void) grab: (BOOL) grab forClient: (AZClient *) client
{
    [self grab: grab forWindow: [client window]];
}

- (void) resetChains
{
    [[AZMainLoop mainLoop] removeTimeoutHandler: chain_timeout];

    if (curpos) {
        [self grabKeys: NO];
        curpos = NULL;
	[self grabKeys: YES];
    }
}

- (void) unbindAll
{
    tree_destroy(keyboard_firstnode);
    keyboard_firstnode = nil;
    [self grabKeys: NO];
    curpos = nil;
}

- (BOOL) bind: (GList *) keylist action: (AZAction *) action
{
    AZKeyBindingTree *tree, *t;
    BOOL conflict;
    BOOL mods = YES;

    g_assert(keylist != NULL);
    g_assert(action != nil);

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
    while ([t first_child]) {
        if (![t state])
            mods = NO;
        t = [t first_child];
    }

    /* when there are no modifiers in the binding, then the action cannot
       be interactive */
    if (!mods && [action data].any.interactive) {
        [action data_pointer]->any.interactive = NO;
        [action data_pointer]->inter.final = YES;
    }

    /* set the action */
    [t addAction: action];
    /* assimilate this built tree into the main tree. assimilation
       destroys/uses the tree */
    if (tree) tree_assimilate(tree);

    return YES;
}

- (BOOL) interactiveGrab: (unsigned int) state
                  client: (AZClient *) client
                  action: (AZAction *) action
{
    ObInteractiveState *s;

    g_assert([action data].any.interactive);

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

- (BOOL) processInteractiveGrab: (XEvent *) e
                      forClient: (AZClient **) client
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
	    [self interactiveEnd: s
		    state: e->xkey.state
		    cancel: cancel];

            handled = YES;
        } else
            *client = s->client;
    }

    return handled;
}

- (void) processEvent: (XEvent *) e forClient: (AZClient *) client
{
    AZKeyBindingTree *p;

    g_assert(e->type == KeyPress);

    if (e->xkey.keycode == config_keyboard_reset_keycode &&
        e->xkey.state == config_keyboard_reset_state)
    {
	[self resetChains];
        return;
    }

    if (curpos == NULL)
        p = keyboard_firstnode;
    else
        p = [curpos first_child];
    while (p) {
        if ([p key] == e->xkey.keycode &&
            [p state] == e->xkey.state)
        {
            if ([p first_child] != nil) { /* part of a chain */
		AZMainLoop *mainLoop = [AZMainLoop mainLoop];
		[mainLoop removeTimeoutHandler: chain_timeout];
                /* 5 second timeout for chains */
		[mainLoop addTimeoutHandler: chain_timeout
			     microseconds: 5 * G_USEC_PER_SEC
			     data: NULL
			     notify: NULL];
		[self grabKeys: NO];
                curpos = p;
		[self grabKeys: YES];
            } else {

		[self resetChains];

                action_run_key([p actions], client, e->xkey.state,
                               e->xkey.x_root, e->xkey.y_root);
            }
            break;
        }
        p = [p next_sibling];
    }
}

- (void) startup: (BOOL) reconfig
{
    [self grabKeys: YES];

    if (!reconfig) {
	[[NSNotificationCenter defaultCenter] addObserver: self
		selector: @selector(clientDestroy:)
		name: AZClientDestroyNotification
		object: nil];
    }
}

- (void) shutdown: (BOOL) reconfig
{
    GSList *it;

    if (!reconfig) {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
    }

    for (it = interactive_states; it; it = g_slist_next(it))
        g_free(it->data);
    g_slist_free(interactive_states);
    interactive_states = NULL;

    [[AZMainLoop mainLoop] removeTimeoutHandler: chain_timeout];

    [self unbindAll];
}

- (AZKeyBindingTree *) firstnode
{
  return keyboard_firstnode;
}

- (void) set_firstnode: (AZKeyBindingTree *) first
{
  keyboard_firstnode = first;
}

+ (AZKeyboardHandler *) defaultHandler
{
  if (sharedInstance == nil)
    sharedInstance = [[AZKeyboardHandler alloc] init];
  return sharedInstance;
}

@end

@implementation AZKeyboardHandler (AZPrivate)
- (void) grab: (BOOL) grab forWindow: (Window) win
{
    AZKeyBindingTree *p;

    ungrab_all_keys(win);

    if (grab) {
        p = curpos ? [curpos first_child] : keyboard_firstnode;
        while (p) {
            grab_key([p key], [p state], win, GrabModeAsync);
            p = [p next_sibling];
        }
        if (curpos)
            grab_key(config_keyboard_reset_keycode,
                     config_keyboard_reset_state,
                     win, GrabModeAsync);
    }
}

- (void) grabKeys: (BOOL) grab
{
    [self grab: grab forWindow: [[AZScreen defaultScreen] supportXWindow]];
    AZClientManager *cManager = [AZClientManager defaultManager];
    int i, count = [cManager count];
    for (i = 0; i < count; i++)
    {
      AZClient *data = [cManager clientAtIndex: i];
      [self grab: grab forWindow: [data window]];
    }
}

- (void) interactiveEnd: (ObInteractiveState *) s
                  state: (unsigned int) state
		  cancel: (BOOL) cancel
{
    action_run_interactive(s->actions, s->client, state, cancel, YES);

    g_slist_free(s->actions);
    g_free(s);

    interactive_states = g_slist_remove(interactive_states, s);

    if (!interactive_states) {
        grab_keyboard(NO);
        grab_pointer(NO, OB_CURSOR_NONE);
        [self resetChains];
    }
}

- (void) clientDestroy: (NSNotification *) not
{
    AZClient *client = [not object];
    GSList *it, *next;

    for (it = interactive_states; it; it = next) {
        ObInteractiveState *s = it->data;

        next = g_slist_next(it);

        if (s->client == client)
            s->client = nil;
    }
}

@end
