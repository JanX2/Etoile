/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   render.c for the Openbox window manager
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

#include <X11/Xlib.h>
#include <X11/Xutil.h>

#include "render.h"
#include "gradient.h"
#include "font.h"
#include "mask.h"
#include "color.h"
#include "image.h"
#include "theme.h"
#import "instance.h"

#ifdef HAVE_STDLIB_H
#  include <stdlib.h>
#endif

@interface AZAppearance (AZPrivate)
- (void) pixelDataToPixmapWithX: (int) x y: (int) y width: (int) w height: (int) h;
@end

@implementation AZAppearance

- (void) paint: (Window) win width: (int) width height: (int) height
{
    int i, transferred = 0, sw;
    RrPixel32 *source, *dest;
    Pixmap oldp;
    RrRect tarea; /* area in which to draw textures */
    BOOL resized;

    if (width <= 0 || height <= 0) return;

    resized = (w != width || h != height);

    oldp = pixmap; /* save to free after changing the visible pixmap */
    pixmap = XCreatePixmap([inst display], [inst rootWindow],
                              width, height, [inst depth]);

    NSAssert(pixmap != None, @"Internal Error: pixmap is None");
    w = width;
    h = height;

    if (xftdraw != NULL)
        XftDrawDestroy(xftdraw);
    xftdraw = XftDrawCreate([inst display], pixmap,
                               [inst visual], [inst colormap]);
    NSAssert(xftdraw != NULL, @"No xftdraw is available");

    free(surface.pixel_data);
    surface.pixel_data = calloc(sizeof(RrPixel32), width * height);

    if (surface.grad == RR_SURFACE_PARENTREL) {
        NSAssert(surface.parent, @"No parent");
        NSAssert([surface.parent w], @"Width of parent is 0");

        sw = [surface.parent w];
        source = ([surface.parent surface].pixel_data +
                  surface.parentx + sw * surface.parenty);
        dest = surface.pixel_data;
        for (i = 0; i < h; i++, source += sw, dest += width) {
            memcpy(dest, source, width * sizeof(RrPixel32));
        }
    } else
	RrRender(self, width, height);

    {
        int l, t, r, b;
	[self marginsWithLeft: &l top: &t right: &r bottom: &b];
        RECT_SET(tarea, l, t, w - l - r, h - t - b); 
    }       

    for (i = 0; i < textures; i++) {
        switch (texture[i].type) {
        case RR_TEXTURE_NONE:
            break;
        case RR_TEXTURE_TEXT:
            if (!transferred) {
                transferred = 1;
                if (surface.grad != RR_SURFACE_SOLID)
		  [self pixelDataToPixmapWithX: 0 y: 0 width: width height: height];
            }
            if (xftdraw == NULL) {
                xftdraw = XftDrawCreate([inst display], pixmap, 
                                           [inst visual], [inst colormap]);
            }
            RrFontDraw(xftdraw, &(texture[i].data.text), &tarea);
            break;
        case RR_TEXTURE_LINE_ART:
            if (!transferred) {
                transferred = 1;
                if (surface.grad != RR_SURFACE_SOLID)
		  [self pixelDataToPixmapWithX: 0 y: 0 width: width height: height];
            }
            XDrawLine([inst display], pixmap,
                      RrColorGC(texture[i].data.lineart.color),
                      texture[i].data.lineart.x1,
                      texture[i].data.lineart.y1,
                      texture[i].data.lineart.x2,
                      texture[i].data.lineart.y2);
            break;
        case RR_TEXTURE_MASK:
            if (!transferred) {
                transferred = 1;
                if (surface.grad != RR_SURFACE_SOLID)
		  [self pixelDataToPixmapWithX: 0 y: 0 width: width height: height];
            }
            RrPixmapMaskDraw(pixmap, &(texture[i].data.mask), &tarea);
            break;
        case RR_TEXTURE_RGBA:
            NSAssert(!transferred, @"Internal Error: transferred");
            RrImageDraw(surface.pixel_data,
                        &(texture[i].data.rgba),
                        width, height,
                        &tarea);
        break;
        }
    }

    if (!transferred) {
        transferred = 1;
        if (surface.grad != RR_SURFACE_SOLID)
	  [self pixelDataToPixmapWithX: 0 y: 0 width: width height: height];
    }

    XSetWindowBackgroundPixmap([inst display], win, pixmap);
    XClearWindow([inst display], win);
    if (oldp) XFreePixmap([inst display], oldp);
}

- (id) initWithInstance: (const AZInstance *) _inst numberOfTextures: (int) numtex
{
  self = [super init];
  inst = _inst;
  textures = numtex;
  if (numtex) 
    texture = calloc(sizeof(RrTexture), numtex);

  return self;
}

- (id) copyWithZone: (NSZone *) zone
{
    AZAppearance *copy = [[AZAppearance allocWithZone: zone] initWithInstance: inst numberOfTextures: textures];

    RrSurface *spo, *spc;
    int i;

    spo = &surface;
    spc = [copy surfacePointer];
    spc->grad = spo->grad;
    spc->relief = spo->relief;
    spc->bevel = spo->bevel;
    if (spo->primary != NULL)
        spc->primary = RrColorNew([copy inst],
                                  spo->primary->r,
                                  spo->primary->g, 
                                  spo->primary->b);
    else spc->primary = NULL;

    if (spo->secondary != NULL)
        spc->secondary = RrColorNew([copy inst],
                                    spo->secondary->r,
                                    spo->secondary->g,
                                    spo->secondary->b);
    else spc->secondary = NULL;

    if (spo->border_color != NULL)
        spc->border_color = RrColorNew([copy inst],
                                       spo->border_color->r,
                                       spo->border_color->g,
                                       spo->border_color->b);
    else spc->border_color = NULL;

    if (spo->interlace_color != NULL)
        spc->interlace_color = RrColorNew([copy inst],
                                       spo->interlace_color->r,
                                       spo->interlace_color->g,
                                       spo->interlace_color->b);
    else spc->interlace_color = NULL;

    if (spo->bevel_dark != NULL)
        spc->bevel_dark = RrColorNew([copy inst],
                                     spo->bevel_dark->r,
                                     spo->bevel_dark->g,
                                     spo->bevel_dark->b);
    else spc->bevel_dark = NULL;

    if (spo->bevel_light != NULL)
        spc->bevel_light = RrColorNew([copy inst],
                                      spo->bevel_light->r,
                                      spo->bevel_light->g,
                                      spo->bevel_light->b);
    else spc->bevel_light = NULL;

    spc->interlaced = spo->interlaced;
    spc->border = spo->border;
    spc->parent = NULL;
    spc->parentx = spc->parenty = 0;
    spc->pixel_data = NULL;

    RrTexture *_temp = calloc(sizeof(RrTexture), textures);
    memcpy(_temp, texture, textures*sizeof(RrTexture));
    [copy set_texture: _temp];
//    [copy set_texture: g_memdup(texture, textures * sizeof(RrTexture))];
    for (i = 0; i < [copy textures]; ++i)
        if ([copy texture][i].type == RR_TEXTURE_RGBA) {
            [copy texture][i].data.rgba.cache = NULL;
        }
    [copy set_pixmap: None];
    [copy set_xftdraw: NULL];
    [copy set_w: 0];
    [copy set_h: 0];
    return copy;
}

- (void) dealloc
{
    int i;

    {
        RrSurface *p;
        if (pixmap != None) XFreePixmap([inst display], pixmap);
        if (xftdraw != NULL) XftDrawDestroy(xftdraw);
        for (i = 0; i < textures; ++i)
            if (texture[i].type == RR_TEXTURE_RGBA) {
                free(texture[i].data.rgba.cache);
                texture[i].data.rgba.cache = NULL;
            }
        if (textures)
            free(texture);
        p = &surface;
        RrColorFree(p->primary);
        RrColorFree(p->secondary);
        RrColorFree(p->border_color);
        RrColorFree(p->interlace_color);
        RrColorFree(p->bevel_dark);
        RrColorFree(p->bevel_light);
        free(p->pixel_data);

	[super dealloc];
    }
}

- (void) marginsWithLeft: (int *) l top: (int *) t 
                   right: (int *) r bottom: (int *) b
{
    *l = *t = *r = *b = 0;

    if (surface.grad != RR_SURFACE_PARENTREL) {
        if (surface.relief != RR_RELIEF_FLAT) {
            switch (surface.bevel) {
            case RR_BEVEL_1:
                *l = *t = *r = *b = 1;
                break;
            case RR_BEVEL_2:
                *l = *t = *r = *b = 2;
                break;
            }
        } else if (surface.border) {
            *l = *t = *r = *b = 1;
        }
    }
}

- (void) minimalSizeWithWidth: (int *) width height: (int *) height;
{
    int i;
    RrSize *m;
    int l, t, r, b;
    *width = *height = 0;

    for (i = 0; i < textures; ++i) {
        switch (texture[i].type) {
        case RR_TEXTURE_NONE:
            break;
        case RR_TEXTURE_MASK:
            *width = MAX(*width, texture[i].data.mask.mask->width);
            *height = MAX(*height, texture[i].data.mask.mask->height);
            break;
        case RR_TEXTURE_TEXT:
            m = RrFontMeasureString(texture[i].data.text.font,
                                    [texture[i].data.text.string UTF8String]);
            *width = MAX(*width, m->width + 4);
            m->height = RrFontHeight(texture[i].data.text.font);
            *height += MAX(*height, m->height);
            break;
        case RR_TEXTURE_RGBA:
            *width += MAX(*width, texture[i].data.rgba.width);
            *height += MAX(*height, texture[i].data.rgba.height);
            break;
        case RR_TEXTURE_LINE_ART:
            *width += MAX(*width, MAX(texture[i].data.lineart.x1,
                              texture[i].data.lineart.x2));
            *height += MAX(*height, MAX(texture[i].data.lineart.y1,
                              texture[i].data.lineart.y2));
            break;
        }
    }

    [self marginsWithLeft: &l top: &t right: &r bottom: &b];

    *width += l + r;
    *height += t + b;

    if (*width < 1) *width = 1;
    if (*height < 1) *height = 1;
}

- (const AZInstance *) inst { return inst; }
- (RrSurface) surface { return surface; }
- (RrSurface *) surfacePointer { return &surface; }
- (int) textures { return textures; }
- (RrTexture *) texture { return texture; }
- (Pixmap) pixmap { return pixmap; }
- (XftDraw *) xftdraw { return xftdraw; }
- (int) w { return w; }
- (int) h { return h; }

- (void) set_texture: (RrTexture *) t { texture = t; }
- (void) set_pixmap: (Pixmap) p { pixmap = p; }
- (void) set_xftdraw: (XftDraw *) x { xftdraw = x; }
- (void) set_w: (int) width { w = width; }
- (void) set_h: (int) height { h = height; }

@end

@implementation AZAppearance (AZPrivate)
- (void) pixelDataToPixmapWithX: (int) x y: (int) y 
                          width: (int) width height: (int) height
{
    RrPixel32 *in, *scratch;
    Pixmap out;
    XImage *im = NULL;
    im = XCreateImage([inst display], [inst visual], [inst depth],
                      ZPixmap, 0, NULL, width, height, 32, 0);
    NSAssert(im != NULL, @"No XImage");

    in = surface.pixel_data;
    out = pixmap;

/* this malloc is a complete waste of time on normal 32bpp
   as reduce_depth just sets im->data = data and returns
*/
    scratch = calloc(sizeof(RrPixel32), im->width * im->height);
    im->data = (char*) scratch;
    RrReduceDepth(inst, in, im);
    XPutImage([inst display], out,
              DefaultGC([inst display], [inst screen]),
              im, 0, 0, x, y, width, height);
    im->data = NULL;
    XDestroyImage(im);
    free(scratch);
}
@end


static void reverse_bits(char *c, int n)
{
    int i;
    for (i = 0; i < n; i++)
        *c++ = (((*c * 0x0802UL & 0x22110UL) |
                 (*c * 0x8020UL & 0x88440UL)) * 0x10101UL) >> 16;
}

BOOL RrPixmapToRGBA(const AZInstance *inst,
                        Pixmap pmap, Pixmap mask,
                        int *w, int *h, RrPixel32 **data)
{
    Window xr;
    int xx, xy;
    guint pw, ph, mw, mh, xb, xd, i, x, y, di;
    XImage *xi, *xm = NULL;

    if (!XGetGeometry([inst display], pmap,
                      &xr, &xx, &xy, &pw, &ph, &xb, &xd))
        return FALSE;

    if (mask) {
        if (!XGetGeometry([inst display], mask,
                          &xr, &xx, &xy, &mw, &mh, &xb, &xd))
            return FALSE;
        if (pw != mw || ph != mh || xd != 1)
            return FALSE;
    }

    xi = XGetImage([inst display], pmap,
                   0, 0, pw, ph, 0xffffffff, ZPixmap);
    if (!xi)
        return FALSE;

    if (mask) {
        xm = XGetImage([inst display], mask,
                       0, 0, mw, mh, 0xffffffff, ZPixmap);
        if (!xm) {
            XDestroyImage(xi);
            return FALSE;
        }
        if ((xm->bits_per_pixel == 1) && (xm->bitmap_bit_order != LSBFirst))
            reverse_bits(xm->data, xm->bytes_per_line * xm->height);
    }

    if ((xi->bits_per_pixel == 1) && (xi->bitmap_bit_order != LSBFirst))
        reverse_bits(xi->data, xi->bytes_per_line * xi->height);

    *data = calloc(sizeof(RrPixel32), pw * ph);
    RrIncreaseDepth(inst, *data, xi);

    if (mask) {
        /* apply transparency from the mask */
        di = 0;
        for (i = 0, y = 0; y < ph; ++y) {
            for (x = 0; x < pw; ++x, ++i) {
                if (!((((unsigned)xm->data[di + x / 8]) >> (x % 8)) & 0x1))
                    (*data)[i] &= ~(0xff << RrDefaultAlphaOffset);
            }
            di += xm->bytes_per_line;
        }
    }

    *w = pw;
    *h = ph;

    XDestroyImage(xi);
    if (mask)
        XDestroyImage(xm);

    return TRUE;
}
