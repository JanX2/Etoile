/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZKeyTree.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   keytree.c for the Openbox window manager
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

#import "AZKeyTree.h"
#import "AZKeyboardHandler.h"
#import "translate.h"

@implementation AZKeyBindingTree
- (unsigned int) state { return state; }
- (unsigned int) key { return key; }
- (NSArray *) actions { return actions; }
- (AZKeyBindingTree *) next_sibling { return next_sibling; }
- (AZKeyBindingTree *) first_child { return first_child; }
- (void) set_state: (unsigned int) s { state = s; }
- (void) set_key: (unsigned int) k { key = k; }
- (void) set_next_sibling: (AZKeyBindingTree *) n { ASSIGN(next_sibling, n); }
- (void) set_first_child: (AZKeyBindingTree *) f { ASSIGN(first_child, f); }
- (void) addAction: (AZAction *) action
{
  [actions addObject: action];
}

- (id) init
{
  self = [super init];
  actions = [[NSMutableArray alloc] init];
  return self;
}

- (void) dealloc
{
  DESTROY(next_sibling);
  DESTROY(first_child);
  DESTROY(actions);
  [super dealloc];
}

@end

void tree_destroy(AZKeyBindingTree *tree)
{
    /* This should propagate into children */
    DESTROY(tree);
}

AZKeyBindingTree *tree_build(NSArray *keylist)
{
    AZKeyBindingTree *ret = nil, *p;
    int i, count = [keylist count];

    if (count <= 0)
        return nil; /* nothing in the list.. */

    for (i = count-1; i > -1; i--) {
        p = ret;
	ret = [[AZKeyBindingTree alloc] init];
        [ret set_first_child: p];
	unsigned int _state, _key;
        if (!translate_key([keylist objectAtIndex: i], &_state, &_key)) {
            tree_destroy(ret);
            return nil;
        } else {
	  [ret set_state: _state];
	  [ret set_key: _key];
	}
    }
    return ret;
}

void tree_assimilate(AZKeyBindingTree *node)
{
    AZKeyBindingTree *a, *b, *tmp, *last;
    AZKeyboardHandler *kHandler = [AZKeyboardHandler defaultHandler];
    AZKeyBindingTree *keyboard_firstnode = [kHandler firstnode];

    if (keyboard_firstnode == nil) {
        /* there are no nodes at this level yet */
        keyboard_firstnode = node;
	[kHandler set_firstnode: node];
    } else {
        a = keyboard_firstnode;
        last = a;
        b = node;
        while (a) {
            last = a;
            if (!([a state] == [b state] && [a key] == [b key])) {
                a = [a next_sibling];
            } else {
                tmp = b;
                b = [b first_child];
		DESTROY(tmp);
                a = [a first_child];
            }
        }
        if (!([last state] == [b state] && [last key] == [b key]))
            [last set_next_sibling: b];
        else {
            [last set_first_child: [b first_child]];
	    DESTROY(b);
        }
    }
}

AZKeyBindingTree *tree_find(AZKeyBindingTree *search, BOOL *conflict)
{
    AZKeyBindingTree *a, *b;
    AZKeyboardHandler *kHandler = [AZKeyboardHandler defaultHandler];
    AZKeyBindingTree *keyboard_firstnode = [kHandler firstnode];

    *conflict = NO;

    a = keyboard_firstnode;
    b = search;
    while (a && b) {
        if (!([a state] == [b state] && [a key] == [b key])) {
            a = [a next_sibling];
        } else {
            if (([a first_child] == nil) == ([b first_child] == nil)) {
                if ([a first_child] == nil) {
                    /* found it! (return the actual node, not the search's) */
                    return a;
                }
            } else {
                *conflict = YES;
                return nil; /* the chain status' don't match (conflict!) */
            }
            b = [b first_child];
            a = [a first_child];
        }
    }
    return nil; /* it just isn't in here */
}
