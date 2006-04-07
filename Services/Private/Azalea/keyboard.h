/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   keyboard.h for the Openbox window manager
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

#ifndef ob__keybaord_h
#define ob__keybaord_h

#include "keytree.h"

#include <glib.h>
#include <X11/Xlib.h>

struct _ObAction;
@class AZClient;

extern KeyBindingTree *keyboard_firstnode;

void keyboard_startup(BOOL reconfig);
void keyboard_shutdown(BOOL reconfig);

BOOL keyboard_bind(GList *keylist, ObAction *action);
void keyboard_unbind_all();

void keyboard_event(AZClient *client, const XEvent *e);
void keyboard_reset_chains();

BOOL keyboard_interactive_grab(unsigned int state, AZClient *client,
                                   struct _ObAction *action);
BOOL keyboard_process_interactive_grab(const XEvent *e, AZClient **client);

void keyboard_grab_for_client(AZClient *c, BOOL grab);

#endif
