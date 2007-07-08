/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZClient+Resist.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   resist.c for the Openbox window manager
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
#import "AZStacking.h"
#import "AZClient+Resist.h"
#import "config.h"
#import "parse.h"

@implementation AZClient (AZResist)

- (void) resistMoveWindowsAtX: (int *) x y: (int *) y
{
    int l, t, r, b; /* requested edges */
    int cl, ct, cr, cb; /* current edges */
    int w, h; /* current size */
    AZClient *snapx = nil, *snapy = nil;
    AZStacking *stacking = [AZStacking stacking];
    int j, count = [stacking count];

    w = [[self frame] area].width;
    h = [[self frame] area].height;

    l = *x;
    t = *y;
    r = l + w - 1;
    b = t + h - 1;

    cl = RECT_LEFT([[self frame] area]);
    ct = RECT_TOP([[self frame] area]);
    cr = RECT_RIGHT([[self frame] area]);
    cb = RECT_BOTTOM([[self frame] area]);
    
    if (config_resist_win)
	for (j = 0; j < count; j++) 
	{
	    id <AZWindow> temp = [stacking windowAtIndex: j];
        AZClient *target;
        int tl, tt, tr, tb; /* 1 past the target's edges on each side */

        if (!WINDOW_IS_CLIENT(temp))
            continue;
        target = (AZClient *)temp;

        /* don't snap to self or non-visibles */
        if (![[target frame] visible] || target == self) continue; 

        /* don't snap to windows in layers beneath */
        if([target layer] < [self layer] && !config_resist_layers_below)
            continue;

        tl = RECT_LEFT([[target frame] area]) - 1;
        tt = RECT_TOP([[target frame] area]) - 1;
        tr = RECT_RIGHT([[target frame] area]) + 1;
        tb = RECT_BOTTOM([[target frame] area]) + 1;

        /* snapx and snapy ensure that the window snaps to the top-most
           window edge available, without going all the way from
           bottom-to-top in the stacking list
        */
        if (snapx == nil) 
		{
            if (ct < tb && cb > tt) 
			{
                if (cl >= tr && l < tr && l >= tr - config_resist_win)
                    *x = tr, snapx = target;
                else if (cr <= tl && r > tl &&
                         r <= tl + config_resist_win)
                    *x = tl - w + 1, snapx = target;
                if (snapx != nil) 
				{
                    /* try to corner snap to the window */
                    if (ct > tt && t <= tt &&
                        t > tt - config_resist_win)
                        *y = tt + 1, snapy = target;
                    else if (cb < tb && b >= tb &&
                             b < tb + config_resist_win)
                        *y = tb - h, snapy = target;
                }
            }
        }
        if (snapy == nil) 
		{
            if (cl < tr && cr > tl) 
			{
				/* This prevent window moved below another one which
				 * has strut.top. Other direction should not be affected. */
				int top_resist = config_resist_win;
				if ([target strut].top > 0)
				{
					top_resist += [target strut].top + [[self frame] innersize].top;
				}
                if (ct >= tb && t < tb && t >= tb - top_resist/*config_resist_win*/)
				{
                    *y = tb, snapy = target;
				}
                else if (cb <= tt && b > tt && b <= tt + /*top_resist*/config_resist_win)
				{
                    *y = tt - h + 1, snapy = target;
				}
                if (snapy != NULL) {
                    /* try to corner snap to the window */
                    if (cl > tl && l <= tl &&
                        l > tl - config_resist_win)
                        *x = tl + 1, snapx = target;
                    else if (cr < tr && r >= tr &&
                             r < tr + config_resist_win)
                        *x = tr - w, snapx = target;
                }
            }
        }

        if (snapx && snapy) break;
    }
}

- (void) resistMoveMonitorsAtX: (int *) x y: (int *) y;
{
    Rect *_area, *parea;
    unsigned int i;
    int l, t, r, b; /* requested edges */
    int al, at, ar, ab; /* screen area edges */
    int pl, pt, pr, pb; /* physical screen area edges */
    int cl, ct, cr, cb; /* current edges */
    int w, h; /* current size */
    AZScreen *screen = [AZScreen defaultScreen];

    w = [[self frame] area].width;
    h = [[self frame] area].height;

    l = *x;
    t = *y;
    r = l + w - 1;
    b = t + h - 1;

    cl = RECT_LEFT([[self frame] area]);
    ct = RECT_TOP([[self frame] area]);
    cr = RECT_RIGHT([[self frame] area]);
    cb = RECT_BOTTOM([[self frame] area]);
    
    if (config_resist_edge) 
	{
        for (i = 0; i < [screen numberOfMonitors]; ++i) 
		{
		    _area = [screen areaOfDesktop: [self desktop] monitor: i];
		    parea = [screen physicalAreaOfMonitor: i];

            if (!RECT_INTERSECTS_RECT(*parea, [[self frame] area]))
                continue;

            al = RECT_LEFT(*_area);
            at = RECT_TOP(*_area);
            ar = RECT_RIGHT(*_area);
            ab = RECT_BOTTOM(*_area);
            pl = RECT_LEFT(*parea);
            pt = RECT_TOP(*parea);
            pr = RECT_RIGHT(*parea);
            pb = RECT_BOTTOM(*parea);

            if (cl >= al && l < al && l >= al - config_resist_edge)
                *x = al;
            else if (cr <= ar && r > ar && r <= ar + config_resist_edge)
                *x = ar - w + 1;
            else if (cl >= pl && l < pl && l >= pl - config_resist_edge)
                *x = pl;
            else if (cr <= pr && r > pr && r <= pr + config_resist_edge)
                *x = pr - w + 1;

            if (ct >= at && t < at && t >= at - config_resist_edge)
                *y = at;
            else if (cb <= ab && b > ab && b < ab + config_resist_edge)
                *y = ab - h + 1;
            else if (ct >= pt && t < pt && t >= pt - config_resist_edge)
                *y = pt;
            else if (cb <= pb && b > pb && b < pb + config_resist_edge)
                *y = pb - h + 1;
        }
    }
}

- (void) resistSizeWindowsWithWidth: (int *) w height: (int *) h 
                            corner: (ObCorner) corn;
{
    AZClient *target; /* target */
    int l, t, r, b; /* my left, top, right and bottom sides */
    int dlt, drb; /* my destination left/top and right/bottom sides */
    int tl, tt, tr, tb; /* target's left, top, right and bottom bottom sides*/
    int incw, inch;
    AZClient *snapx = nil, *snapy = nil;
    AZStacking *stacking = [AZStacking stacking];
    int j, count = [stacking count];

    incw = [self size_inc].width;
    inch = [self size_inc].height;

    l = RECT_LEFT([[self frame] area]);
    r = RECT_RIGHT([[self frame] area]);
    t = RECT_TOP([[self frame] area]);
    b = RECT_BOTTOM([[self frame] area]);

    if (config_resist_win) {
	for (j = 0; j < count; j++) {
	    id <AZWindow> temp = [stacking windowAtIndex: j];
            if (!WINDOW_IS_CLIENT(temp))
                continue;
            target = (AZClient *)temp;

            /* don't snap to invisibles or ourself */
            if (![[target frame] visible] || target == self) continue;

            /* don't snap to windows in layers beneath */
            if([target layer] < [self layer] && !config_resist_layers_below)
                continue;

            tl = RECT_LEFT([[target frame] area]);
            tr = RECT_RIGHT([[target frame] area]);
            tt = RECT_TOP([[target frame] area]);
            tb = RECT_BOTTOM([[target frame] area]);

            if (snapx == nil) {
                /* horizontal snapping */
                if (t < tb && b > tt) {
                    switch (corn) {
                    case OB_CORNER_TOPLEFT:
                    case OB_CORNER_BOTTOMLEFT:
                        dlt = l;
                        drb = r + *w - [[self frame] area].width;
                        if (r < tl && drb >= tl && drb < tl + config_resist_win)
                            *w = tl - l, snapx = target;
                        break;
                    case OB_CORNER_TOPRIGHT:
                    case OB_CORNER_BOTTOMRIGHT:
                        dlt = l - *w + [[self frame] area].width;
                        drb = r;
                        if (l > tr && dlt <= tr && dlt > tr - config_resist_win)
                            *w = r - tr, snapx = target;
                        break;
                    }
                }
            }

            if (snapy == nil) {
                /* vertical snapping */
                if (l < tr && r > tl) {
                    switch (corn) {
                    case OB_CORNER_TOPLEFT:
                    case OB_CORNER_TOPRIGHT:
                        dlt = t;
                        drb = b + *h - [[self frame] area].height;
                        if (b < tt && drb >= tt && drb < tt + config_resist_win)
                            *h = tt - t, snapy = target;
                        break;
                    case OB_CORNER_BOTTOMLEFT:
                    case OB_CORNER_BOTTOMRIGHT:
                        dlt = t - *h + [[self frame] area].height;
                        drb = b;
                        if (t > tb && dlt <= tb && dlt > tb - config_resist_win)
                            *h = b - tb, snapy = target;
                        break;
                    }
                }
            }

            /* snapped both ways */
            if (snapx && snapy) break;
        }
    }
}

- (void) resistSizeMonitorsWithWidth: (int *) w height: (int *) h 
                              corner: (ObCorner) corn;
{
    int l, t, r, b; /* my left, top, right and bottom sides */
    int dlt, drb; /* my destination left/top and right/bottom sides */
    Rect *_area, *parea;
    int al, at, ar, ab; /* screen boundaries */ 
    int pl, pt, pr, pb; /* physical screen boundaries */
    int incw, inch;
    unsigned int i;
    AZScreen *screen = [AZScreen defaultScreen];

    l = RECT_LEFT([[self frame] area]);
    r = RECT_RIGHT([[self frame] area]);
    t = RECT_TOP([[self frame] area]);
    b = RECT_BOTTOM([[self frame] area]);

    incw = [self size_inc].width;
    inch = [self size_inc].height;

    for (i = 0; i < [screen numberOfMonitors]; ++i) {
	_area = [screen areaOfDesktop: [self desktop] monitor: i];
	parea = [screen physicalAreaOfMonitor: i];

        if (!RECT_INTERSECTS_RECT(*parea, [[self frame] area]))
            continue;

        /* get the screen boundaries */
        al = RECT_LEFT(*_area);
        at = RECT_TOP(*_area);
        ar = RECT_RIGHT(*_area);
        ab = RECT_BOTTOM(*_area);
        pl = RECT_LEFT(*parea);
        pt = RECT_TOP(*parea);
        pr = RECT_RIGHT(*parea);
        pb = RECT_BOTTOM(*parea);

        if (config_resist_edge) {
            /* horizontal snapping */
            switch (corn) {
            case OB_CORNER_TOPLEFT:
            case OB_CORNER_BOTTOMLEFT:
                dlt = l;
                drb = r + *w - [[self frame] area].width;
                if (r <= ar && drb > ar && drb <= ar + config_resist_edge)
                    *w = ar - l + 1;
                else if (r <= pr && drb > pr && drb <= pr + config_resist_edge)
                    *w = pr - l + 1;
                break;
            case OB_CORNER_TOPRIGHT:
            case OB_CORNER_BOTTOMRIGHT:
                dlt = l - *w + [[self frame] area].width;
                drb = r;
                if (l >= al && dlt < al && dlt >= al - config_resist_edge)
                    *w = r - al + 1;
                else if (l >= pl && dlt < pl && dlt >= pl - config_resist_edge)
                    *w = r - pl + 1;
                break;
            }

            /* vertical snapping */
            switch (corn) {
            case OB_CORNER_TOPLEFT:
            case OB_CORNER_TOPRIGHT:
                dlt = t;
                drb = b + *h - [[self frame] area].height;
                if (b <= ab && drb > ab && drb <= ab + config_resist_edge)
                    *h = ab - t + 1;
                else if (b <= pb && drb > pb && drb <= pb + config_resist_edge)
                    *h = pb - t + 1;
                break;
            case OB_CORNER_BOTTOMLEFT:
            case OB_CORNER_BOTTOMRIGHT:
                dlt = t - *h + [[self frame] area].height;
                drb = b;
                if (t >= at && dlt < at && dlt >= at - config_resist_edge)
                    *h = b - at + 1;
                else if (t >= pt && dlt < pt && dlt >= pt - config_resist_edge)
                    *h = b - pt + 1;
                break;
            }
        }
    }
}

@end
