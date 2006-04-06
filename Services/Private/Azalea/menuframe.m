/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   menuframe.c for the Openbox window manager
   Copyright (c) 2004        Mikael Magnusson
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

#import "AZScreen.h"
#import "AZDock.h"
#import "AZClient.h"
#import "AZMenuFrame.h"
#include "menuframe.h"
#include "menu.h"
#include "grab.h"
#include "openbox.h"
#include "config.h"
#include "render/theme.h"

GList *menu_frame_visible;

ObMenuFrame* menu_frame_new(ObMenu *menu, AZClient *client)
{
    ObMenuFrame *self;
    XSetWindowAttributes attr;

    self = g_new0(ObMenuFrame, 1);
    self->type = Window_Menu;
    self->_self = [[AZMenuFrame alloc] initWithMenu: menu client: client];
    [self->_self set_obMenuFrame: self];

    [[AZStacking stacking] addWindow: self->_self];

    return self;
}

void menu_frame_free(ObMenuFrame *self)
{
    if (self) {
        [[AZStacking stacking] removeWindow: self->_self];

	DESTROY(self->_self);
        g_free(self);
    }
}

