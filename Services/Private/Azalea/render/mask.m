/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   mask.c for the Openbox window manager
   Copyright (c) 2003        Ben Jansens
   Copyright (c) 2003        Derek Foreman

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

#include "render.h"
#include "color.h"
#include "mask.h"
#import "instance.h"

RrPixmapMask *RrPixmapMaskNew(const AZInstance *inst,
                              int w, int h, const char *data)
{
    RrPixmapMask *m = calloc(sizeof(RrPixmapMask), 1);
    m->inst = inst;
    m->width = w;
    m->height = h;
    /* round up to nearest byte */
    m->data = calloc(sizeof(char), (w + 7) / 8 * h);
    memcpy(m->data, data, (w + 7) / 8 * h);
//    m->data = g_memdup(data, (w + 7) / 8 * h);
    m->mask = XCreateBitmapFromData([inst display], [inst rootWindow],
                                    data, w, h);
    return m;
}

void RrPixmapMaskFree(RrPixmapMask *m)
{
    if (m) {
        XFreePixmap([m->inst display], m->mask);
        free(m->data);
        free(m);
    }
}

void RrPixmapMaskDraw(Pixmap p, const RrTextureMask *m, const RrRect *area)
{
    int x, y;
    if (m->mask == None) return; /* no mask given */

    /* set the clip region */
    x = area->x + (area->width - m->mask->width) / 2;
    y = area->y + (area->height - m->mask->height) / 2;

    if (x < 0) x = 0;
    if (y < 0) y = 0;

    XSetClipMask([m->mask->inst display], RrColorGC(m->color), m->mask->mask);
    XSetClipOrigin([m->mask->inst display], RrColorGC(m->color), x, y);

    /* fill in the clipped region */
    XFillRectangle([m->mask->inst display], p, RrColorGC(m->color), x, y,
                   x + m->mask->width, y + m->mask->height);

    /* unset the clip region */
    XSetClipMask([m->mask->inst display], RrColorGC(m->color), None);
    XSetClipOrigin([m->mask->inst display], RrColorGC(m->color), 0, 0);
}

RrPixmapMask *RrPixmapMaskCopy(const RrPixmapMask *src)
{
    RrPixmapMask *m = calloc(sizeof(RrPixmapMask), 1);
    m->inst = src->inst;
    m->width = src->width;
    m->height = src->height;
    /* round up to nearest byte */
    m->data = calloc(sizeof(char), (src->width + 7) / 8 * src->height);
    memcpy(m->data, src->data, (src->width + 7) / 8 * src->height);
//    m->data = g_memdup(src->data, (src->width + 7) / 8 * src->height);
    m->mask = XCreateBitmapFromData([m->inst display], [m->inst rootWindow],
                                    m->data, m->width, m->height);
    return m;
}
