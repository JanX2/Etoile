/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   render.h for the Openbox window manager
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

#ifndef __render_h
#define __render_h

#include "geom.h"
#include "version.h"
#import <Foundation/Foundation.h>

#include <X11/Xlib.h> /* some platforms dont include this as needed for Xft */
#define _XFT_NO_COMPAT_ /* no Xft 1 API */
#include <X11/Xft/Xft.h>
#include <glib.h>

G_BEGIN_DECLS

@class AZAppearance;
typedef union  _RrTextureData      RrTextureData;
typedef struct _RrSurface          RrSurface;
typedef struct _RrFont             RrFont;
typedef struct _RrTexture          RrTexture;
typedef struct _RrTextureMask      RrTextureMask;
typedef struct _RrTextureRGBA      RrTextureRGBA;
typedef struct _RrTextureText      RrTextureText;
typedef struct _RrTextureLineArt   RrTextureLineArt;
typedef struct _RrPixmapMask       RrPixmapMask;
typedef struct _RrInstance         RrInstance;
typedef struct _RrColor            RrColor;

typedef guint32 RrPixel32;
typedef guint16 RrPixel16;

typedef enum {
    RR_RELIEF_FLAT,
    RR_RELIEF_RAISED,
    RR_RELIEF_SUNKEN
} RrReliefType;

typedef enum {
    RR_BEVEL_1,
    RR_BEVEL_2
} RrBevelType;

typedef enum {
    RR_SURFACE_NONE,
    RR_SURFACE_PARENTREL,
    RR_SURFACE_SOLID,
    RR_SURFACE_HORIZONTAL,
    RR_SURFACE_VERTICAL,
    RR_SURFACE_DIAGONAL,
    RR_SURFACE_CROSS_DIAGONAL,
    RR_SURFACE_PYRAMID
} RrSurfaceColorType;

typedef enum {
    RR_TEXTURE_NONE,
    RR_TEXTURE_MASK,
    RR_TEXTURE_TEXT,
    RR_TEXTURE_LINE_ART,
    RR_TEXTURE_RGBA
} RrTextureType;

typedef enum {
    RR_JUSTIFY_LEFT,
    RR_JUSTIFY_CENTER,
    RR_JUSTIFY_RIGHT
} RrJustify;

struct _RrSurface {
    RrSurfaceColorType grad;
    RrReliefType relief;
    RrBevelType bevel;
    RrColor *primary;
    RrColor *secondary;
    RrColor *border_color;
    RrColor *bevel_dark; 
    RrColor *bevel_light;
    RrColor *interlace_color;
    BOOL interlaced;
    BOOL border;
    AZAppearance *parent;
    int parentx;
    int parenty;
    RrPixel32 *pixel_data;
};

struct _RrTextureText {
    RrFont *font;
    RrJustify justify;
    RrColor *color;
    gchar *string;
};

struct _RrPixmapMask {
    const RrInstance *inst;
    Pixmap mask;
    int width;
    int height;
    gchar *data;
};

struct _RrTextureMask {
    RrColor *color;
    RrPixmapMask *mask;
};

struct _RrTextureRGBA {
    int width;
    int height;
    RrPixel32 *data;
/* cached scaled so we don't have to scale often */
    int cwidth;
    int cheight;
    RrPixel32 *cache;
};

struct _RrTextureLineArt {
    RrColor *color;
    int x1;
    int y1;
    int x2;
    int y2;
};

union _RrTextureData {
    RrTextureRGBA rgba;
    RrTextureText text;
    RrTextureMask mask;
    RrTextureLineArt lineart;
};

struct _RrTexture {
    RrTextureType type;
    RrTextureData data;
};

@interface AZAppearance: NSObject <NSCopying>
{
    const RrInstance *inst;

    RrSurface surface;
    int textures;
    RrTexture *texture;
    Pixmap pixmap;
    XftDraw *xftdraw;

    /* cached for internal use */
    int w, h;
}
- (id) initWithInstance: (const RrInstance *) inst numberOfTextures: (int) numtex;

- (const RrInstance *) inst;
- (RrSurface) surface;
- (RrSurface *) surfacePointer;
- (int) textures;
- (RrTexture *) texture;
- (Pixmap) pixmap;
- (XftDraw *) xftdraw;
- (int) w;
- (int) h;

- (void) set_texture: (RrTexture *) texture;
- (void) set_pixmap: (Pixmap) pixmap;
- (void) set_xftdraw: (XftDraw *) xftdraw;
- (void) set_w: (int) w;
- (void) set_h: (int) h;

- (void) paint: (Window) win width: (int) w height: (int) h;
- (void) minimalSizeWithWidth: (int *) w height: (int *) h;
- (void) marginsWithLeft: (int *) l top: (int *) t right: (int *) r bottom: (int *) b;

@end

/* these are the same on all endian machines because it seems to be dependant
   on the endianness of the gfx card, not the cpu. */
#define RrDefaultAlphaOffset 24
#define RrDefaultRedOffset 16
#define RrDefaultGreenOffset 8
#define RrDefaultBlueOffset 0

RrInstance* RrInstanceNew (Display *display, int screen);
void        RrInstanceFree (RrInstance *inst);

Display* RrDisplay      (const RrInstance *inst);
int     RrScreen       (const RrInstance *inst);
Window   RrRootWindow   (const RrInstance *inst);
Visual*  RrVisual       (const RrInstance *inst);
int     RrDepth        (const RrInstance *inst);
Colormap RrColormap     (const RrInstance *inst);
int     RrRedOffset    (const RrInstance *inst);
int     RrGreenOffset  (const RrInstance *inst);
int     RrBlueOffset   (const RrInstance *inst);
int     RrRedShift     (const RrInstance *inst);
int     RrGreenShift   (const RrInstance *inst);
int     RrBlueShift    (const RrInstance *inst);
int     RrRedMask      (const RrInstance *inst);
int     RrGreenMask    (const RrInstance *inst);
int     RrBlueMask     (const RrInstance *inst);

RrColor *RrColorNew   (const RrInstance *inst, int r, int g, int b);
RrColor *RrColorParse (const RrInstance *inst, gchar *colorname);
void     RrColorFree  (RrColor *in);

int     RrColorRed   (const RrColor *c);
int     RrColorGreen (const RrColor *c);
int     RrColorBlue  (const RrColor *c);
gulong   RrColorPixel (const RrColor *c);
GC       RrColorGC    (RrColor *c);


RrSize *RrFontMeasureString (const RrFont *f, const gchar *str);
int RrFontHeight        (const RrFont *f);
int RrFontMaxCharWidth  (const RrFont *f);

BOOL RrPixmapToRGBA(const RrInstance *inst,
                        Pixmap pmap, Pixmap mask,
                        int *w, int *h, RrPixel32 **data);

G_END_DECLS

#endif /*__render_h*/
