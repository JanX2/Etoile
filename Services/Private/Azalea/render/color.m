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
    in->gc = XCreateGC([in->inst display], [in->inst rootWindow],
                       GCForeground | GCCapStyle, &gcv);
}

RrColor *RrColorParse(const AZInstance *inst, char *colorname)
{
    XColor xcol;

    if (colorname == NULL) 
	    NSLog(@"Internal Error: no colorname");
    /* get rgb values from colorname */

    xcol.red = 0;
    xcol.green = 0;
    xcol.blue = 0;
    xcol.pixel = 0;
    if (!XParseColor([inst display], [inst colormap], colorname, &xcol)) {
        NSLog(@"Warning: unable to parse color '%s'", colorname);
        return NULL;
    }
    return RrColorNew(inst, xcol.red >> 8, xcol.green >> 8, xcol.blue >> 8);
}

/*#define NO_COLOR_CACHE*/
#ifdef DEBUG
int id;
#endif

RrColor *RrColorNew(const AZInstance *inst, int r, int g, int b)
{
    /* this should be replaced with something far cooler */
    RrColor *out = NULL;
    XColor xcol;
    int key;

    key = (r << 24) + (g << 16) + (b << 8);
#ifndef NO_COLOR_CACHE
    if ((out = [[[inst colorHash] objectForKey: [NSNumber numberWithInt: key]] pointerValue])) {
        out->refcount++;
    } else {
#endif
        xcol.red = (r << 8) | r;
        xcol.green = (g << 8) | g;
        xcol.blue = (b << 8) | b;
        if (XAllocColor([inst display], [inst colormap], &xcol)) {
            out = calloc(sizeof(RrColor), 1);
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
	    [[inst colorHash] setObject: [NSValue valueWithPointer: out]
		              forKey: [NSNumber numberWithInt: out->key]];
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
            //g_assert(g_hash_table_lookup([c->inst colorHash], &c->key));
	    [[c->inst colorHash] removeObjectForKey: [NSNumber numberWithInt: c->key]];
#endif
            if (c->pixel) XFreeColors([c->inst display], [c->inst colormap],
                                      &c->pixel, 1, 0);
            if (c->gc) XFreeGC([c->inst display], c->gc);
            free(c);
        }
    }
}

void RrReduceDepth(const AZInstance *inst, RrPixel32 *data, XImage *im)
{
    int r, g, b;
    int x,y;
    RrPixel32 *p32 = (RrPixel32 *) im->data;
    RrPixel16 *p16 = (RrPixel16 *) im->data;
    unsigned char *p8 = (unsigned char *)im->data;
    switch (im->bits_per_pixel) {
    case 32:
        if (([inst redOffset] != RrDefaultRedOffset) ||
            ([inst blueOffset] != RrDefaultBlueOffset) ||
            ([inst greenOffset] != RrDefaultGreenOffset)) {
            for (y = 0; y < im->height; y++) {
                for (x = 0; x < im->width; x++) {
                    r = (data[x] >> RrDefaultRedOffset) & 0xFF;
                    g = (data[x] >> RrDefaultGreenOffset) & 0xFF;
                    b = (data[x] >> RrDefaultBlueOffset) & 0xFF;
                    p32[x] = (r << [inst redOffset])
                           + (g << [inst greenOffset])
                           + (b << [inst blueOffset]);
                }
                data += im->width;
                p32 += im->width;
            } 
        } else im->data = (char*) data;
        break;
    case 16:
        for (y = 0; y < im->height; y++) {
            for (x = 0; x < im->width; x++) {
                r = (data[x] >> RrDefaultRedOffset) & 0xFF;
                r = r >> [inst redShift];
                g = (data[x] >> RrDefaultGreenOffset) & 0xFF;
                g = g >> [inst greenShift];
                b = (data[x] >> RrDefaultBlueOffset) & 0xFF;
                b = b >> [inst blueShift];
                p16[x] = (r << [inst redOffset])
                       + (g << [inst greenOffset])
                       + (b << [inst blueOffset]);
            }
            data += im->width;
            p16 += im->bytes_per_line/2;
        }
        break;
    case 8:
        if([inst visual]->class == TrueColor) NSLog(@"Wrong depth");
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
        NSLog(@"Warning: your bit depth is currently unhandled\n");
    }
}

XColor *RrPickColor(const AZInstance *inst, int r, int g, int b) 
{
  r = (r & 0xff) >> (8-[inst pseudoBPC]);
  g = (g & 0xff) >> (8-[inst pseudoBPC]);
  b = (b & 0xff) >> (8-[inst pseudoBPC]);
  return &[inst pseudoColors][(r << (2*[inst pseudoBPC])) +
                               (g << (1*[inst pseudoBPC])) +
                               b];
}

static void swap_byte_order(XImage *im)
{
    int x, y, di;

    di = 0;
    for (y = 0; y < im->height; ++y) {
        for (x = 0; x < im->height; ++x) {
            char *c = &im->data[di + x * im->bits_per_pixel / 8];
            char t;

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
                NSLog(@"Warning: Your bit depth is currently unhandled");
            }
        }
        di += im->bytes_per_line;
    }

    if (im->byte_order == LSBFirst)
        im->byte_order = MSBFirst;
    else
        im->byte_order = LSBFirst;
}

void RrIncreaseDepth(const AZInstance *inst, RrPixel32 *data, XImage *im)
{
    int r, g, b;
    int x,y;
    RrPixel32 *p32 = (RrPixel32 *) im->data;
    RrPixel16 *p16 = (RrPixel16 *) im->data;
    unsigned char *p8 = (unsigned char *)im->data;

    if (im->byte_order != LSBFirst)
        swap_byte_order(im);

    switch (im->bits_per_pixel) {
    case 32:
        for (y = 0; y < im->height; y++) {
            for (x = 0; x < im->width; x++) {
                r = (p32[x] >> [inst redOffset]) & 0xff;
                g = (p32[x] >> [inst greenOffset]) & 0xff;
                b = (p32[x] >> [inst blueOffset]) & 0xff;
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
                r = (p16[x] & [inst redMask]) >>
                    [inst redOffset] << [inst redShift];
                g = (p16[x] & [inst greenMask]) >>
                    [inst greenOffset] << [inst greenShift];
                b = (p16[x] & [inst blueMask]) >>
                    [inst blueOffset] << [inst blueShift];
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
        NSLog(@"Warning: this image bit depth is currently unhandled");
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
