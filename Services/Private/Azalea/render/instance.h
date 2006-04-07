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

#include <X11/Xlib.h>
#include <glib.h>

struct _RrInstance {
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

    GHashTable *color_hash;
};

unsigned int       RrPseudoBPC    (const RrInstance *inst);
XColor*     RrPseudoColors (const RrInstance *inst);
GHashTable* RrColorHash    (const RrInstance *inst);

#endif
