// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

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
#import "keyboard.h"
#import "translate.h"
#import <glib.h>

@implementation AZKeyBindingTree
- (unsigned int) state { return state; }
- (unsigned int) key { return key; }
- (GSList *) actions { return actions; }
- (AZKeyBindingTree *) next_sibling { return next_sibling; }
- (AZKeyBindingTree *) first_child { return first_child; }
- (void) set_state: (unsigned int) s { state = s; }
- (void) set_key: (unsigned int) k { key = k; }
- (void) set_actions: (GSList *) a { actions = a; }
- (void) set_next_sibling: (AZKeyBindingTree *) n { next_sibling = n; }
- (void) set_first_child: (AZKeyBindingTree *) f { first_child = f; }

@end

void tree_destroy(AZKeyBindingTree *tree)
{
    AZKeyBindingTree *c;

    while (tree) {
        tree_destroy([tree next_sibling]);
        c = [tree first_child];
        if (c == NULL) {
            GSList *sit;
            for (sit = [tree actions]; sit != NULL; sit = sit->next)
                action_unref(sit->data);
            g_slist_free([tree actions]);
        }
	DESTROY(tree);
        tree = c;
    }
}

AZKeyBindingTree *tree_build(GList *keylist)
{
    GList *it;
    AZKeyBindingTree *ret = NULL, *p;

    if (g_list_length(keylist) <= 0)
        return NULL; /* nothing in the list.. */

    for (it = g_list_last(keylist); it; it = g_list_previous(it)) {
        p = ret;
	ret = [[AZKeyBindingTree alloc] init];
        [ret set_first_child: p];
	unsigned int _state, _key;
        if (!translate_key(it->data, &_state, &_key)) {
            tree_destroy(ret);
            return NULL;
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

    if (keyboard_firstnode == nil) {
        /* there are no nodes at this level yet */
        keyboard_firstnode = node;
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
