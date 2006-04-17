/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZClient+Place.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   place.c for the Openbox window manager
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

#import "AZScreen.h"
#import "AZDock.h"
#import "AZGroup.h"
#import "AZClient+Place.h"
#import "AZFocusManager.h"
#import "config.h"

static Rect* pick_head(AZClient *c)
{
  AZScreen *screen = [AZScreen defaultScreen];
    /* try direct parent first */
    if ([c transient_for] && [c transient_for] != OB_TRAN_GROUP) {
	return [screen areaOfDesktop: [c desktop]
		       monitor: [[c transient_for] monitor]];
    }

    /* more than one guy in his group (more than just him) */
    if ([c hasGroupSiblings]) {
        /* try on the client's desktop */
        int i, count = [[[c group] members] count];
	for (i = 0; i < count; i++) {
	  AZClient *itc = [[c group] memberAtIndex: i];
            if (itc != c &&
                ([itc desktop] == [c desktop] ||
                 [itc desktop] == DESKTOP_ALL || [c desktop] == DESKTOP_ALL))
	    {
		return [screen areaOfDesktop: [c desktop]
			       monitor: [itc monitor]];
	    }
        }

        /* try on all desktops */
        count = [[[c group] members] count];
	for (i = 0; i < count; i++) {
	  AZClient *itc = [[c group] memberAtIndex: i];
            if (itc != c)
	    {
		return [screen areaOfDesktop: [c desktop]
			       monitor: [itc monitor]];
	    }
        }
    }

    return NULL;
}

static BOOL place_random(AZClient *client, int *x, int *y)
{
    int l, r, t, b;
    Rect *area;

    area = pick_head(client);
    if (!area)
    {
	AZScreen *screen = [AZScreen defaultScreen];
	area = [screen areaOfDesktop: [client desktop]
		       monitor: g_random_int_range(0, [screen numberOfMonitors])];
    }

    l = area->x;
    t = area->y;
    r = area->x + area->width - [[client frame] area].width;
    b = area->y + area->height - [[client frame] area].height;

    if (r > l) *x = g_random_int_range(l, r + 1);
    else       *x = 0;
    if (b > t) *y = g_random_int_range(t, b + 1);
    else       *y = 0;

    return YES;
}

static GSList* area_add(GSList *list, Rect *a)
{
    Rect *r = g_new(Rect, 1);
    *r = *a;
    return g_slist_prepend(list, r);
}

static GSList* area_remove(GSList *list, Rect *a)
{
    GSList *sit;
    GSList *result = NULL;

    for (sit = list; sit; sit = g_slist_next(sit)) {
        Rect *r = sit->data;

        if (!RECT_INTERSECTS_RECT(*r, *a)) {
            result = g_slist_prepend(result, r);
            r = NULL; /* dont free it */
        } else {
            Rect isect, extra;

            /* Use an intersection of a and r to determine the space
               around r that we can use.

               NOTE: the spaces calculated can overlap.
            */

            RECT_SET_INTERSECTION(isect, *r, *a);

            if (RECT_LEFT(isect) > RECT_LEFT(*r)) {
                RECT_SET(extra, r->x, r->y,
                         RECT_LEFT(isect) - r->x, r->height);
                result = area_add(result, &extra);
            }

            if (RECT_TOP(isect) > RECT_TOP(*r)) {
                RECT_SET(extra, r->x, r->y,
                         r->width, RECT_TOP(isect) - r->y + 1);
                result = area_add(result, &extra);
            }

            if (RECT_RIGHT(isect) < RECT_RIGHT(*r)) {
                RECT_SET(extra, RECT_RIGHT(isect) + 1, r->y,
                         RECT_RIGHT(*r) - RECT_RIGHT(isect), r->height);
                result = area_add(result, &extra);
            }

            if (RECT_BOTTOM(isect) < RECT_BOTTOM(*r)) {
                RECT_SET(extra, r->x, RECT_BOTTOM(isect) + 1,
                         r->width, RECT_BOTTOM(*r) - RECT_BOTTOM(isect));
                result = area_add(result, &extra);
            }
        }

        g_free(r);
    }
    g_slist_free(list);
    return result;
}

static int area_cmp(gconstpointer p1, gconstpointer p2, gpointer data)
{
    AZClient *c = data;
    Rect temp = [[c frame] area];
    Rect *carea = &temp;
    const Rect *a1 = p1, *a2 = p2;
    BOOL diffhead = NO;
    unsigned int i;
    Rect *a;
    AZScreen *screen = [AZScreen defaultScreen];

    for (i = 0; i < [screen numberOfMonitors]; ++i) {
	a = [screen physicalAreaOfMonitor: i];
        if (RECT_CONTAINS(*a, a1->x, a1->y) &&
            !RECT_CONTAINS(*a, a2->x, a2->y))
        {
            diffhead = YES;
            break;
        }
    }

    /* has to be more than me in the group */
    if (diffhead && [c hasGroupSiblings]) {
        unsigned int *num, most;

        /* find how many clients in the group are on each monitor, use the
           monitor with the most in it */
        num = g_new0(unsigned int, [screen numberOfMonitors]);
        int i, count = [[[c group] members] count];
	for (i = 0; i < count; i++) {
	  AZClient *data = [[c group] memberAtIndex: i];
          if (data != c)
                ++num[[data monitor]];
	}
        most = 0;
        for (i = 1; i < [screen numberOfMonitors]; ++i)
            if (num[i] > num[most])
                most = i;

	a = [screen physicalAreaOfMonitor: most];
        if (RECT_CONTAINS(*a, a1->x, a1->y))
            return -1;
        if (RECT_CONTAINS(*a, a2->x, a2->y))
            return 1;
    }

    return MIN((a1->width - carea->width), (a1->height - carea->height)) -
        MIN((a2->width - carea->width), (a2->height - carea->height));
}

typedef enum
{
    SMART_FULL,
    SMART_GROUP,
    SMART_FOCUSED
} ObSmartType;

#define SMART_IGNORE(placer, c) \
    (placer == c || ![[c frame] visible] || [c shaded] || ![c normal] || \
     ([c desktop] != DESKTOP_ALL && \
      [c desktop] != ([placer desktop] == DESKTOP_ALL ? \
                     ([[AZScreen defaultScreen] desktop]) : [placer desktop])))

static BOOL place_smart(AZClient *client, int *x, int *y,
                            ObSmartType type)
{
    unsigned int i;
    BOOL ret = NO;
    GSList *spaces = NULL, *sit;
    AZScreen *screen = [AZScreen defaultScreen];
    AZStacking *stacking = [AZStacking stacking];
    int j, index = NSNotFound, count = [stacking count];
    id <AZWindow> temp;

    for (i = 0; i < [screen numberOfMonitors]; ++i)
        spaces = area_add(spaces, [screen areaOfDesktop: [client desktop]
			            monitor: i]);

    /* stay out from under windows in higher layers */
    for (j = 0; j < count; j++) {
	temp = [stacking windowAtIndex: j];
        AZClient *c = nil;

        if (WINDOW_IS_CLIENT(temp)) {
            c = (AZClient *)temp;
            if ([c fullscreen])
                continue;
        } else
            continue;

        if ([c layer] > [client layer]) {
            if (!SMART_IGNORE(client, c)) {
		Rect temp = [[c frame] area];
                spaces = area_remove(spaces, &temp);
		[[c frame] setArea: temp];
	    }
        } else {
	    index = j;
            break;
	}
    }

    if ([client type] == OB_CLIENT_TYPE_NORMAL) {
        if (type == SMART_FULL || type == SMART_FOCUSED) {
            BOOL found_foc = NO, stop = NO;
            AZClient *foc;
	    unsigned int d = ([client desktop] == DESKTOP_ALL ? [screen desktop] : [client desktop]);

	    // foc can be nil.
	    foc = [[AZFocusManager defaultManager] focusOrder: 0 inScreen: d];

	    for (j = index; j < count && !stop; j++) {
		temp = [stacking windowAtIndex: j];
                AZClient *c;

                if (WINDOW_IS_CLIENT(temp)) {
                    c = (AZClient *)temp;
                    if ([c fullscreen])
                        continue;
                } else
                    continue;

                if (!SMART_IGNORE(client, c)) {
                    if (type == SMART_FOCUSED)
                        if (found_foc)
                            stop = YES;
                    if (!stop) {
			Rect temp = [[c frame] area];
                        spaces = area_remove(spaces, &temp);
			[[c frame] setArea: temp];
		    }
                }

                if (c == foc)
                    found_foc = YES;
            }
        } else if (type == SMART_GROUP) {
            /* has to be more than me in the group */
            if (![client hasGroupSiblings])
                return NO;

            int i, count = [[[client group] members] count];
	    for (i = 0; i < count; i++) {
	      AZClient *c = [[client group] memberAtIndex: i];
              if (!SMART_IGNORE(client, c)) {
		    Rect temp = [[c frame] area];
                    spaces = area_remove(spaces, &temp);
		    [[c frame] setArea: temp];
	      }
            }
        } else
            g_assert_not_reached();
    }

    spaces = g_slist_sort_with_data(spaces, area_cmp, client);

    for (sit = spaces; sit; sit = g_slist_next(sit)) {
        Rect *r = sit->data;

        if (!ret) {
            if (r->width >= [[client frame] area].width &&
                r->height >= [[client frame] area].height) {
                ret = YES;
                if ([client type] == OB_CLIENT_TYPE_DIALOG ||
                    type != SMART_FULL)
                {
                    *x = r->x + (r->width - [[client frame] area].width) / 2;
                    *y = r->y + (r->height - [[client frame] area].height) / 2;
                } else {
                    *x = r->x;
                    *y = r->y;
                }
            }
        }

        g_free(r);
    }
    g_slist_free(spaces);

    return ret;
}

static BOOL place_under_mouse(AZClient *client, int *x, int *y)
{
    unsigned int i;
    int l, r, t, b;
    int px, py;
    Rect *area;
    AZScreen *screen = [AZScreen defaultScreen];

    [screen pointerPosAtX: &px y: &py];

    for (i = 0; i < [screen numberOfMonitors]; ++i) {
	area = [screen areaOfDesktop: [client desktop]
		       monitor: i];
        if (RECT_CONTAINS(*area, px, py))
            break;
    }
    if (i == [screen numberOfMonitors])
	area = [screen areaOfDesktop: [client desktop]
		       monitor: 0];

    l = area->x;
    t = area->y;
    r = area->x + area->width - [[client frame] area].width;
    b = area->y + area->height - [[client frame] area].height;

    *x = px - [client area].width / 2 - [[client frame] size].left;
    *x = MIN(MAX(*x, l), r);
    *y = py - [client area].height / 2 - [[client frame] size].top;
    *y = MIN(MAX(*y, t), b);

    return YES;
}

static BOOL place_transient(AZClient *client, int *x, int *y)
{
    if ([client transient_for]) {
        if ([client transient_for] != OB_TRAN_GROUP) {
            AZClient *c = client;
            AZClient *p = [client transient_for];
            *x = ([[p frame] area].width - [[c frame] area].width) / 2 +
                [[p frame] area].x;
            *y = ([[p frame] area].height - [[c frame] area].height) / 2 +
                [[p frame] area].y;
            return YES;
        } else {
            BOOL first = YES;
            int l, r, t, b;
            int i, count = [[[client group] members] count];
	    for (i = 0; i < count; i++) {
	      AZClient *m = [[client group] memberAtIndex: i];
                if (!(m == client || [m transient_for])) {
                    if (first) {
                        l = RECT_LEFT([[m frame] area]);
                        t = RECT_TOP([[m frame] area]);
                        r = RECT_RIGHT([[m frame] area]);
                        b = RECT_BOTTOM([[m frame] area]);
                        first = NO;
                    } else {
                        l = MIN(l, RECT_LEFT([[m frame] area]));
                        t = MIN(t, RECT_TOP([[m frame] area]));
                        r = MAX(r, RECT_RIGHT([[m frame] area]));
                        b = MAX(b, RECT_BOTTOM([[m frame] area]));
                    }
                }
            }
            if (!first) {
                *x = ((r + 1 - l) - [[client frame] area].width) / 2 + l; 
                *y = ((b + 1 - t) - [[client frame] area].height) / 2 + t;
                return YES;
            }
        }
    }
    return NO;
}

@implementation AZClient (AZPlace)

- (void) placeAtX: (int *) x y: (int *) y
{
    if ([self positioned])
        return;
    if (place_transient(self , x, y)             ||
        ((config_place_policy == OB_PLACE_POLICY_MOUSE) ?
         place_under_mouse(self , x, y) :
         place_smart(self , x, y, SMART_FULL)    ||
         place_smart(self , x, y, SMART_GROUP)   ||
         place_smart(self , x, y, SMART_FOCUSED) ||
         place_random(self, x, y)))
    {
        /* get where the client should be */
	[[self frame] frameGravityAtX: x y: y];
    } else
        g_assert_not_reached(); /* the last one better succeed */
}

@end
