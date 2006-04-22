/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   font.c for the Openbox window manager
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

#import <Foundation/Foundation.h>
#include "font.h"
#include "color.h"
#include "mask.h"
#include "theme.h"
#include "geom.h"
#import "instance.h"

#include <X11/Xft/Xft.h>
#include <string.h>
#include <stdlib.h>

#define ELIPSES "..."
#define ELIPSES_LENGTH(font) \
    (font->elipses_length + (font->shadow ? font->offset : 0))

#define OB_SHADOW "shadow"
#define OB_SHADOW_OFFSET "shadowoffset"
#define OB_SHADOW_ALPHA "shadowtint"

FcObjectType objs[] = {
    { OB_SHADOW,        FcTypeBool    },
    { OB_SHADOW_OFFSET, FcTypeInteger },
    { OB_SHADOW_ALPHA,  FcTypeInteger  }
};

static BOOL started = NO;

static void font_startup(void)
{
    if (!XftInit(0)) {
        NSLog(@"Couldn't initialize Xft.");
        exit(EXIT_FAILURE);
    }

    /* Here we are teaching xft about the shadow, shadowoffset & shadowtint */
    FcNameRegisterObjectTypes(objs, (sizeof(objs) / sizeof(objs[0])));
}

static void measure_font(RrFont *f)
{
    /* xOff, yOff is the normal spacing to the next glyph. */
    XGlyphInfo info;

    /* measure an elipses */
    XftTextExtentsUtf8([f->inst display], f->xftfont,
                       (FcChar8*)ELIPSES, strlen(ELIPSES), &info);
    f->elipses_length = (signed) info.xOff;
}

static RrFont *openfont(const AZInstance *inst, gchar *fontstring)
{
    /* This function is called for each font in the theme file. */
    /* It returns a pointer to a RrFont struct after filling it. */
    RrFont *out;
    FcPattern *pat, *match;
    XftFont *font;
    FcResult res;
    int tint;

    if (!(pat = XftNameParse(fontstring)))
        return NULL;

    match = XftFontMatch([inst display], [inst screen], pat, &res);
    FcPatternDestroy(pat);
    if (!match)
        return NULL;

    out = calloc(sizeof(RrFont), 1);
    out->inst = inst;

    if (FcPatternGetBool(match, OB_SHADOW, 0, &out->shadow) != FcResultMatch)
        out->shadow = NO;

    if (FcPatternGetInteger(match, OB_SHADOW_OFFSET, 0, &out->offset) !=
        FcResultMatch)
        out->offset = 1;

    if (FcPatternGetInteger(match, OB_SHADOW_ALPHA, 0, &tint) != FcResultMatch)
        tint = 25;
    if (tint > 100) tint = 100;
    else if (tint < -100) tint = -100;
    out->tint = tint;

    font = XftFontOpenPattern([inst display], match);
    if (!font) {
        FcPatternDestroy(match);
        free(out);
        return NULL;
    } else
        out->xftfont = font;

    measure_font(out);

    return out;
}

RrFont *RrFontOpen(const AZInstance *inst, gchar *fontstring)
{
    RrFont *out;

    if (!started) {
        font_startup();
        started = YES;
    }

    if ((out = openfont(inst, fontstring)))
        return out;
    NSLog(@"Warning: Unable to load font: %s\n", fontstring);
    NSLog(@"Warning: Trying fallback font: %s\n", "sans");

    if ((out = openfont(inst, "sans")))
        return out;
    NSLog(@"Warning: Unable to load font: %s\n", "sans");

    return NULL;
}

void RrFontClose(RrFont *f)
{
    if (f) {
        XftFontClose([f->inst display], f->xftfont);
        free(f);
    }
}

static void font_measure_full(const RrFont *f, const char *str,
                              int *x, int *y)
{
    XGlyphInfo info;

    XftTextExtentsUtf8([f->inst display], f->xftfont,
                       (const FcChar8*)str, strlen(str), &info);

    *x = (signed) info.xOff + (f->shadow ? ABS(f->offset) : 0);
    *y = info.height + (f->shadow ? ABS(f->offset) : 0);
}

RrSize *RrFontMeasureString(const RrFont *f, const char *str)
{
    RrSize *size;
    size = calloc(sizeof(RrSize), 1);
    font_measure_full (f, str, &size->width, &size->height);
    return size;
}

int RrFontHeight(const RrFont *f)
{
    return f->xftfont->ascent + f->xftfont->descent +
           (f->shadow ? f->offset : 0);
}

int RrFontMaxCharWidth(const RrFont *f)
{
    return (signed) f->xftfont->max_advance_width;
}

#if 0
/* For my own reference:
 *   _________
 *  ^space/2  ^height     ^baseline
 *  v_________|_          |
 *            | ^ascent   |   _           _
 *            | |         |  | |_ _____ _| |_ _  _
 *            | |         |  |  _/ -_) \ /  _| || |
 *            | v_________v   \__\___/_\_\\__|\_, |
 *            | ^descent                      |__/
 *  __________|_v
 *  ^space/2  |
 *  V_________v
 */
#endif

void RrFontDraw(XftDraw *d, RrTextureText *t, RrRect *area)
{
    int x,y,w,h;
    XftColor c;
    NSMutableString *text;
    int mw, mh;
    size_t l;
    BOOL shortened = NO;

    /* center vertically
     * for xft we pass the top edge of the text for positioning... */
    y = area->y +
        (area->height - RrFontHeight(t->font)) / 2;
    /* the +2 and -4 leave a small blank edge on the sides */
    x = area->x + 2;
    w = area->width - 4;
    h = area->height;

    text = [NSMutableString stringWithString: t->string];
    l = [text length];
    font_measure_full(t->font, [text UTF8String], &mw, &mh);
    while (l && mw > area->width) {
        shortened = YES;
        /* remove a character from the middle */
	[text deleteCharactersInRange: NSMakeRange(l--/2, 1)];
        /* if the elipses are too large, don't show them at all */
        if (ELIPSES_LENGTH(t->font) > area->width)
            shortened = NO;
        font_measure_full(t->font, [text UTF8String], &mw, &mh);
        mw += ELIPSES_LENGTH(t->font);
    }
    if (shortened) {
	[text insertString: [NSString stringWithCString: ELIPSES]
		atIndex: (l+1)/2];
        l += 3;
    }
    if (!l) return;

    l = strlen([text UTF8String]); /* number of bytes */

    switch (t->justify) {
    case RR_JUSTIFY_LEFT:
        break;
    case RR_JUSTIFY_RIGHT:
        x += (w - mw);
        break;
    case RR_JUSTIFY_CENTER:
        x += (w - mw) / 2;
        break;
    }

    if (t->font->shadow) {
        if (t->font->tint >= 0) {
            c.color.red = 0;
            c.color.green = 0;
            c.color.blue = 0;
            c.color.alpha = 0xffff * t->font->tint / 100;
            c.pixel = BlackPixel([t->font->inst display],
                                 [t->font->inst screen]);
        } else {
            c.color.red = 0xffff;
            c.color.green = 0xffff;
            c.color.blue = 0xffff;
            c.color.alpha = 0xffff * -t->font->tint / 100;
            c.pixel = WhitePixel([t->font->inst display],
                                 [t->font->inst screen]);
        }
        XftDrawStringUtf8(d, &c, t->font->xftfont, x + t->font->offset,
                          t->font->xftfont->ascent + y + t->font->offset,
                          (FcChar8*)[text UTF8String], l);
    }
    c.color.red = t->color->r | t->color->r << 8;
    c.color.green = t->color->g | t->color->g << 8;
    c.color.blue = t->color->b | t->color->b << 8;
    c.color.alpha = 0xff | 0xff << 8; /* fully opaque text */
    c.pixel = t->color->pixel;

    XftDrawStringUtf8(d, &c, t->font->xftfont, x,
                      t->font->xftfont->ascent + y,
                      (FcChar8*)[text UTF8String], l);

    return;
}
