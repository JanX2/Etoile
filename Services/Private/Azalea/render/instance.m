/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   instance.c for the Openbox window manager
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

#include "render.h"
#include "instance.h"

//static AZInstance *definst = NULL;
#ifdef DEBUG
#include "color.h"
#endif
static void
dest(gpointer data)
{
#ifdef DEBUG
    RrColor *c = data;
    if (c->refcount > 0)
        g_error("color %d (%d,%d,%d) in hash table with %d "
                "leftover references",
                c->id, RrColorRed(c), RrColorGreen(c), RrColorBlue(c),
                c->refcount);
#endif
}

@interface AZInstance (AZPrivate)
- (void) trueColorSetup;
- (void) pseudoColorSetup;
@end

@implementation AZInstance

- (id) initWithDisplay: (Display *) _display screen: (int) _screen
{
  self = [super init];
  display = _display;
  screen = _screen;

  depth = DefaultDepth(display, screen);
  visual = DefaultVisual(display, screen);
  colormap = DefaultColormap(display, screen);

  pseudo_colors = NULL;

  color_hash = g_hash_table_new_full(g_int_hash, g_int_equal,
                                                NULL, dest);

  switch (visual->class) {
    case TrueColor:
        [self trueColorSetup];
        break;
    case PseudoColor:
    case StaticColor:
    case GrayScale:
    case StaticGray:
        [self pseudoColorSetup];
        break;
    default:
        NSLog(@"Critical: Unsupported visual class");
	RELEASE(self);
        return nil;
    }
  return self;
}

- (void) dealloc
{
  free(pseudo_colors);
  g_hash_table_destroy(color_hash);
  [super dealloc];
}

- (Display *) display { return display; }
- (int) screen { return screen; }
- (Window) rootWindow { return RootWindow(display, screen); }
- (Visual *) visual { return visual; }
- (int) depth { return depth; }
- (Colormap) colormap { return colormap; }
- (int) redOffset { return red_offset; }
- (int) greenOffset { return green_offset; }
- (int) blueOffset { return blue_offset; }
- (int) redShift { return red_shift; }
- (int) greenShift { return green_shift; }
- (int) blueShift { return blue_shift; }
- (int) redMask { return red_mask; }
- (int) greenMask { return green_mask; }
- (int) blueMask { return blue_mask; }
- (unsigned int) pseudoBPC { return pseudo_bpc; }
- (XColor *) pseudoColors { return pseudo_colors; }
- (GHashTable *) colorHash { return color_hash; }
@end

@implementation AZInstance (AZPrivate)

- (void) trueColorSetup
{
  unsigned long r_mask, g_mask, b_mask;
  XImage *timage = NULL;

  timage = XCreateImage(display, visual, depth,
                        ZPixmap, 0, NULL, 1, 1, 32, 0);
  NSAssert(timage != NULL, @"Cannot create image");
  /* find the offsets for each color in the visual's masks */
  red_mask = r_mask = timage->red_mask;
  green_mask = g_mask = timage->green_mask;
  blue_mask = b_mask = timage->blue_mask;

  red_offset = 0;
  green_offset = 0;
  blue_offset = 0;

  while (! (r_mask & 1))   { red_offset++;   r_mask   >>= 1; }
  while (! (g_mask & 1)) { green_offset++; g_mask >>= 1; }
  while (! (b_mask & 1))  { blue_offset++;  b_mask  >>= 1; }

  red_shift = green_shift = blue_shift = 8;
  while (r_mask)   { r_mask   >>= 1; red_shift--;   }
  while (g_mask) { g_mask >>= 1; green_shift--; }
  while (b_mask)  { b_mask  >>= 1; blue_shift--;  }
  XFree(timage);
}

#define RrPseudoNcolors() (1 << (pseudo_bpc * 3))

- (void) pseudoColorSetup
{
    XColor icolors[256];
    int tr, tg, tb, n, r, g, b, i, incolors, ii;
    unsigned long dev;
    int cpc, _ncolors;

    /* determine the number of colors and the bits-per-color */
    pseudo_bpc = 2; /* XXX THIS SHOULD BE A USER OPTION */
    NSAssert(pseudo_bpc >= 1, @"PseudoBPC must larger than 0");
    _ncolors = RrPseudoNcolors();

    if (_ncolors > 1 << depth) {
        NSLog(@"Warning: PseudoRenderControl: Invalid colormap size. Resizing.\n");
        pseudo_bpc = 1 << (depth/3) >> 3;
        _ncolors = 1 << (pseudo_bpc * 3);
    }

    /* build a color cube */
    pseudo_colors = calloc(sizeof(XColor), _ncolors);
    cpc = 1 << pseudo_bpc; /* colors per channel */

    for (n = 0, r = 0; r < cpc; r++)
        for (g = 0; g < cpc; g++)
            for (b = 0; b < cpc; b++, n++) {
                tr = (int)(((float)(r)/(float)(cpc-1)) * 0xFF);
                tg = (int)(((float)(g)/(float)(cpc-1)) * 0xFF);
                tb = (int)(((float)(b)/(float)(cpc-1)) * 0xFF);
                pseudo_colors[n].red = tr | tr << 8;
                pseudo_colors[n].green = tg | tg << 8;
                pseudo_colors[n].blue = tb | tb << 8;
                /* used to track allocation */
                pseudo_colors[n].flags = DoRed|DoGreen|DoBlue;
            }

    /* allocate the colors */
    for (i = 0; i < _ncolors; i++)
        if (!XAllocColor(display, colormap,
                         &pseudo_colors[i]))
            pseudo_colors[i].flags = 0; /* mark it as unallocated */

    /* try allocate any colors that failed allocation above */

    /* get the allocated values from the X server
       (only the first 256 XXX why!?)
     */
    incolors = (((1 << depth) > 256) ? 256 : (1 << depth));
    for (i = 0; i < incolors; i++)
        icolors[i].pixel = i;
    XQueryColors(display, colormap, icolors, incolors);

    /* try match unallocated ones */
    for (i = 0; i < _ncolors; i++) {
        if (!pseudo_colors[i].flags) { /* if it wasn't allocated... */
            unsigned long closest = 0xffffffff, close = 0;
            for (ii = 0; ii < incolors; ii++) {
                /* find deviations */
                r = (pseudo_colors[i].red - icolors[ii].red) & 0xff;
                g = (pseudo_colors[i].green - icolors[ii].green) & 0xff;
                b = (pseudo_colors[i].blue - icolors[ii].blue) & 0xff;
                /* find a weighted absolute deviation */
                dev = (r * r) + (g * g) + (b * b);

                if (dev < closest) {
                    closest = dev;
                    close = ii;
                }
            }

            pseudo_colors[i].red = icolors[close].red;
            pseudo_colors[i].green = icolors[close].green;
            pseudo_colors[i].blue = icolors[close].blue;
            pseudo_colors[i].pixel = icolors[close].pixel;

            /* try alloc this closest color, it had better succeed! */
            if (XAllocColor(display, colormap,
                            &pseudo_colors[i]))
                /* mark as alloced */
                pseudo_colors[i].flags = DoRed|DoGreen|DoBlue;
            else
                /* wtf has gone wrong, its already alloced for chissake! */
                NSAssert(0, @"Should not reach here");
        }
    }
}

@end
