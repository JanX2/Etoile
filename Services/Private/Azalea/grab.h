/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   grab.h for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   grab.h for the Openbox window manager
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

#ifndef __grab_h
#define __grab_h

#import "misc.h"
#import <X11/Xlib.h>

void grab_startup(BOOL reconfig);
void grab_shutdown(BOOL reconfig);

BOOL grab_keyboard(BOOL grab);
BOOL grab_pointer(BOOL grab, ObCursor cur);
int grab_server(BOOL grab);

BOOL grab_on_keyboard();
BOOL grab_on_pointer();

void grab_button(unsigned int button, unsigned int state, Window win, unsigned int mask);
void grab_button_full(unsigned int button, unsigned int state, Window win, unsigned int mask, int pointer_mode, ObCursor cursor);
void ungrab_button(unsigned int button, unsigned int state, Window win);

void grab_key(unsigned int keycode, unsigned int state, Window win, int keyboard_mode);

void ungrab_all_keys(Window win);

#endif
