// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   keytree.h for the Openbox window manager
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

#import <Foundation/Foundation.h>
#import "action.h"

#import <glib.h>

@interface AZKeyBindingTree: NSObject
{
    unsigned int state;
    unsigned int key;
    NSMutableArray *actions; /* list of Action pointers */

    /* the next binding in the tree at the same level */
    AZKeyBindingTree *next_sibling; 
    /* the first child of this binding (next binding in a chained sequence).*/
    AZKeyBindingTree *first_child;
}
- (unsigned int) state;
- (unsigned int) key;
- (NSArray *) actions;
- (AZKeyBindingTree *) next_sibling;
- (AZKeyBindingTree *) first_child;
- (void) set_state: (unsigned int) state;
- (void) set_key: (unsigned int) key;
- (void) set_next_sibling: (AZKeyBindingTree *) next_sibling;
- (void) set_first_child: (AZKeyBindingTree *) first_child;
- (void) addAction: (AZAction *) action;

@end

void tree_destroy(AZKeyBindingTree *tree);
AZKeyBindingTree *tree_build(GList *keylist);
void tree_assimilate(AZKeyBindingTree *node);
AZKeyBindingTree *tree_find(AZKeyBindingTree *search, BOOL *conflict);

