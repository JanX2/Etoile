/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   color.c for the Openbox window manager
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
#include "instance.h"

#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <string.h>

void RrColorAllocateGC(RrColor *in)
{
    XGCValues gcv;

    gcv.foreground = in->pixel;
    gcv.cap_style = CapProjecting;
    in->gc = XCreateGC(RrDisplay(in->inst),
                       RrRootWindow(in->inst),
                       GCForeground | GCCapStyle, &gcv);
}

RrColor *RrColorParse(const RrInstance *inst, gchar *colorname)
{
    XColor xcol;

    if (colorname == NULL) 
	    NSLog(@"Internal Error: no colorname");
    /* get rgb values from colorname */

    xcol.red = 0;
    xcol.green = 0;
    xcol.blue = 0;
    xcol.pixel = 0;
    if (!XParseColor(RrDisplay(inst), RrColormap(inst), colorname, &xcol)) {
        NSLog(@"Warning: unable to parse color '%s'", colorname);
        return NULL;
    }
    return RrColorNew(inst, xcol.red >> 8, xcol.green >> 8, xcol.blue >> 8);
}

/*#define NO_COLOR_CACHE*/
#ifdef DEBUG
int id;
#endif

RrColor *RrColorNew(const RrInstance *inst, int r, int g, int b)
{
    /* this should be replaced with something far cooler */
    RrColor *out = NULL;
    XColor xcol;
    int key;

    key = (r << 24) + (g << 16) + (b << 8);
#ifndef NO_COLOR_CACHE
    if ((out = g_hash_table_lookup(RrColorHash(inst), &key))) {
        out->refcount++;
    } else {
#endif
        xcol.red = (r << 8) | r;
        xcol.green = (g << 8) | g;
        xcol.blue = (b << 8) | b;
        if (XAllocColor(RrDisplay(inst), RrColormap(inst), &xcol)) {
            out = g_new(RrColor, 1);
            out->inst = inst;
            out->r = xcol.red >> 8;
            out->g = xcol.green >> 8;
            out->b = xcol.blue >> 8;
            out->gc = None;
            out->pixel = xcol.pixel;
            out->key = key;
            out->refcount = 1;
#ifdef DEBUG
            out->id = id++;
#endif
#ifndef NO_COLOR_CACHE
            g_hash_table_insert(RrColorHash(inst), &out->key, out);
        }
#endif
    }
    return out;
}

void RrColorFree(RrColor *c)
{
    if (c) {
        if (--c->refcount < 1) {
#ifndef NO_COLOR_CACHE
            g_assert(g_hash_table_lookup(RrColorHash(c->inst), &c->key));
            g_hash_table_remove(RrColorHash(c->inst), &c->key);
#endif
            if (c->pixel) XFreeColors(RrDisplay(c->inst), RrColormap(c->inst),
                                      &c->pixel, 1, 0);
            if (c->gc) XFreeGC(RrDisplay(c->inst), c->gc);
            g_free(c);
        }
    }
}

void RrReduceDepth(const RrInstance *inst, RrPixel32 *data, XImage *im)
{
    int r, g, b;
    int x,y;
    RrPixel32 *p32 = (RrPixel32 *) im->data;
    RrPixel16 *p16 = (RrPixel16 *) im->data;
    guchar *p8 = (guchar *)im->data;
    switch (im->bits_per_pixel) {
    case 32:
        if ((RrRedOffset(inst) != RrDefaultRedOffset) ||
            (RrBlueOffset(inst) != RrDefaultBlueOffset) ||
            (RrGreenOffset(inst) != RrDefaultGreenOffset)) {
            for (y = 0; y < im->height; y++) {
                for (x = 0; x < im->width; x++) {
                    r = (data[x] >> RrDefaultRedOffset) & 0xFF;
                    g = (data[x] >> RrDefaultGreenOffset) & 0xFF;
                    b = (data[x] >> RrDefaultBlueOffset) & 0xFF;
                    p32[x] = (r << RrRedOffset(inst))
                           + (g << RrGreenOffset(inst))
                           + (b << RrBlueOffset(inst));
                }
                data += im->width;
                p32 += im->width;
            } 
        } else im->data = (gchar*) data;
        break;
    case 16:
        for (y = 0; y < im->height; y++) {
            for (x = 0; x < im->width; x++) {
                r = (data[x] >> RrDefaultRedOffset) & 0xFF;
                r = r >> RrRedShift(inst);
                g = (data[x] >> RrDefaultGreenOffset) & 0xFF;
                g = g >> RrGreenShift(inst);
                b = (data[x] >> RrDefaultBlueOffset) & 0xFF;
                b = b >> RrBlueShift(inst);
                p16[x] = (r << RrRedOffset(inst))
                       + (g << RrGreenOffset(inst))
                       + (b << RrBlueOffset(inst));
            }
            data += im->width;
            p16 += im->bytes_per_line/2;
        }
        break;
    case 8:
        g_assert(RrVisual(inst)->class != TrueColor);
        for (y = 0; y < im->height; y++) {
            for (x = 0; x < im->width; x++) {
                p8[x] = RrPickColor(inst,
                                    data[x] >> RrDefaultRedOffset,
                                    data[x] >> RrDefaultGreenOffset,
                                    data[x] >> RrDefaultBlueOffset)->pixel;
            }
            data += im->width;
            p8 += im->bytes_per_line;
        }
        break;
    default:
        g_warning("your bit depth is currently unhandled\n");
    }
}

XColor *RrPickColor(const RrInstance *inst, int r, int g, int b) 
{
  r = (r & 0xff) >> (8-RrPseudoBPC(inst));
  g = (g & 0xff) >> (8-RrPseudoBPC(inst));
  b = (b & 0xff) >> (8-RrPseudoBPC(inst));
  return &RrPseudoColors(inst)[(r << (2*RrPseudoBPC(inst))) +
                               (g << (1*RrPseudoBPC(inst))) +
                               b];
}

static void swap_byte_order(XImage *im)
{
    int x, y, di;

    di = 0;
    for (y = 0; y < im->height; ++y) {
        for (x = 0; x < im->height; ++x) {
            gchar *c = &im->data[di + x * im->bits_per_pixel / 8];
            gchar t;

            switch (im->bits_per_pixel) {
            case 32:
                t = c[2];
                c[2] = c[3];
                c[3] = t;
            case 16:
                t = c[0];
                c[0] = c[1];
                c[1] = t;
            case 8:
            case 1:
                break;
            default:
                g_warning("Your bit depth is currently unhandled");
            }
        }
        di += im->bytes_per_line;
    }

    if (im->byte_order == LSBFirst)
        im->byte_order = MSBFirst;
    else
        im->byte_order = LSBFirst;
}

void RrIncreaseDepth(const RrInstance *inst, RrPixel32 *data, XImage *im)
{
    int r, g, b;
    int x,y;
    RrPixel32 *p32 = (RrPixel32 *) im->data;
    RrPixel16 *p16 = (RrPixel16 *) im->data;
    guchar *p8 = (guchar *)im->data;

    if (im->byte_order != LSBFirst)
        swap_byte_order(im);

    switch (im->bits_per_pixel) {
    case 32:
        for (y = 0; y < im->height; y++) {
            for (x = 0; x < im->width; x++) {
                r = (p32[x] >> RrRedOffset(inst)) & 0xff;
                g = (p32[x] >> RrGreenOffset(inst)) & 0xff;
                b = (p32[x] >> RrBlueOffset(inst)) & 0xff;
                data[x] = (r << RrDefaultRedOffset)
                    + (g << RrDefaultGreenOffset)
                    + (b << RrDefaultBlueOffset)
                    + (0xff << RrDefaultAlphaOffset);
            }
            data += im->width;
            p32 += im->bytes_per_line/4;
        }
        break;
    case 16:
        for (y = 0; y < im->height; y++) {
            for (x = 0; x < im->width; x++) {
                r = (p16[x] & RrRedMask(inst)) >>
                    RrRedOffset(inst) <<
                    RrRedShift(inst);
                g = (p16[x] & RrGreenMask(inst)) >>
                    RrGreenOffset(inst) <<
                    RrGreenShift(inst);
                b = (p16[x] & RrBlueMask(inst)) >>
                    RrBlueOffset(inst) <<
                    RrBlueShift(inst);
                data[x] = (r << RrDefaultRedOffset)
                    + (g << RrDefaultGreenOffset)
                    + (b << RrDefaultBlueOffset)
                    + (0xff << RrDefaultAlphaOffset);
            }
            data += im->width;
            p16 += im->bytes_per_line/2;
        }
        break;
    case 8:
        NSLog(@"Warning: this image bit depth is currently unhandled");
        break;
    case 1:
        for (y = 0; y < im->height; y++) {
            for (x = 0; x < im->width; x++) {
                if (!(((p8[x / 8]) >> (x % 8)) & 0x1))
                    data[x] = 0xff << RrDefaultAlphaOffset; /* black */
                else
                    data[x] = 0xffffffff; /* white */
            }
            data += im->width;
            p8 += im->bytes_per_line;
        }
        break;
    default:
        g_warning("this image bit depth is currently unhandled");
    }
}

int RrColorRed(const RrColor *c)
{
    return c->r;
}

int RrColorGreen(const RrColor *c)
{
    return c->g;
}

int RrColorBlue(const RrColor *c)
{
    return c->b;
}

unsigned long RrColorPixel(const RrColor *c)
{
    return c->pixel;
}

GC RrColorGC(RrColor *c)
{
    if (!c->gc)
        RrColorAllocateGC(c);
    return c->gc;
}
