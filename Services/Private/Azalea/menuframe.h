/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   menuframe.h for the Openbox window manager
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

#ifndef ob__menuframe_h
#define ob__menuframe_h

#include "geom.h"
#include "window.h"
#include "render/render.h"

#include <glib.h>

struct _ObMenu;

extern GList *menu_frame_visible;

typedef struct _ObMenuFrame ObMenuFrame;

@class AZMenuFrame;
@class AZClient;

struct _ObMenuFrame
{
    /* stuff to be an ObWindow */
    Window_InternalType type;
    AZMenuFrame *_self;
};

ObMenuFrame* menu_frame_new(struct _ObMenu *menu, AZClient *client);
void menu_frame_free(ObMenuFrame *self);

#endif
