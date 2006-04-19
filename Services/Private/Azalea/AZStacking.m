/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZStacking.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   stacking.c for the Openbox window manager
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

#import "AZStacking.h"
#import "AZScreen.h"
#import "AZDock.h"
#import "AZGroup.h"
#import "AZClient.h"
#import "openbox.h"
#import "prop.h"

static AZStacking *sharedInstance;

@interface AZStacking (AZPrivate)
- (void) doRestack: (NSArray *) wins before: (id <AZWindow>) before;
- (void) doRaise: (NSArray *) wins;
- (void) doLower: (NSArray *) wins;
- (NSArray *)pickWindowsFrom: (AZClient *) top to: (AZClient *) selected raise: (BOOL) raise;
- (NSArray *)pickGroupWindowsFrom: (AZClient *) top to: (AZClient *) selected raise: (BOOL) raise normal: (BOOL) normal;
@end

@implementation AZStacking

- (void) setList
{
    Window *windows = NULL;
    unsigned int i = 0;

    /* on shutdown, don't update the properties, so that we can read it back
       in on startup and re-stack the windows as they were before we shut down
    */
    if (ob_state() == OB_STATE_EXITING) return;

    /* create an array of the window ids (from bottom to top,
       reverse order!) */
    if ([self count]) {
        windows = calloc(sizeof(Window), [self count]);
	int j, jcount = [self count];
	for (j = jcount-1; j > -1; j--) {
	  id <AZWindow> temp = [self windowAtIndex: j];
	  if (WINDOW_IS_CLIENT(temp)) {
	    windows[i++] = [(AZClient *)temp window];
	  }
	}
    }

    PROP_SETA32(RootWindow(ob_display, ob_screen),
                net_client_list_stacking, window, (unsigned long *)windows, i);

    free(windows);
}

- (void) raiseWindow: (id <AZWindow>) window group: (BOOL) group
{
    NSMutableArray *wins = [[NSMutableArray alloc] init];

    if (WINDOW_IS_CLIENT(window)) {
        AZClient *c;
        AZClient *selected;
        selected = (AZClient *)window;
	c = [selected searchTopTransient];
	[wins addObjectsFromArray: [self pickWindowsFrom: c to: selected raise: YES]];
	[wins addObjectsFromArray: [self pickGroupWindowsFrom: c to: selected raise: YES normal: group]];
    } else {
	[wins addObject: window];
	[self removeWindow: window];
    }
    [self doRaise: wins];
    DESTROY(wins);
}

- (void) lowerWindow: (id <AZWindow>) window group: (BOOL) group
{
    NSMutableArray *wins = [[NSMutableArray alloc] init];

    if (WINDOW_IS_CLIENT(window)) {
        AZClient *c;
        AZClient *selected;
        selected = (AZClient*)window;
	c = [selected searchTopTransient];
	NSArray *w = [self pickWindowsFrom: c to: selected raise: NO];
	[wins addObjectsFromArray: [self pickGroupWindowsFrom: c to: selected raise: NO normal: group]];
	[wins addObjectsFromArray: w];
    } else {
	[wins addObject: window];
	[self removeWindow: window];
    }
    [self doLower: wins];
    DESTROY(wins);
}

- (void) moveWindow: (id <AZWindow>) window belowWindow: (id <AZWindow>) below
{
    id <AZWindow> before = nil;

    if ([window windowLayer] != [below windowLayer])
        return;

    NSMutableArray *wins = [[NSMutableArray alloc] init];

    [wins addObject: window];
    [self removeWindow: window];
    int index = [stacking_list indexOfObject: below];
    if ((index == -1 || (index > [self count]-2))) // Not found
      before = nil;
    else
      before = [self windowAtIndex: index+1];
    [self doRestack: wins before: before];
    DESTROY(wins);
}

- (void) addWindow: (id <AZWindow>) win
{
    ObStackingLayer l;

    AZScreen *screen = [AZScreen defaultScreen];
    g_assert([screen supportXWindow] != None); /* make sure I dont break this in the
                                             future */

    l = [win windowLayer];

    [stacking_list addObject: win];
    [self raiseWindow: win group: NO];
}

- (void) removeWindow: (id <AZWindow>) win
{
  [stacking_list removeObject: win];
}

/* Accessories */
- (int) count
{
  [stacking_list count];
}

- (id <AZWindow>) windowAtIndex: (int) index
{
  return [stacking_list objectAtIndex: index];
}

- (id) init
{
  self = [super init];
  stacking_list = [[NSMutableArray alloc] init];
  return self;
}

- (void) dealloc
{
  DESTROY(stacking_list);
  [super dealloc];
}

+ (AZStacking *) stacking
{
  if (sharedInstance == nil)
  {
    sharedInstance = [[AZStacking alloc] init];
  }
  return sharedInstance;
}

@end

@implementation AZStacking (AZPrivate)
- (void) doRestack: (NSArray *) wins before: (id <AZWindow>) before;
{
    id <AZWindow> data;
    Window *win;
    int i, j, jcount = [wins count];

#ifdef DEBUG
    GList *next;
    /* pls only restack stuff in the same layer at a time */
    for (it = wins; it; it = next) {
        next = g_list_next(it);
        if (!next) break;
	g_assert ([((id <AZWindow>)(it->data)) windowLayer] == [((id <AZWindow>)(next->data)) windowLayer]);
    }
    if (before)
	g_assert ([((id <AZWindow>)(it->data)) windowLayer] == [((id <AZWindow>)(before->data)) windowLayer]);
#endif

    win = calloc(sizeof(Window), [wins count] + 1);

    if (before == ([self count] ? [self windowAtIndex: 0] : nil)) {
        win[0] = [[AZScreen defaultScreen] supportXWindow];
    } else if (!before) {
        win[0] = [[stacking_list lastObject] windowTop];
    } else {
	int index = [stacking_list indexOfObject: before];
	if (index < 1) {
	  NSLog(@"Internal Error: cannot find window in doRestack:before:");
	} else {
	  win[0] = [(id <AZWindow>)[self windowAtIndex: index-1] windowTop];
	}
    }

    for (i = 1, j = 0; j < jcount; ++i, j++) {
	data = [wins objectAtIndex: j];
        win[i] = [data windowTop];
        g_assert(win[i] != None); /* better not call stacking shit before
                                     setting your top level window value */
	if (before == nil) {
	  [stacking_list addObject: data];
	} else {
	  int index = [stacking_list indexOfObject: before];
	  if (index == NSNotFound) {
	    [stacking_list addObject: data];
	  } else if (index > 0) {
	    [stacking_list insertObject: data atIndex: index];
	  } else { /* Not sure 0 or last */
	    [stacking_list insertObject: data atIndex: 0];
	  } 
	}
    }

#ifdef DEBUG
    /* some debug checking of the stacking list's order */
    for (it = stacking_list; ; it = next) {
        next = g_list_next(it);
        if (!next) break;
        g_assert([(id <AZWindow>)(it->data) windowLayer] >= [(id <AZWindow>)(next->data) windowLayer]);
    }
#endif

    XRestackWindows(ob_display, win, i);
    free(win);

    [self setList];
}

- (void) doRaise: (NSArray *) wins
{
    NSMutableDictionary *dict = AUTORELEASE([[NSMutableDictionary alloc] init]);
    NSMutableArray *array = nil;
    int i, icount = [wins count];
    for (i = 0; i < icount; i++) {
      ObStackingLayer l;
      l = [(id <AZWindow>)[wins objectAtIndex: i] windowLayer];

      array = [dict objectForKey: [NSNumber numberWithInt: l]];
      if (array == nil) {
        array = AUTORELEASE([[NSMutableArray alloc] init]);
      }
      [array addObject: [wins objectAtIndex: i]];
      [dict setObject: array forKey: [NSNumber numberWithInt: l]];
    }

    NSArray *allLayers = [dict allKeys];
    NSArray *sorted = [allLayers sortedArrayUsingSelector: @selector(compare:)];

    id <AZWindow> data = nil;
    NSMutableArray *layer = nil;
    int j, jcount = [sorted count];
    int k, kcount = 0;
    int b, index;
    for (j = jcount - 1; j > -1; j--) {
      NSArray *a = [dict objectForKey: [sorted objectAtIndex: j]];
      kcount = [a count];
      if (kcount) {
	/* build layer */
	layer = [[NSMutableArray alloc] init];
	for (k = 0; k < kcount; k++) {
	  [layer addObject: [a objectAtIndex: k]];
	}

	index = NSNotFound;
	for (b = 0; b < [self count]; b++) {
          /* look for the top of the layer */
	  if ([[self windowAtIndex: b] windowLayer] <= (ObStackingLayer)[[sorted objectAtIndex: j] intValue])
	  {
	    index = b;
	    break;
	  }
	}
	if (index != NSNotFound)
	  data = [self windowAtIndex: index];
	else
          data = nil;
	[self doRestack: layer before: data];
	DESTROY(layer);
      }
    }
}

- (void) doLower: (NSArray *) wins
{
    NSMutableDictionary *dict = AUTORELEASE([[NSMutableDictionary alloc] init]);
    NSMutableArray *array = nil;
    int i, icount = [wins count];
    for (i = 0; i < icount; i++) {
      ObStackingLayer l;
      l = [(id <AZWindow>)[wins objectAtIndex: i] windowLayer];

      array = [dict objectForKey: [NSNumber numberWithInt: l]];
      if (array == nil) {
        array = AUTORELEASE([[NSMutableArray alloc] init]);
      }
      [array addObject: [wins objectAtIndex: i]];
      [dict setObject: array forKey: [NSNumber numberWithInt: l]];
    }

    NSArray *allLayers = [dict allKeys];
    NSArray *sorted = [allLayers sortedArrayUsingSelector: @selector(compare:)];

    id <AZWindow> data = nil;
    NSMutableArray *layer = nil;
    int j, jcount = [sorted count];
    int k, kcount = 0;
    int b, index;
    for (j = jcount - 1; j > -1; j--) {
      NSArray *a = [dict objectForKey: [sorted objectAtIndex: j]];
      kcount = [a count];
      if (kcount) {
	/* build layer */
	layer = [[NSMutableArray alloc] init];
	for (k = 0; k < kcount; k++) {
	  [layer addObject: [a objectAtIndex: k]];
	}

	index = NSNotFound;
	for (b = 0; b < [self count]; b++) {
          /* look for the top of the layer */
	  if ([[self windowAtIndex: b] windowLayer] < (ObStackingLayer)[[sorted objectAtIndex: j] intValue])
	  {
	    index = b;
	    break;
	  }
	}
	if (index != NSNotFound)
	  data = [self windowAtIndex: index];
	else
          data = nil;
	[self doRestack: layer before: data];
	DESTROY(layer);
      }
    }
}

- (NSArray *)pickWindowsFrom: (AZClient *) top to: (AZClient *) selected 
		     raise: (BOOL) raise
{
    NSMutableArray *ret = AUTORELEASE([[NSMutableArray alloc] init]);
    id <AZWindow> data = nil;
    int i, n;
    NSMutableArray *modals = [[NSMutableArray alloc] init];
    NSMutableArray *trans = [[NSMutableArray alloc] init];
    NSMutableArray *modal_sel = [[NSMutableArray alloc] init]; /* the selected guys if modal */
    NSMutableArray *tran_sel = [[NSMutableArray alloc] init]; /* the selected guys if not */

    /* remove first so we can't run into ourself */
    int index = [stacking_list indexOfObject: top];
    if (index != NSNotFound)
      [self removeWindow: top];
    else
      return ret; /* Empty */

    i = 0;
    n = [[top transients] count];

    int prev_index;
    int j;
    for (j = 0; i < n, j < [self count];/*j++ in the end */ ) {
	data = [self windowAtIndex: j];
	prev_index = j - 1;

	int index = NSNotFound;

	if (WINDOW_IS_CLIENT(data))
	  index = [[top transients] indexOfObject: (AZClient*)data];

	if (index != NSNotFound) {
            AZClient *c = [[top transients] objectAtIndex: index];
            BOOL sel_child;

            ++i;

            if (c == selected)
                sel_child = YES;
            else
		sel_child = ([c searchTransient: selected] != nil);

            if (![c modal]) {
                if (!sel_child) {
		    [trans addObjectsFromArray: [self pickWindowsFrom: c to: selected raise: raise]];
                } else {
		    [tran_sel addObjectsFromArray: [self pickWindowsFrom: c to: selected raise: raise]];
                }
            } else {
                if (!sel_child) {
		    [modals addObjectsFromArray: [self pickWindowsFrom: c to: selected raise: raise]];
                } else {
		    [modal_sel addObjectsFromArray: [self pickWindowsFrom: c to: selected raise: raise]];
                }
            }
            /* if we dont have a prev then start back at the beginning,
               otherwise skip back to the prev's next */
	    if (prev_index < 0) {
              j = 0;
	      continue;
	    }
        }
	j++;
    }

    [ret addObjectsFromArray: (raise ? modal_sel : modals)];
    [ret addObjectsFromArray: (raise ? modals : modal_sel)];

    [ret addObjectsFromArray: (raise ? tran_sel : trans)];
    [ret addObjectsFromArray: (raise ? trans : tran_sel)];


    /* add itself */
    [ret addObject: top];
    DESTROY(modals);
    DESTROY(modal_sel);
    DESTROY(trans);
    DESTROY(tran_sel);

    return ret;
}

- (NSArray *)pickGroupWindowsFrom: (AZClient *) top to: (AZClient *) selected
                     raise: (BOOL) raise normal: (BOOL) normal
{
    NSMutableArray *ret = AUTORELEASE([[NSMutableArray alloc] init]);
    id <AZWindow> data = nil;
    int i, n;

    /* add group members in their stacking order */
    if ((top) && (top != OB_TRAN_GROUP) && ([top group])) {
        i = 0;
	n = [[[top group] members] count]-1;
	int prev_index;
	int j;
	for (j = 0; i < n, j < [self count]; /* j++ later */) {
	    data = [self windowAtIndex: j];
	    prev_index = j - 1;

	    /* Not in openbox. Maybe have side-effect. */
	    if (!WINDOW_IS_CLIENT(data)) {
              j++;
	      continue;
            }

	    int sit = [[top group] indexOfMember: (AZClient*)data];
	    if (sit != NSNotFound) {
                AZClient *c = nil;
                ObClientType t;

                ++i;
                c = (AZClient *)data;
                t = [c type];

                if (([c desktop] == [selected desktop] ||
                     [c desktop] == DESKTOP_ALL) &&
                    (t == OB_CLIENT_TYPE_TOOLBAR ||
                     t == OB_CLIENT_TYPE_MENU ||
                     t == OB_CLIENT_TYPE_UTILITY ||
                     (normal && t == OB_CLIENT_TYPE_NORMAL)))
                {
		    AZClient *data = [[top group] memberAtIndex: sit];
                    [ret addObjectsFromArray:
                        [self pickWindowsFrom: data to: selected raise: raise]];
                    /* if we dont have a prev then start back at the beginning,
                       otherwise skip back to the prev's next */
		    if (prev_index < 0) {
		      j = 0;
		      continue;
		    }
                }
            }
	    j++;
        }
    }
    return ret;
}

@end

