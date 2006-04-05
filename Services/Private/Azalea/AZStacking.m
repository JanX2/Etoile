// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

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
- (void) doRestack: (GList *) wins before: (GList *) before;
- (void) doRaise: (GList *) wins;
- (void) doLower: (GList *) wins;
- (GList *)pickWindowsFrom: (ObClient *) top to: (ObClient *) selected raise: (gboolean) raise;
- (GList *)pickGroupWindowsFrom: (ObClient *) top to: (ObClient *) selected raise: (gboolean) raise normal: (gboolean) normal;
@end

@implementation AZStacking

- (void) setList
{
    Window *windows = NULL;
    GList *it;
    guint i = 0;

    /* on shutdown, don't update the properties, so that we can read it back
       in on startup and re-stack the windows as they were before we shut down
    */
    if (ob_state() == OB_STATE_EXITING) return;

    /* create an array of the window ids (from bottom to top,
       reverse order!) */
    if (stacking_list) {
        windows = g_new(Window, g_list_length(stacking_list));
        for (it = g_list_last(stacking_list); it; it = g_list_previous(it)) {
            if (WINDOW_IS_CLIENT(it->data))
                windows[i++] = [WINDOW_AS_CLIENT(it->data)->_self window];
        }
    }

    PROP_SETA32(RootWindow(ob_display, ob_screen),
                net_client_list_stacking, window, (gulong*)windows, i);

    g_free(windows);
}

- (void) raiseWindow: (ObWindow *) window group: (BOOL) group
{
    GList *wins;

    if (WINDOW_IS_CLIENT(window)) {
        ObClient *c;
        ObClient *selected;
        selected = WINDOW_AS_CLIENT(window);
	c = [[selected->_self searchTopTransient] obClient];
	wins = [self pickWindowsFrom: c to: selected raise: TRUE];
	wins = g_list_concat(wins, [self pickGroupWindowsFrom: c to: selected raise: TRUE normal: group]);
    } else {
        wins = g_list_append(NULL, window);
        stacking_list = g_list_remove(stacking_list, window);
    }
    [self doRaise: wins];
    g_list_free(wins);
}

- (void) lowerWindow: (ObWindow *) window group: (BOOL) group
{
    GList *wins;

    if (WINDOW_IS_CLIENT(window)) {
        ObClient *c;
        ObClient *selected;
        selected = WINDOW_AS_CLIENT(window);
	c = [[selected->_self searchTopTransient] obClient];
	wins = [self pickWindowsFrom: c to: selected raise: FALSE];
        wins = g_list_concat([self pickGroupWindowsFrom: c to: selected raise: FALSE normal: group], wins);
    } else {
        wins = g_list_append(NULL, window);
        stacking_list = g_list_remove(stacking_list, window);
    }
    [self doLower: wins];
    g_list_free(wins);
}

- (void) moveWindow: (ObWindow *) window belowWindow: (ObWindow *) below
{
    GList *wins, *before;

    if (window_layer(window) != window_layer(below))
        return;

    wins = g_list_append(NULL, window);
    stacking_list = g_list_remove(stacking_list, window);
    before = g_list_next(g_list_find(stacking_list, below));
    [self doRestack: wins before: before];
    g_list_free(wins);
}

- (void) addWindow: (ObWindow *) win
{
    ObStackingLayer l;

    AZScreen *screen = [AZScreen defaultScreen];
    g_assert([screen supportXWindow] != None); /* make sure I dont break this in the
                                             future */

    l = window_layer(win);

    stacking_list = g_list_append(stacking_list, win);
    [self raiseWindow: win group: FALSE];
}

- (void) removeWindow: (ObWindow *) win
{
  stacking_list = g_list_remove(stacking_list, win);
}

/* Accessories */
- (int) count
{
  return g_list_length(stacking_list);
}

- (ObWindow *) windowAtIndex: (int) index
{
  return (ObWindow *)g_list_nth_data(stacking_list, index);
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
- (void) doRestack: (GList *) wins before: (GList *) before;
{
    GList *it, *next;
    Window *win;
    gint i;

#ifdef DEBUG
    /* pls only restack stuff in the same layer at a time */
    for (it = wins; it; it = next) {
        next = g_list_next(it);
        if (!next) break;
        g_assert (window_layer(it->data) == window_layer(next->data));
    }
    if (before)
        g_assert(window_layer(it->data) >= window_layer(before->data));
#endif

    win = g_new(Window, g_list_length(wins) + 1);

    if (before == stacking_list)
        win[0] = [[AZScreen defaultScreen] supportXWindow];
    else if (!before)
        win[0] = window_top(g_list_last(stacking_list)->data);
    else
        win[0] = window_top(g_list_previous(before)->data);

    for (i = 1, it = wins; it; ++i, it = g_list_next(it)) {
        win[i] = window_top(it->data);
        g_assert(win[i] != None); /* better not call stacking shit before
                                     setting your top level window value */
        stacking_list = g_list_insert_before(stacking_list, before, it->data);
    }

#ifdef DEBUG
    /* some debug checking of the stacking list's order */
    for (it = stacking_list; ; it = next) {
        next = g_list_next(it);
        if (!next) break;
        g_assert(window_layer(it->data) >= window_layer(next->data));
    }
#endif

    XRestackWindows(ob_display, win, i);
    g_free(win);

    [self setList];
}

- (void) doRaise: (GList *) wins
{
#if 1
    NSMutableDictionary *dict = AUTORELEASE([[NSMutableDictionary alloc] init]);
    NSMutableArray *array = nil;
    int i, icount = g_list_length(wins);
    for (i = 0; i < icount; i++) {
      ObStackingLayer l;
      l = window_layer(g_list_nth_data(wins, i));

      array = [dict objectForKey: [NSNumber numberWithInt: l]];
      if (array == nil) {
        array = AUTORELEASE([[NSMutableArray alloc] init]);
      }
      [array addObject: [NSValue valueWithPointer: g_list_nth_data(wins, i)]];
      [dict setObject: array forKey: [NSNumber numberWithInt: l]];
    }

    NSArray *allLayers = [dict allKeys];
    NSArray *sorted = [allLayers sortedArrayUsingSelector: @selector(compare:)];

    GList *it = stacking_list;
    GList *layer = NULL;
    int j, jcount = [sorted count];
    int k, kcount = 0;
    for (j = jcount - 1; j > -1; j--) {
      NSArray *a = [dict objectForKey: [sorted objectAtIndex: j]];
      kcount = [a count];
      if (kcount) {
	/* build layer */
	for (k = 0; k < kcount; k++) {
          layer = g_list_append(layer, [[a objectAtIndex: k] pointerValue]);
	}

	for (; it; it = g_list_next(it)) {
          /* look for the top of the layer */
	  if (window_layer(it->data) <= (ObStackingLayer)[[sorted objectAtIndex: j] intValue])
	  {
	    break;
	  }
	}
	[self doRestack: layer before: it];
	g_list_free(layer);
	layer = NULL;
      }
    }
#else
    GList *it;
    GList *layer[OB_NUM_STACKING_LAYERS] = {NULL};
    gint i;

    for (it = wins; it; it = g_list_next(it)) {
        ObStackingLayer l;

        l = window_layer(it->data);
        layer[l] = g_list_append(layer[l], it->data);
    }

    it = stacking_list;
    for (i = OB_NUM_STACKING_LAYERS - 1; i >= 0; --i) {
        if (layer[i]) {
            for (; it; it = g_list_next(it)) {
                /* look for the top of the layer */
                if (window_layer(it->data) <= (ObStackingLayer) i)
                    break;
            }
	    [self doRestack: layer[i] before: it];
            g_list_free(layer[i]);
        }
    }
#endif
}

- (void) doLower: (GList *) wins
{
#if 1
    NSMutableDictionary *dict = AUTORELEASE([[NSMutableDictionary alloc] init]);
    NSMutableArray *array = nil;
    int i, icount = g_list_length(wins);
    for (i = 0; i < icount; i++) {
      ObStackingLayer l;
      l = window_layer(g_list_nth_data(wins, i));

      array = [dict objectForKey: [NSNumber numberWithInt: l]];
      if (array == nil) {
        array = AUTORELEASE([[NSMutableArray alloc] init]);
      }
      [array addObject: [NSValue valueWithPointer: g_list_nth_data(wins, i)]];
      [dict setObject: array forKey: [NSNumber numberWithInt: l]];
    }

    NSArray *allLayers = [dict allKeys];
    NSArray *sorted = [allLayers sortedArrayUsingSelector: @selector(compare:)];

    GList *it = stacking_list;
    GList *layer = NULL;
    int j, jcount = [sorted count];
    int k, kcount = 0;
    for (j = jcount - 1; j > -1; j--) {
      NSArray *a = [dict objectForKey: [sorted objectAtIndex: j]];
      kcount = [a count];
      if (kcount) {
	/* build layer */
	for (k = 0; k < kcount; k++) {
          layer = g_list_append(layer, [[a objectAtIndex: k] pointerValue]);
	}

	for (; it; it = g_list_next(it)) {
          /* look for the top of the layer */
	  if (window_layer(it->data) < (ObStackingLayer)[[sorted objectAtIndex: j] intValue])
	  {
	    break;
	  }
	}
	[self doRestack: layer before: it];
	g_list_free(layer);
	layer = NULL;
      }
    }
#else
    GList *it;
    GList *layer[OB_NUM_STACKING_LAYERS] = {NULL};
    gint i;

    for (it = wins; it; it = g_list_next(it)) {
        ObStackingLayer l;

        l = window_layer(it->data);
        layer[l] = g_list_append(layer[l], it->data);
    }

    it = stacking_list;
    for (i = OB_NUM_STACKING_LAYERS - 1; i >= 0; --i) {
        if (layer[i]) {
            for (; it; it = g_list_next(it)) {
                /* look for the top of the next layer down */
                if (window_layer(it->data) < (ObStackingLayer) i)
                    break;
            }
	    [self doRestack: layer[i] before: it];
            g_list_free(layer[i]);
        }
    }
#endif
}

- (GList *)pickWindowsFrom: (ObClient *) top to: (ObClient *) selected 
		     raise: (gboolean) raise
{
    GList *ret = NULL;
    GList *it, *next, *prev;
    //GSList *sit;
    gint i, n;
    GList *modals = NULL;
    GList *trans = NULL;
    GList *modal_sel = NULL; /* the selected guys if modal */
    GList *trans_sel = NULL; /* the selected guys if not */

    /* remove first so we can't run into ourself */
    if ((it = g_list_find(stacking_list, top)))
        stacking_list = g_list_delete_link(stacking_list, it);
    else
        return NULL;

    i = 0;
    n = [[top->_self transients] count];

    for (it = stacking_list; i < n && it; it = next) {
        prev = g_list_previous(it);
        next = g_list_next(it);


	int index = NSNotFound;

	if (WINDOW_IS_CLIENT(it->data))
	{
	  index = [[top->_self transients] indexOfObject: ((ObClient*)(it->data))->_self];
	}

	if (index != NSNotFound) {
            ObClient *c = [[[top->_self transients] objectAtIndex: index] obClient];
            gboolean sel_child;

            ++i;

            if (c == selected)
                sel_child = TRUE;
            else
	    {
		sel_child = ([c->_self searchTransient: selected->_self] != nil);
	    }

            if (![c->_self modal]) {
                if (!sel_child) {
                    trans = g_list_concat(trans,
                         [self pickWindowsFrom: c to: selected raise: raise]);
                } else {
                    trans_sel = g_list_concat(trans_sel,
		   	 [self pickWindowsFrom: c to: selected raise: raise]);
                }
            } else {
                if (!sel_child) {
                    modals = g_list_concat(modals,
                         [self pickWindowsFrom: c to: selected raise: raise]);
                } else {
                    modal_sel = g_list_concat(modal_sel,
                         [self pickWindowsFrom: c to: selected raise: raise]);
                }
            }
            /* if we dont have a prev then start back at the beginning,
               otherwise skip back to the prev's next */
            next = prev ? g_list_next(prev) : stacking_list;
        }
    }

    ret = g_list_concat((raise ? modal_sel : modals),
                        (raise ? modals : modal_sel));

    ret = g_list_concat(ret, (raise ? trans_sel : trans));
    ret = g_list_concat(ret, (raise ? trans : trans_sel));


    /* add itself */
    ret = g_list_append(ret, top);

    return ret;
}

- (GList *)pickGroupWindowsFrom: (ObClient *) top to: (ObClient *) selected
                     raise: (gboolean) raise normal: (gboolean) normal
{
    GList *ret = NULL;
    GList *it = NULL, *next = NULL, *prev = NULL;
    gint i, n;

    /* add group members in their stacking order */
    if ((top) && (top != OB_TRAN_GROUP) && ([top->_self group])) {
        i = 0;
	n = [[[top->_self group] members] count]-1;
        for (it = stacking_list; i < n && it; it = next) {
            prev = g_list_previous(it);
            next = g_list_next(it);

	    // This fixes a bug. Probably due to the difference between
	    // glib and GNUstep.
	    if (!WINDOW_IS_CLIENT(it->data))
	    {
              //NSLog(@"Not a client %d", ((ObWindow*)(it->data))->type);
	      continue;
	    }

	    int sit = [[top->_self group] indexOfMember: ((ObClient*)(it->data))->_self];;
	    if (sit != NSNotFound) {
                ObClient *c = NULL;
                ObClientType t;

                ++i;
                c = it->data;
                t = [c->_self type];

                if (([c->_self desktop] == [selected->_self desktop] ||
                     [c->_self desktop] == DESKTOP_ALL) &&
                    (t == OB_CLIENT_TYPE_TOOLBAR ||
                     t == OB_CLIENT_TYPE_MENU ||
                     t == OB_CLIENT_TYPE_UTILITY ||
                     (normal && t == OB_CLIENT_TYPE_NORMAL)))
                {
		    AZClient *data = [[top->_self group] memberAtIndex: sit];
                    ret = g_list_concat(ret,
                        [self pickWindowsFrom: [data obClient]to: selected raise: raise]);
                    /* if we dont have a prev then start back at the beginning,
                       otherwise skip back to the prev's next */
                    next = prev ? g_list_next(prev) : stacking_list;
                }
            }
        }
    }
    return ret;
}
@end
