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
#import "AZFocusManager.h"
#import "AZGroup.h"
#import "AZClient.h"
#import "openbox.h"
#import "prop.h"

static AZStacking *sharedInstance;

@interface AZStacking (AZPrivate)
- (void) doRestack: (NSArray *) wins before: (id <AZWindow>) before;
- (void) doRaise: (NSArray *) wins;
- (void) doLower: (NSArray *) wins;
- (void) restackWindows: (AZClient *) selected raise: (BOOL) raise;
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

- (void) raiseWindow: (id <AZWindow>) window 
{
    if (WINDOW_IS_CLIENT(window)) {
        AZClient *selected = (AZClient *)window;
	[self restackWindows: selected raise: YES];
    } else {
        NSMutableArray *wins = [[NSMutableArray alloc] init];
	[wins addObject: window];
	[self removeWindow: window];
	[self doRaise: wins];
	DESTROY(wins);
    }
}

- (void) lowerWindow: (id <AZWindow>) window
{		
    if (WINDOW_IS_CLIENT(window)) {
        AZClient *selected = (AZClient*)window;
	[self restackWindows: selected raise: NO];
    } else {
        NSMutableArray *wins = [[NSMutableArray alloc] init];
	[wins addObject: window];
	[self removeWindow: window];
        [self doLower: wins];
        DESTROY(wins);
    }
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
    AZScreen *screen = [AZScreen defaultScreen];
    NSAssert([screen supportXWindow] != None, @"SupportXWindow cannot be None"); /* make sure I dont break this in the future */

    [stacking_list addObject: win];
    [self raiseWindow: win];
}

- (void) addWindowNonIntrusively: (id <AZWindow>) win
{
    AZClient *client = nil;
    AZClient *parent = nil;

    if (!WINDOW_IS_CLIENT(win)) {
        [self addWindow: win]; /* no special rules for others */
        return;
    }

    client = (AZClient *)win;

    /* insert above its highest parent */
    if ([client transient_for]) {
        if ([client transient_for] != OB_TRAN_GROUP) {
            parent = [client transient_for];
        } else {
	    int sit, it;

            if ([client group])
	    {
		NSArray *members = [[client group] members];
		for (it = 0; !parent && (it < [stacking_list count]); it++)
		{
		    AZClient *data = [self windowAtIndex: it];
		    if ([members containsObject: data])
		    {
			for (sit = 0; !parent && (sit < [members count]); sit++)
			{
			    AZClient *c = [members objectAtIndex: sit];
			    /* checking transient_for prevents infinate loops */
                    	    if ([c isEqual: data] && ![c transient_for])
                              parent = data;
			}
		    }
		}
	    }
	}
    }

    AZClient *it_below = nil;
    int index = [stacking_list indexOfObject: parent];
    if (index == NSNotFound)
    {
        /* no parent to put above, try find the focused client to go
           under */
	AZClient *fc = [[AZFocusManager defaultManager] focus_client];
        if (fc && [fc windowLayer] == [client windowLayer]) 
	{
	    index = [stacking_list indexOfObject: fc];
	    if ((index != NSNotFound) && (index < [stacking_list count]-2))
	    {
	        it_below = [self windowAtIndex: index+1];
	    }
        }
    }
    if (it_below == nil)
    {
        /* there is no window to put this directly above, so put it at the
           bottom */
        [stacking_list insertObject: win atIndex: 0];
	[self lowerWindow: win];
    } else {
        /* make sure it's not in the wrong layer though ! */
	index = [stacking_list indexOfObject: it_below];
	if (index == NSNotFound)
	    NSLog(@"Internal Error: inconsistent it_below position");
	for (; index < [stacking_list count]; index++)
 	{
            /* stop when the window is not in a higher layer than the window
               it is going above (it_below) */
	    AZClient *data = [self windowAtIndex: index];
            if ([client windowLayer] >= [data windowLayer])
                break;
        }
	for (; index > 0; index--)
	{
            /* stop when the window is not in a lower layer than the
               window it is going under (it_above) */
  	    AZClient *it_above = [stacking_list objectAtIndex: (index-1)];
	    if ([client windowLayer] <= [it_above windowLayer])
	      break;
        }

	NSArray *wins = [[NSArray alloc] initWithObjects: win, nil];
	[self doRestack: wins before: [self windowAtIndex: index]];
	DESTROY(wins);
    }
}

- (void) removeWindow: (id <AZWindow>) win
{
  [stacking_list removeObject: win];
}

/* Accessories */
- (int) count
{
  return [stacking_list count];
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

    win = calloc(sizeof(Window), [wins count] + 1);

    if (before == ([self count] ? [self windowAtIndex: 0] : nil)) {
        win[0] = [[AZScreen defaultScreen] supportXWindow];
    } else if (!before) {
        win[0] = [[stacking_list lastObject] windowTop];
    } else {
	int index = [stacking_list indexOfObject: before];
	if (index == NSNotFound) {
	  NSLog(@"Internal Error: cannot find window in doRestack:before:");
	} else {
	  win[0] = [(id <AZWindow>)[self windowAtIndex: index-1] windowTop];
	}
    }

    for (i = 1, j = 0; j < jcount; ++i, j++) {
	data = [wins objectAtIndex: j];
        win[i] = [data windowTop];
        NSAssert(win[i] != None, @"Window cannot be NONE"); /* better not call stacking shit before setting your top level window value */
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

- (void)restackWindows: (AZClient *) selected raise: (BOOL) raise
{
    if (!raise && [selected transient_for])
    {
        /* if it's a transient lowering, lower its parents so that we can lower
           this window, or it won't move */
        NSMutableArray *top = [[NSMutableArray alloc] initWithArray: [selected searchAllTopParents]];
        NSMutableArray *top_reorder = [[NSMutableArray alloc] init];

        /* that is, if it has any parents */
        if (!(top && [top count] == 1 && [top objectAtIndex: 0] == selected)) 
        {
          /* go thru stacking list backwards so we can use g_slist_prepend */
	  int i = [stacking_list count]-1;
          for (; (i > -1) && ([top count] > 0); i--)
	  {
	    id <AZWindow> it = [self windowAtIndex: i];
	    if ([top containsObject: it])
	    {
	      if ([top_reorder count] > 0)
 	        [top_reorder insertObject: it atIndex: 0];
	      else 
 	        [top_reorder addObject: it];
	      [top removeObject: it];
	    }
	  }

	  if ([top count] > 0)
	    NSLog(@"Internal Error: top parents are left");

          /* call restack for each of these to lower them */
	  for (i = 0; i < [top_reorder count]; i++)
	  {
	    [self restackWindows: [top_reorder objectAtIndex: i]
	                   raise: raise];
	  }
	  DESTROY(top_reorder);
	  DESTROY(top);
	  return;
       }
    }

    /* remove first so we can't run into ourself */
    int index = [stacking_list indexOfObject: selected];
    if (index != NSNotFound)
      [self removeWindow: selected];
    else
      NSLog(@"Internal Error: Cannot find itself");

    /* go from the bottom of the stacking list up */
    NSMutableArray *wins = AUTORELEASE([[NSMutableArray alloc] init]);
    NSMutableArray *modals = AUTORELEASE([[NSMutableArray alloc] init]);
    NSMutableArray *trans = AUTORELEASE([[NSMutableArray alloc] init]);
    NSMutableArray *group_modals = AUTORELEASE([[NSMutableArray alloc] init]);
    NSMutableArray *group_trans = AUTORELEASE([[NSMutableArray alloc] init]);
    id <AZWindow> data = nil;
    int i = [stacking_list count]-1;
    for (; i > -1; i--)
    {
	data = [self windowAtIndex: i];

	if (WINDOW_IS_CLIENT(data))
	{
	  AZClient *ch = (AZClient *) data;
          /* only move windows in the same stacking layer */
          if (([ch windowLayer] == [selected windowLayer]) &&
	      [selected searchTransient: ch])
	  {
	    if ([selected hasDirectChild: ch])
	    {
	       if ([ch modal])
	       {
		 if ([modals count] > 0)
		    [modals insertObject: ch atIndex: 0];
	    	 else
		    [modals addObject: ch];
	       }
	       else
	       {
		 if ([trans count] > 0)
		    [trans insertObject: ch atIndex: 0];
	    	 else
		    [trans addObject: ch];
	       }
	    }
	    else
	    {
	       if ([ch modal])
	       {
		 if ([group_modals count] > 0)
		    [group_modals insertObject: ch atIndex: 0];
	    	 else
		    [group_modals addObject: ch];
	       }
	       else
	       {
		 if ([group_trans count] > 0)
		    [group_trans insertObject: ch atIndex: 0];
	    	 else
		    [group_trans addObject: ch];
	       }
	    }
	    /* We can safely delete it because the loop is backward */
	    [self removeWindow: ch];
	  }
	}
    }

    /* put transients of the selected window right above it */
    [wins addObjectsFromArray: modals];
    [wins addObjectsFromArray: trans];
    [wins addObject: selected];

    /* if selected window is transient for group then raise it above others */
    if ([selected transient_for] == OB_TRAN_GROUP) {
        /* if it's modal, raise it above those also */
        if ([selected modal]) {
	    [wins addObjectsFromArray: group_modals];
	    group_modals = nil; /* It is autoreleased */
        }
	[wins addObjectsFromArray: group_trans];
	group_trans = nil; /* It is autoreleased */
    }

    /* find where to put the selected window, start from bottom of list,
       this is the window below everything we are re-adding to the list */
    int last = NSNotFound;
    int below = NSNotFound;
    i = [stacking_list count]-1;
    for (; i > -1; i--)
    {
	data = [self windowAtIndex: i];
	if ([data windowLayer] < [selected windowLayer])
	{
	  last = i;
	  continue;
	}
        /* if lowering, stop at the beginning of the layer */
        if (!raise)
            break;
        /* if raising, stop at the end of the layer */
        if ([data windowLayer] > [selected windowLayer])
            break;
	last = i;
    }

    /* save this position in the stacking list */
    below = last;
    id <AZWindow> belowWindow = nil;
    if (below != NSNotFound)
      belowWindow = [self windowAtIndex: below];

    /* find where to put the group transients, start from the top of list */
    for (i = 0; i < [stacking_list count]; i++)
    {
	data = [self windowAtIndex: i];
        /* skip past higher layers */
        if ([data windowLayer] > [selected windowLayer])
            continue;
        /* if we reach the end of the layer (how?) then don't go further */
        if ([data windowLayer] < [selected windowLayer])
            break;
        /* stop when we reach the first window in the group */
        if (WINDOW_IS_CLIENT(data)) 
	{
            AZClient *c = (AZClient *)data;
            if ([c group] == [selected group])
                break;
        }
        /* if we don't hit any other group members, stop here because this
           is where we are putting the selected window (and its children) */
        if (i == below)
            break;
    }

    /* save this position, this is the top of the group of windows between the
       group transient ones we're restacking and the others up above that we're
       restacking

       we actually want to save 1 position _above_ that, for for loops to work
       nicely, so move back one position in the list while saving it
    */
    int above = NSNotFound;
    if (i < [stacking_list count])
    {
      if (i > 1)
        above = i-1;
    }
    else
    {
      if ([stacking_list count] > 0)
        above = [stacking_list count]-1;
    }

    /* put the windows inside the gap to the other windows we're stacking
       into the restacking list, go from the bottom up so that we can use
       g_list_prepend */
    index = NSNotFound;
    if (below != NSNotFound)
    {
      if (below > 1)
        index = below-1;
    }
    else
    {
      if ([stacking_list count] > 0)
        index = [stacking_list count]-1;
    }

    if (index == NSNotFound)
      NSLog(@"Internal Error: index %d out of range of stacking_list", index);

    for (; (index != above) && (index > -1); index--)
    {
      id <AZWindow> data = [self windowAtIndex: index];
      if ([wins count] > 0)
        [wins insertObject: data atIndex: 0];
      else
        [wins addObject: data];
      [self removeWindow: data]; /* We do this backward */
    }

    NSMutableArray *a = AUTORELEASE([[NSMutableArray alloc] init]);
    /* group modals go on the very top */
    [a addObjectsFromArray: group_modals];
    /* group transients go above the rest of the stuff acquired to now */
    [a addObjectsFromArray: group_trans];
    [a addObjectsFromArray: wins];

    [self doRestack: wins before: belowWindow];
}

@end

