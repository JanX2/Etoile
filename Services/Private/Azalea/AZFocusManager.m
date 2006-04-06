// Modified by Yen-Ju Chen
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   focus.c for the Openbox window manager
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

#import "AZDock.h"
#import "AZScreen.h"
#import "AZEventHandler.h"
#import "AZDebug.h"
#import "AZGroup.h"
#import "AZClientManager.h"
#import "AZStacking.h"
#import "AZPopUp.h"
#import "AZFocusManager.h"
#import "openbox.h"
#import "grab.h"
#import "config.h"
#import "prop.h"
#import "render/render.h"
#import <assert.h>

struct {
    AZInternalWindow *top;
    AZInternalWindow *left;
    AZInternalWindow *right;
    AZInternalWindow *bottom;
} focus_indicator;

static void focus_cycle_destructor(ObClient *client, gpointer data)
{
    /* end cycling if the target disappears */
    AZFocusManager *fManager = [AZFocusManager defaultManager];
    if ([[fManager focus_cycle_target] obClient] == client)
      [fManager cycleForward: YES linear: YES interactive: YES
	          dialog: YES done: YES cancel: YES];
}

static Window createWindow(Window parent, gulong mask,
                           XSetWindowAttributes *attrib)
{
    return XCreateWindow(ob_display, parent, 0, 0, 1, 1, 0,
                         RrDepth(ob_rr_inst), InputOutput,
                         RrVisual(ob_rr_inst), mask, attrib);
                       
}

static AZFocusManager *sharedInstance;

@interface AZFocusManager (AZPrivate)

- (void) pushToTop: (AZClient *) client;
- (AZClient *) findTransientRecursive: (AZClient *) c : (AZClient *) top : (AZClient *) skip;
- (AZClient *) fallbackTransient: (AZClient *) top : (AZClient *) old;
- (void) popupCycle: (AZClient *) c show: (BOOL) show;
- (BOOL) validFocusTarget: (AZClient *) ft;
- (void) toTop: (AZClient *) c desktop: (unsigned int) d;
- (void) toBottom: (AZClient *) c desktop: (unsigned int) d;

@end

@implementation AZFocusManager

- (void) startup: (BOOL) reconfig
{
    focus_cycle_popup = [[AZIconPopUp alloc] initWithIcon: YES];

    if (!reconfig) {
        XSetWindowAttributes attr;
	AZStacking *stacking = [AZStacking stacking];

	[[AZClientManager defaultManager] addDestructor: focus_cycle_destructor data: NULL];

        /* start with nothing focused */
	[self setClient: nil];

        focus_indicator.top = [[AZInternalWindow alloc] init];
        focus_indicator.left = [[AZInternalWindow alloc] init];
        focus_indicator.right = [[AZInternalWindow alloc] init];
        focus_indicator.bottom = [[AZInternalWindow alloc] init];

        attr.save_under = True;
        attr.override_redirect = True;
        attr.background_pixel = BlackPixel(ob_display, ob_screen);
        [focus_indicator.top set_window: 
            createWindow(RootWindow(ob_display, ob_screen),
                         CWOverrideRedirect | CWBackPixel | CWSaveUnder,
                         &attr)];
        [focus_indicator.left set_window:
            createWindow(RootWindow(ob_display, ob_screen),
                         CWOverrideRedirect | CWBackPixel | CWSaveUnder,
                         &attr)];
        [focus_indicator.right set_window:
            createWindow(RootWindow(ob_display, ob_screen),
                         CWOverrideRedirect | CWBackPixel | CWSaveUnder,
                         &attr)];
        [focus_indicator.bottom set_window:
            createWindow(RootWindow(ob_display, ob_screen),
                         CWOverrideRedirect | CWBackPixel | CWSaveUnder,
                         &attr)];

        [stacking addWindow: focus_indicator.top];
        [stacking addWindow: focus_indicator.left];
        [stacking addWindow: focus_indicator.right];
        [stacking addWindow: focus_indicator.bottom];

        color_white = RrColorNew(ob_rr_inst, 0xff, 0xff, 0xff);

        a_focus_indicator = RrAppearanceNew(ob_rr_inst, 4);
        a_focus_indicator->surface.grad = RR_SURFACE_SOLID;
        a_focus_indicator->surface.relief = RR_RELIEF_FLAT;
        a_focus_indicator->surface.primary = RrColorNew(ob_rr_inst,
                                                        0, 0, 0);
        a_focus_indicator->texture[0].type = RR_TEXTURE_LINE_ART;
        a_focus_indicator->texture[0].data.lineart.color = color_white;
        a_focus_indicator->texture[1].type = RR_TEXTURE_LINE_ART;
        a_focus_indicator->texture[1].data.lineart.color = color_white;
        a_focus_indicator->texture[2].type = RR_TEXTURE_LINE_ART;
        a_focus_indicator->texture[2].data.lineart.color = color_white;
        a_focus_indicator->texture[3].type = RR_TEXTURE_LINE_ART;
        a_focus_indicator->texture[3].data.lineart.color = color_white;
    }
}

- (void) shutdown: (BOOL) reconfig
{
    guint i;
    unsigned int count = [[AZScreen defaultScreen] numberOfDesktops];

    DESTROY(focus_cycle_popup);

    if (!reconfig) {
	[[AZClientManager defaultManager] removeDestructor: focus_cycle_destructor];

        for (i = 0; i < count; ++i)
            g_list_free(focus_order[i]);
        g_free(focus_order);

        /* reset focus to root */
        XSetInputFocus(ob_display, PointerRoot, RevertToNone, [[AZEventHandler defaultHandler] eventLastTime]);

        RrColorFree(color_white);

        RrAppearanceFree(a_focus_indicator);

        XDestroyWindow(ob_display, [focus_indicator.top window]);
        XDestroyWindow(ob_display, [focus_indicator.left window]);
        XDestroyWindow(ob_display, [focus_indicator.right window]);
        XDestroyWindow(ob_display, [focus_indicator.bottom window]);

	DESTROY(focus_indicator.top);
	DESTROY(focus_indicator.left);
	DESTROY(focus_indicator.right);
	DESTROY(focus_indicator.bottom);
    }
}

- (void) setClient: (AZClient *) client
{
    Window active;
    AZClient *old;
    AZScreen *screen = [AZScreen defaultScreen];

#ifdef DEBUG_FOCUS
    AZDebug("focus_set_client 0x%lx\n", client ? [client window] : 0);
#endif

    /* uninstall the old colormap, and install the new one */
    [screen installColormap: focus_client install: NO];
    [screen installColormap: client install: YES];

    if (client == nil) {
#ifdef DEBUG_FOCUS
        AZDebug("actively focusing NONWINDOW\n");
#endif
        /* when nothing will be focused, send focus to the backup target */
        XSetInputFocus(ob_display, [screen supportXWindow], RevertToNone,
                       [[AZEventHandler defaultHandler] eventLastTime]);
        XSync(ob_display, FALSE);
    }

    /* in the middle of cycling..? kill it. */
    if (focus_cycle_target)
	[self cycleForward: YES linear: YES interactive: YES
		dialog: YES done: YES cancel: YES];

    old = focus_client;
    focus_client = client;

    /* move to the top of the list */
    if (client != nil)
	[self pushToTop: client];

    /* set the NET_ACTIVE_WINDOW hint, but preserve it on shutdown */
    if (ob_state() != OB_STATE_EXITING) {
        active = client ? [client window] : None;
        PROP_SET32(RootWindow(ob_display, ob_screen),
                   net_active_window, window, active);
    }
}

- (AZClient *) fallbackTarget: (ObFocusFallbackType) type
{
    GList *it;
    AZClient *old = nil;
    AZClient *target = nil;
    AZScreen *screen = [AZScreen defaultScreen];

    old = focus_client;

    if (type == OB_FOCUS_FALLBACK_UNFOCUSING && old) {
        if ([old transient_for]) {
            gboolean trans = FALSE;

            if (!config_focus_follow || config_focus_last)
                trans = TRUE;
            else {
                if ((target = AZUnderPointer()) &&
	            [[target searchTopTransient] searchTransient: old])
                {
                    trans = TRUE;
                }
            }

            /* try for transient relations */
            if (trans) {
                if ([old transient_for] == OB_TRAN_GROUP) {
                    for (it = focus_order[[screen desktop]]; it;
                         it = g_list_next(it))
                    {
	                int i, count = [[[old group] members] count];
			for (i = 0; i < count; i++) {
			  AZClient *data = [[old group] memberAtIndex: i];
                          if (data == ((AZClient*)(it->data)))
                                if ((target =
				     [self fallbackTransient: data : old]))
                                    return target;
                        }
                    }
                } else {
                    if ((target =
			 [self fallbackTransient: [old transient_for] : old]))
                        return target;
                }
            }
        }
    }

    if (config_focus_follow && !config_focus_last) {
        if ((target = AZUnderPointer()))
            if ([target normal] && [target canFocus])
                return target;
    }

    for (it = focus_order[[screen desktop]]; it; it = g_list_next(it))
        if (type != OB_FOCUS_FALLBACK_UNFOCUSING || ((AZClient *)(it->data)) != old)
            if ([((AZClient *)(it->data)) normal] && [((AZClient *)(it->data)) canFocus])
                return ((AZClient *)(it->data));

    return nil;
}

- (void) fallback: (ObFocusFallbackType) type
{
    AZClient *new;

    /* unfocus any focused clients.. they can be focused by Pointer events
       and such, and then when I try focus them, I won't get a FocusIn event
       at all for them.
    */
    [self setClient: nil];

    if ((new = [self fallbackTarget: type]))
	[new focus];
}

- (void) cycleDrawIndicator
{
    if (!focus_cycle_target) {
        XUnmapWindow(ob_display, [focus_indicator.top window]);
        XUnmapWindow(ob_display, [focus_indicator.left window]);
        XUnmapWindow(ob_display, [focus_indicator.right window]);
        XUnmapWindow(ob_display, [focus_indicator.bottom window]);
    } else {
        gint x, y, w, h;
        gint wt, wl, wr, wb;

        wt = wl = wr = wb = MAX(3,
                                ob_rr_theme->handle_height +
                                ob_rr_theme->bwidth * 2);

        x = [[focus_cycle_target frame] area].x;
        y = [[focus_cycle_target frame] area].y;
        w = [[focus_cycle_target frame] area].width;
        h = wt;

        XMoveResizeWindow(ob_display, [focus_indicator.top window],
                          x, y, w, h);
        a_focus_indicator->texture[0].data.lineart.x1 = 0;
        a_focus_indicator->texture[0].data.lineart.y1 = h-1;
        a_focus_indicator->texture[0].data.lineart.x2 = 0;
        a_focus_indicator->texture[0].data.lineart.y2 = 0;
        a_focus_indicator->texture[1].data.lineart.x1 = 0;
        a_focus_indicator->texture[1].data.lineart.y1 = 0;
        a_focus_indicator->texture[1].data.lineart.x2 = w-1;
        a_focus_indicator->texture[1].data.lineart.y2 = 0;
        a_focus_indicator->texture[2].data.lineart.x1 = w-1;
        a_focus_indicator->texture[2].data.lineart.y1 = 0;
        a_focus_indicator->texture[2].data.lineart.x2 = w-1;
        a_focus_indicator->texture[2].data.lineart.y2 = h-1;
        a_focus_indicator->texture[3].data.lineart.x1 = (wl-1);
        a_focus_indicator->texture[3].data.lineart.y1 = h-1;
        a_focus_indicator->texture[3].data.lineart.x2 = w - wr;
        a_focus_indicator->texture[3].data.lineart.y2 = h-1;
        RrPaint(a_focus_indicator, [focus_indicator.top window],
                w, h);

        x = [[focus_cycle_target frame] area].x;
        y = [[focus_cycle_target frame] area].y;
        w = wl;
        h = [[focus_cycle_target frame] area].height;

        XMoveResizeWindow(ob_display, [focus_indicator.left window],
                          x, y, w, h);
        a_focus_indicator->texture[0].data.lineart.x1 = w-1;
        a_focus_indicator->texture[0].data.lineart.y1 = 0;
        a_focus_indicator->texture[0].data.lineart.x2 = 0;
        a_focus_indicator->texture[0].data.lineart.y2 = 0;
        a_focus_indicator->texture[1].data.lineart.x1 = 0;
        a_focus_indicator->texture[1].data.lineart.y1 = 0;
        a_focus_indicator->texture[1].data.lineart.x2 = 0;
        a_focus_indicator->texture[1].data.lineart.y2 = h-1;
        a_focus_indicator->texture[2].data.lineart.x1 = 0;
        a_focus_indicator->texture[2].data.lineart.y1 = h-1;
        a_focus_indicator->texture[2].data.lineart.x2 = w-1;
        a_focus_indicator->texture[2].data.lineart.y2 = h-1;
        a_focus_indicator->texture[3].data.lineart.x1 = w-1;
        a_focus_indicator->texture[3].data.lineart.y1 = wt-1;
        a_focus_indicator->texture[3].data.lineart.x2 = w-1;
        a_focus_indicator->texture[3].data.lineart.y2 = h - wb;
        RrPaint(a_focus_indicator, [focus_indicator.left window],
                w, h);

        x = [[focus_cycle_target frame] area].x +
            [[focus_cycle_target frame] area].width - wr;
        y = [[focus_cycle_target frame] area].y;
        w = wr;
        h = [[focus_cycle_target frame] area].height ;

        XMoveResizeWindow(ob_display, [focus_indicator.right window],
                          x, y, w, h);
        a_focus_indicator->texture[0].data.lineart.x1 = 0;
        a_focus_indicator->texture[0].data.lineart.y1 = 0;
        a_focus_indicator->texture[0].data.lineart.x2 = w-1;
        a_focus_indicator->texture[0].data.lineart.y2 = 0;
        a_focus_indicator->texture[1].data.lineart.x1 = w-1;
        a_focus_indicator->texture[1].data.lineart.y1 = 0;
        a_focus_indicator->texture[1].data.lineart.x2 = w-1;
        a_focus_indicator->texture[1].data.lineart.y2 = h-1;
        a_focus_indicator->texture[2].data.lineart.x1 = w-1;
        a_focus_indicator->texture[2].data.lineart.y1 = h-1;
        a_focus_indicator->texture[2].data.lineart.x2 = 0;
        a_focus_indicator->texture[2].data.lineart.y2 = h-1;
        a_focus_indicator->texture[3].data.lineart.x1 = 0;
        a_focus_indicator->texture[3].data.lineart.y1 = wt-1;
        a_focus_indicator->texture[3].data.lineart.x2 = 0;
        a_focus_indicator->texture[3].data.lineart.y2 = h - wb;
        RrPaint(a_focus_indicator, [focus_indicator.right window],
                w, h);

        x = [[focus_cycle_target frame] area].x;
        y = [[focus_cycle_target frame] area].y +
            [[focus_cycle_target frame] area].height - wb;
        w = [[focus_cycle_target frame] area].width;
        h = wb;

        XMoveResizeWindow(ob_display, [focus_indicator.bottom window],
                          x, y, w, h);
        a_focus_indicator->texture[0].data.lineart.x1 = 0;
        a_focus_indicator->texture[0].data.lineart.y1 = 0;
        a_focus_indicator->texture[0].data.lineart.x2 = 0;
        a_focus_indicator->texture[0].data.lineart.y2 = h-1;
        a_focus_indicator->texture[1].data.lineart.x1 = 0;
        a_focus_indicator->texture[1].data.lineart.y1 = h-1;
        a_focus_indicator->texture[1].data.lineart.x2 = w-1;
        a_focus_indicator->texture[1].data.lineart.y2 = h-1;
        a_focus_indicator->texture[2].data.lineart.x1 = w-1;
        a_focus_indicator->texture[2].data.lineart.y1 = h-1;
        a_focus_indicator->texture[2].data.lineart.x2 = w-1;
        a_focus_indicator->texture[2].data.lineart.y2 = 0;
        a_focus_indicator->texture[3].data.lineart.x1 = wl-1;
        a_focus_indicator->texture[3].data.lineart.y1 = 0;
        a_focus_indicator->texture[3].data.lineart.x2 = w - wr;
        a_focus_indicator->texture[3].data.lineart.y2 = 0;
        RrPaint(a_focus_indicator, [focus_indicator.bottom window],
                w, h);

        XMapWindow(ob_display, [focus_indicator.top window]);
        XMapWindow(ob_display, [focus_indicator.left window]);
        XMapWindow(ob_display, [focus_indicator.right window]);
        XMapWindow(ob_display, [focus_indicator.bottom window]);
    }
}

- (void) cycleForward: (BOOL) forward linear: (BOOL) linear
          interactive: (BOOL) interactive dialog: (BOOL) dialog
	            done: (BOOL) done cancel: (BOOL) cancel;
{
    static AZClient *first = nil;
    static AZClient *t = nil;
    static GList *order = NULL;
    GList *list;
    AZClient *ft = nil;
    AZScreen *screen = [AZScreen defaultScreen];
    BOOL use_clist = NO;

    if (interactive) {
        if (cancel) {
            focus_cycle_target = nil;
            goto done_cycle;
        } else if (done)
            goto done_cycle;

        if (!focus_order[[screen desktop]])
            goto done_cycle;

        if (!first) first = focus_client;

        if (linear) 
	{
	  use_clist = YES;
	  list = NULL;
	}
        else        
	{
	  use_clist = NO;
	  list = focus_order[[screen desktop]];
	}
    } else {
        if (!focus_order[[screen desktop]])
            goto done_cycle;
	use_clist = YES;
	list = NULL;
    }
    if (!focus_cycle_target) focus_cycle_target = focus_client;

    if (use_clist)
    {
      AZClientManager *cManager = [AZClientManager defaultManager];
      int c_start = NSNotFound, c_index = NSNotFound;
      int count = 0;
      int temp = [cManager indexOfClient: focus_cycle_target];
      if (temp == NSNotFound) /* switched desktops or something ? */
      {
	count = [cManager count];
	if (count == 0) goto done_cycle;
        if (forward)
	{
          c_start = c_index = count-1;
	}
	else
	{
	  c_start = c_index = 0;
	}
      }
      else
      {
        c_start = c_index = temp;
      }

      do {
        if (forward)
	{
	  c_index++;
	  if (c_index >= count) c_index = 0;
	}
	else
	{
	  c_index--;
	  if (c_index < 0) c_index = count-1;
	}

	ft = [cManager clientAtIndex: c_index];
	if ([self validFocusTarget: ft]) {
            if (interactive) {
	        if (ft != focus_cycle_target) { /* prevents flicker */
	            focus_cycle_target = ft;
		    [self cycleDrawIndicator];
	        }
		[self popupCycle: ft show: dialog];
	        return;
	    } else if (ft != focus_cycle_target) {
	        focus_cycle_target = ft;
	        done = TRUE;
	        break;
	    }
        }
      } while (c_index != c_start);
    }
    else
    {
      GList *it, *start;
      start = it = g_list_find(list, focus_cycle_target);
      if (!start) /* switched desktops or something? */
          start = it = forward ? g_list_last(list) : g_list_first(list);
      if (!start) goto done_cycle;

      do {
          if (forward) {
              it = it->next;
              if (it == NULL) it = g_list_first(list);
          } else {
              it = it->prev;
              if (it == NULL) it = g_list_last(list);
          }
          ft = ((AZClient *)(it->data));
          if ([self validFocusTarget: ft]) {
              if (interactive) {
                  if (ft != focus_cycle_target) { /* prevents flicker */
                      focus_cycle_target = ft;
		      [self cycleDrawIndicator];
                  }
		  [self popupCycle: ft show: dialog];
                  return;
              } else if (ft != focus_cycle_target) {
                  focus_cycle_target = ft;
                  done = TRUE;
                  break;
              }
          }
      } while (it != start);
    }

done_cycle:
    if (done && focus_cycle_target)
	[focus_cycle_target activateHere: NO];

    t = nil;
    first = nil;
    focus_cycle_target = nil;
    g_list_free(order);
    order = NULL;

    if (interactive) {
	[self cycleDrawIndicator];
	[self popupCycle: ft show: NO];
    }

    return;
}

- (void) directionalCycle: (ObDirection) dir interactive: (BOOL) interactive
                 dialog: (BOOL) dialog done: (BOOL) done cancel: (BOOL) cancel
{
    static AZClient *first = nil;
    AZClient *ft = nil;
    AZScreen *screen = [AZScreen defaultScreen];

    if (!interactive)
        return;

    if (cancel) {
        focus_cycle_target = nil;
        goto done_cycle;
    } else if (done)
        goto done_cycle;

    if (!focus_order[[screen desktop]])
        goto done_cycle;

    if (!first) first = focus_client;
    if (!focus_cycle_target) focus_cycle_target = focus_client;

    if (focus_cycle_target)
	ft = [focus_cycle_target findDirectional: dir];
    else {
        GList *it;

        for (it = focus_order[[screen desktop]]; it; it = g_list_next(it))
            if ([self validFocusTarget: ((AZClient *)(it->data))])
                ft = (AZClient *)(it->data);
    }
        
    if (ft) {
        if (ft != focus_cycle_target) {/* prevents flicker */
            focus_cycle_target = ft;
	    [self cycleDrawIndicator];
        }
    }
    if (focus_cycle_target) {
	[self popupCycle: focus_cycle_target show: dialog];
        if (dialog)
            return;
    }


done_cycle:
    if (done && focus_cycle_target)
	[focus_cycle_target activateHere: NO];

    first = nil;
    focus_cycle_target = nil;

    [self cycleDrawIndicator];
    [self popupCycle: ft show: NO];

    return;
}

- (void) focusOrderAdd: (AZClient *) c
{
    guint d, i;
    unsigned int count = [[AZScreen defaultScreen] numberOfDesktops];

    if ([c iconic])
	[self focusOrderToTop: c];
    else {
        d = [c desktop];
        if (d == DESKTOP_ALL) {
            for (i = 0; i < count; ++i) {
                g_assert(!g_list_find(focus_order[i], c));
                if (focus_order[i] && [((AZClient*)focus_order[i]->data) iconic])
                    focus_order[i] = g_list_insert(focus_order[i], c, 0);
                else
                    focus_order[i] = g_list_insert(focus_order[i], c, 1);
            }
        } else {
            g_assert(!g_list_find(focus_order[d], c));
            if (focus_order[d] && [((AZClient*)focus_order[d]->data) iconic])
                focus_order[d] = g_list_insert(focus_order[d], c, 0);
            else
                focus_order[d] = g_list_insert(focus_order[d], c, 1);
        }
    }
}

- (void) focusOrderRemove: (AZClient *) c
{
    guint d, i;
    unsigned int count = [[AZScreen defaultScreen] numberOfDesktops];

    d = [c desktop];
    if (d == DESKTOP_ALL) {
        for (i = 0; i < count; ++i)
            focus_order[i] = g_list_remove(focus_order[i], c);
    } else
        focus_order[d] = g_list_remove(focus_order[d], c);
}

- (void) focusOrderToTop: (AZClient *) c
{
    guint d, i;
    unsigned int count = [[AZScreen defaultScreen] numberOfDesktops];

    d = [c desktop];
    if (d == DESKTOP_ALL) {
        for (i = 0; i < count; ++i)
            [self toTop: c desktop: i];
    } else
	[self toTop: c desktop: d];
}

- (void) focusOrderToBottom: (AZClient *) c
{
    guint d, i;
    unsigned int count = [[AZScreen defaultScreen] numberOfDesktops];

    d = [c desktop];
    if (d == DESKTOP_ALL) {
        for (i = 0; i < count; ++i)
	    [self toBottom: c desktop: i];
    } else
	[self toBottom: c desktop: d];
}

/* accessories */
- (void) set_focus_client: (AZClient *) f { focus_client = f; }
- (void) set_focus_hilite: (AZClient *) f { focus_hilite = f; }
- (void) set_focus_cycle_target: (AZClient *) f { focus_cycle_target = f; }
- (void) set_focus_order: (GList **) f { focus_order = f; }
- (AZClient *) focus_client { return focus_client; }
- (AZClient *) focus_hilite { return focus_hilite; }
- (AZClient *) focus_cycle_target { return focus_cycle_target; }
- (GList **) focus_order { return focus_order; }

+ (AZFocusManager *) defaultManager
{
  if (sharedInstance == nil)
  {
    sharedInstance = [[AZFocusManager alloc] init];
  }
  return sharedInstance;
}

@end

@implementation AZFocusManager (AZPrivate)

- (void) pushToTop: (AZClient *) client
{
    guint desktop;

    desktop = [client desktop];
    if (desktop == DESKTOP_ALL) desktop = [[AZScreen defaultScreen] desktop];
    focus_order[desktop] = g_list_remove(focus_order[desktop], client);
    focus_order[desktop] = g_list_prepend(focus_order[desktop], client);
}

/* finds the first transient that isn't 'skip' and ensure's that client_normal
 is true for it */
- (AZClient *) findTransientRecursive: (AZClient *) c : (AZClient *) top
                                     : (AZClient *) skip
{
    AZClient *ret, *temp;

    int j, jcount = [[c transients] count];
    for (j = 0; j < jcount; j++) {
	temp = [[c transients] objectAtIndex: j];
	if (temp == top) return nil;
	ret = [self findTransientRecursive: temp : top : skip];
	if (ret && ret != skip && [ret normal]) return ret;
	if (temp != skip && [temp normal]) return temp;
    }
    return nil;
}

- (AZClient *) fallbackTransient: (AZClient *) top : (AZClient *) old
{
    AZClient *target = [self findTransientRecursive: top : top : old];
    if (!target) {
        /* make sure client_normal is true always */
	if (![top normal])
            return nil;
        target = top; /* no transient, keep the top */
    }
    if ([target canFocus])
        return target;
    else
        return nil;
}

- (void) popupCycle: (AZClient *) c show: (BOOL) show
{
    if (!show) {
	[focus_cycle_popup hide];
    } else {
        Rect *a;
        AZClient *p = c;
        gchar *title = NULL;

	a = [[AZScreen defaultScreen] physicalAreaOfMonitor: 0];
	[focus_cycle_popup positionWithGravity: CenterGravity
                                             x: a->x + a->width / 2 
			                     y: a->y + a->height / 2];
        /* XXX the size and the font extents need to be related on some level
         */
	[focus_cycle_popup sizeWithWidth: POPUP_WIDTH height: POPUP_HEIGHT];

        /* use the transient's parent's title/icon */
        while ([p transient_for] && [p transient_for] != OB_TRAN_GROUP)
            p = [p transient_for];

        if (p != c && !strcmp("", ([c iconic] ? [c icon_title] : [c title])))
            title = g_strdup([p iconic] ? [p icon_title] : [p title]);
	  [focus_cycle_popup showText: (title ? title : ([c iconic] ? [c icon_title] : [c title]))
		                 icon: [p iconWithWidth: 48 height: 48]];
        g_free(title);
    }
}

- (BOOL) validFocusTarget: (AZClient *) ft
{
    /* we don't use client_can_focus here, because that doesn't let you
       focus an iconic window, but we want to be able to, so we just check
       if the focus flags on the window allow it, and its on the current
       desktop */
    if (([ft type] == OB_CLIENT_TYPE_NORMAL ||
         [ft type] == OB_CLIENT_TYPE_DIALOG ||
         (![ft hasGroupSiblings] &&
          ([ft type] == OB_CLIENT_TYPE_TOOLBAR ||
           [ft type] == OB_CLIENT_TYPE_MENU ||
           [ft type] == OB_CLIENT_TYPE_UTILITY))) &&
        (([ft can_focus] || [ft focus_notify]) &&
         ![ft skip_taskbar] &&
         ([ft desktop] == [[AZScreen defaultScreen] desktop] || [ft desktop] == DESKTOP_ALL)) &&
        ft == [ft focusTarget])
        return YES;

    return NO;
}

- (void) toTop: (AZClient *) c desktop: (unsigned int) d
{
    focus_order[d] = g_list_remove(focus_order[d], c);
    if (![c iconic]) {
        focus_order[d] = g_list_prepend(focus_order[d], c);
    } else {
        GList *it;

        /* insert before first iconic window */
        for (it = focus_order[d];
             it && ![((AZClient*)it->data) iconic]; it = g_list_next(it));
        focus_order[d] = g_list_insert_before(focus_order[d], it, c);
    }
}

- (void) toBottom: (AZClient *) c desktop: (unsigned int) d
{
    focus_order[d] = g_list_remove(focus_order[d], c);
    if ([c iconic]) {
        focus_order[d] = g_list_append(focus_order[d], c);
    } else {
        GList *it;

        /* insert before first iconic window */
        for (it = focus_order[d];
             it && ![((AZClient*)it->data) iconic]; it = g_list_next(it));
        g_list_insert_before(focus_order[d], it, c);
    }
}

@end
