/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZKeyboardHandler.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen
	 
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

@interface AZInteractiveState: NSObject
{
    unsigned int state;
    AZClient *client;
    NSArray *actions;
    ObFrameContext context;
}
- (unsigned int) state;
- (AZClient *) client;
- (NSArray *) actions;
- (ObFrameContext) context;
- (void) set_state: (unsigned int) state;
- (void) set_client:(AZClient *) client;
- (void) set_actions: (NSArray *) actions;
- (void) set_context: (ObFrameContext) context;
@end

@implementation AZInteractiveState
- (unsigned int) state { return state; }
- (AZClient *) client { return client; }
- (NSArray *) actions { return actions; }
- (ObFrameContext) context { return context; }
- (void) set_state: (unsigned int) s { state = s; }
- (void) set_client:(AZClient *) c { client = c; }
- (void) set_actions: (NSArray *) a { ASSIGN(actions, a); }
- (void) set_context: (ObFrameContext) c { context = c; }
- (void) dealloc
{
  DESTROY(actions);
  [super dealloc];
}
@end

static AZKeyboardHandler *sharedInstance;

@interface AZKeyboardHandler (AZPrivate)
- (void) grab: (BOOL) grab forWindow: (Window) win;
- (void) grabKeys: (BOOL) grab;
- (void) interactiveEnd: (AZInteractiveState *) s state: (unsigned int) state cancel: (BOOL) cancel;
- (void) clientDestroy: (NSNotification *) not;
/* callback */
- (BOOL) chainTimeout: (id) data;

@end

@implementation AZKeyboardHandler

- (void) grab: (BOOL) grab forClient: (AZClient *) client
{
    [self grab: grab forWindow: [client window]];
}

- (void) resetChains
{
    [[AZMainLoop mainLoop] removeTimeout: self 
	                         handler: @selector(chainTimeout:)];

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

- (BOOL) bind: (NSArray *) keylist action: (AZAction *) action
{
    AZKeyBindingTree *tree, *t;
    BOOL conflict;
    BOOL mods = YES;

    NSAssert(keylist != nil, @"keylist is nil");
    NSAssert(action != nil, @"action is NULL");

    if (!(tree = tree_build(keylist)))
        return NO;

    if ((t = tree_find(tree, &conflict)) != NULL) {
        /* already bound to something, use the existing tree */
        tree_destroy(tree);
        tree = nil;
    } else
        t = tree;

    if (conflict) {
	NSLog(@"Warning: conflict with binding");
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
    AZInteractiveState *s;

    NSAssert([action data].any.interactive, @"interactive is NULL");

    if ([interactive_states count] == 0) {
        if (!grab_keyboard(YES))
            return NO;
        if (!grab_pointer(YES, OB_CURSOR_NONE)) {
            grab_keyboard(NO);
            return NO;
        }
    }

    s = [[AZInteractiveState alloc] init];

    [s set_state: state];
    [s set_client: client];
    [s set_actions: [NSArray arrayWithObjects: action, nil]];

    [interactive_states addObject: s];
    DESTROY(s);

    return YES;
}

- (BOOL) processInteractiveGrab: (XEvent *) e
                      forClient: (AZClient **) client
{
    BOOL handled = NO;
    BOOL done = NO;
    BOOL cancel = NO;
    int i;

    for (i = 0; i < [interactive_states count]; i++) {
        AZInteractiveState *s = [interactive_states objectAtIndex: i];

        if ((e->type == KeyRelease && 
             !([s state] & e->xkey.state)))
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
	    i--; /* s is removed */
        } else
            *client = [s client];
    }

    return handled;
}

- (void) processEvent: (XEvent *) e forClient: (AZClient *) client
{
    AZKeyBindingTree *p;

    NSAssert(e->type == KeyPress, @"Event type is not KeyPress");

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
		[mainLoop removeTimeout: self 
			        handler: @selector(chainTimeout:)];
                /* 5 second timeout for chains */
		[mainLoop addTimeout: self 
			     handler: @selector(chainTimeout:)
			     microseconds: 5 * G_USEC_PER_SEC
			     data: nil notify: NULL];
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

    interactive_states = [[NSMutableArray alloc] init];
}

- (void) shutdown: (BOOL) reconfig
{
    if (!reconfig) {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
    }

    DESTROY(interactive_states);

    [[AZMainLoop mainLoop] removeTimeout: self 
	                         handler: @selector(chainTimeout:)];

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

- (void) interactiveEnd: (AZInteractiveState *) s
                  state: (unsigned int) state
		  cancel: (BOOL) cancel
{
    action_run_interactive([s actions], [s client], state, cancel, YES);
    [interactive_states removeObject: s];

    if ([interactive_states count] == 0) {
        grab_keyboard(NO);
        grab_pointer(NO, OB_CURSOR_NONE);
        [self resetChains];
    }
}

- (void) clientDestroy: (NSNotification *) not
{
    AZClient *client = [not object];
    int i, count = [interactive_states count];

    for (i = 0; i < count; i++) {
        AZInteractiveState *s = [interactive_states objectAtIndex: i];
        if ([s client] == client)
            [s set_client: nil];
    }
}

- (BOOL) chainTimeout: (id) data
{
  [[AZKeyboardHandler defaultHandler] resetChains];
  return NO; /* don't repeat */
}

@end
