/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   config.h for the Openbox window manager
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

#ifndef __config_h
#define __config_h

#import "AZStacking.h"
#import "misc.h"
#import "AZClient+Place.h"

#include <glib.h>

struct _ObParseInst;

/*! Should new windows be focused */
extern gboolean config_focus_new;
/*! Focus windows when the mouse enters them */
extern gboolean config_focus_follow;
/*! Timeout for focusing windows on focus follows mouse, in microseconds */
extern guint    config_focus_delay;
/*! If windows should automatically be raised when they are focused in
 focus follows mouse */
extern gboolean config_focus_raise;
/*! Focus the last focused window, not under the mouse, in follow mouse mode */
extern gboolean config_focus_last;

extern ObPlacePolicy config_place_policy;

/*! When true windows' contents are refreshed while they are resized; otherwise
  they are not updated until the resize is complete */
extern gboolean config_resize_redraw;
/*! Divide windows in 4 or 9 areas when doing a resize. The middle will be move
  when selecting 9 corners */
extern gboolean config_resize_four_corners;
/*! show move/resize popups? 0 = no, 1 = always, 2 = only
  resizing !1 increments */
extern gint config_resize_popup_show;
/*! where to show the popup, currently above the window or centered */
extern gint config_resize_popup_pos;

/*! The stacking layer the dock will reside in */
extern ObStackingLayer config_dock_layer;
/*! Is the dock floating */
extern gboolean config_dock_floating;
/*! Don't use a strut for the dock */
extern gboolean config_dock_nostrut;
/*! Where to place the dock if not floating */
extern ObDirection config_dock_pos;
/*! If config_dock_floating, this is the top-left corner's
  position */
extern gint config_dock_x;
/*! If config_dock_floating, this is the top-left corner's
  position */
extern gint config_dock_y;
/*! Whether the dock places the dockapps in it horizontally or vertically */
extern ObOrientation config_dock_orient;
/*! Whether to auto-hide the dock when the pointer is not over it */
extern gboolean config_dock_hide;
/*! The number of microseconds to wait before hiding the dock */
extern guint config_dock_hide_delay;
/*! The number of microseconds to wait before showing the dock */
extern guint config_dock_show_delay;
/*! The mouse button to be used to move dock apps */
extern guint config_dock_app_move_button;
/*! The modifiers to be used with the button to move dock apps */
extern guint config_dock_app_move_modifiers;

/* The name of the theme */
extern gchar *config_theme;

/* Show the onepixel border after toggleDecor */
extern gboolean config_theme_keepborder;
/* Hide window frame buttons that the window doesn't allow */
extern gboolean config_theme_hidedisabled;
/* Titlebar button layout */
extern gchar *config_title_layout;

/*! The number of desktops */
extern gint config_desktops_num;
/*! Desktop to start on, put 5 to start in the center of a 3x3 grid */
extern gint config_screen_firstdesk;
/*! Names for the desktops */
extern GSList *config_desktops_names;

/*! The keycode of the key combo which resets the keybaord chains */
extern guint config_keyboard_reset_keycode;
/*! The modifiers of the key combo which resets the keybaord chains */
extern guint config_keyboard_reset_state;

/*! Number of pixels a drag must go before being considered a drag */
extern gint config_mouse_threshold;
/*! Number of milliseconds within which 2 clicks must occur to be a
  double-click */
extern gint config_mouse_dclicktime;

/*! Number of pixels to resist while crossing another window's edge */
extern gint config_resist_win;
/*! Number of pixels to resist while crossing a screen's edge */
extern gint config_resist_edge;
/*! Should windows resist edges at layers below */
extern gboolean config_resist_layers_below;

/*! Warp near edge on menu? */
extern gboolean config_menu_warppointer;
/*! make menus jump around a lot */
extern gboolean config_menu_xorstyle;
/*! delay for hiding menu when opening */
extern guint    config_menu_hide_delay;
/*! show icons in client_list_menu */
extern gboolean config_menu_client_list_icons;
/*! User-specified menu files */
extern GSList *config_menu_files;

void config_startup(struct _ObParseInst *i);
void config_shutdown();

#endif
