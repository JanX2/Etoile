/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   instance.h for the Openbox window manager
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

#ifndef __render_instance_h
#define __render_instance_h

#import <Foundation/Foundation.h>
#include <X11/Xlib.h>

/* these are the same on all endian machines because it seems to be dependant
   on the endianness of the gfx card, not the cpu. */
#define RrDefaultAlphaOffset 24
#define RrDefaultRedOffset 16
#define RrDefaultGreenOffset 8
#define RrDefaultBlueOffset 0

@interface AZInstance: NSObject
{
    Display *display;
    int screen;

    Visual *visual;
    int depth;
    Colormap colormap;

    int red_offset;
    int green_offset;
    int blue_offset;

    int red_shift;
    int green_shift;
    int blue_shift;

    int red_mask;
    int green_mask;
    int blue_mask;

    int pseudo_bpc;
    XColor *pseudo_colors;

    NSMutableDictionary *color_hash;
}

- (id) initWithDisplay: (Display *) display screen: (int) screen;

- (Display *) display;
- (int) screen;
- (Window) rootWindow;
- (Visual *) visual;
- (int) depth;
- (Colormap) colormap;
- (int) redOffset;
- (int) greenOffset;
- (int) blueOffset;
- (int) redShift;
- (int) greenShift;
- (int) blueShift;
- (int) redMask;
- (int) greenMask;
- (int) blueMask;

- (unsigned int) pseudoBPC;
- (XColor *) pseudoColors;
- (NSMutableDictionary *) colorHash;
@end

#if 0
unsigned int       RrPseudoBPC    (const RrInstance *inst);
XColor*     RrPseudoColors (const RrInstance *inst);
GHashTable* RrColorHash    (const RrInstance *inst);
#endif

#endif
