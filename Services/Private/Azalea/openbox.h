/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   openbox.h for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   openbox.h for the Openbox window manager
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

#ifndef __openbox_h
#define __openbox_h

#import <Foundation/Foundation.h>
#include "misc.h"

#import "render/instance.h"
#include "render/render.h"
#include "render/theme.h"

#include <X11/Xlib.h>

extern AZInstance *ob_rr_inst;
extern RrTheme    *ob_rr_theme;

/*! The X display */
extern Display *ob_display; 

/*! The number of the screen on which we're running */
extern int     ob_screen;

extern char   *ob_sm_id;
extern BOOL ob_sm_use;
extern BOOL ob_replace_wm;

/* The state of execution of the window manager */
ObState ob_state();

void ob_restart_other(const char *path);
void ob_restart();
void ob_exit(int code);

void ob_reconfigure();

void ob_exit_with_error(char *msg);

Cursor ob_cursor(ObCursor cursor);

KeyCode ob_keycode(ObKey key);

#endif
