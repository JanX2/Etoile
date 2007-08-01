/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   theme.h for the Openbox window manager
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

#ifndef __theme_h
#define __theme_h

#include "render.h"
#import <Foundation/Foundation.h>

typedef struct _RrTheme RrTheme;

struct _RrTheme {
    NSString *path;
    NSString *name;

    const AZInstance *inst;

    /* style settings - optional decor */
    BOOL show_handle;

    /* style settings - geometry */
    int padding;
    int handle_height;
    int bwidth;
    int cbwidth;
    int label_height;
    int title_height;
    int menu_title_height;
    int button_size;
    int grip_width;
    int menu_overlap;

    /* style settings - colors */
    RrColor *b_color;
    RrColor *cb_focused_color;
    RrColor *cb_unfocused_color;
    RrColor *title_focused_color;
    RrColor *title_unfocused_color;
    RrColor *titlebut_disabled_focused_color;
    RrColor *titlebut_disabled_unfocused_color;
    RrColor *titlebut_hover_focused_color;
    RrColor *titlebut_hover_unfocused_color;
    RrColor *titlebut_toggled_focused_color;
    RrColor *titlebut_toggled_unfocused_color;
    RrColor *titlebut_focused_pressed_color;
    RrColor *titlebut_unfocused_pressed_color;
    RrColor *titlebut_focused_unpressed_color;
    RrColor *titlebut_unfocused_unpressed_color;
    RrColor *menu_title_color;
    RrColor *menu_color;
    RrColor *menu_disabled_color;
    RrColor *menu_selected_color;

    /* style settings - fonts */
    int win_font_height;
    RrFont *win_font_focused;
    RrFont *win_font_unfocused;
    int menu_title_font_height;
    RrFont *menu_title_font;
    int menu_font_height;
    RrFont *menu_font;

    /* style settings - pics */
    RrPixel32 *def_win_icon; /* 48x48 RGBA */

    /* style settings - masks */
    RrPixmapMask *max_mask;
    RrPixmapMask *max_toggled_mask;
    RrPixmapMask *max_hover_mask;
    RrPixmapMask *max_disabled_mask;
    RrPixmapMask *max_pressed_mask;
    RrPixmapMask *iconify_mask;
    RrPixmapMask *iconify_hover_mask;
    RrPixmapMask *iconify_disabled_mask;
    RrPixmapMask *iconify_pressed_mask;
    RrPixmapMask *desk_mask;
    RrPixmapMask *desk_toggled_mask;
    RrPixmapMask *desk_hover_mask;
    RrPixmapMask *desk_disabled_mask;
    RrPixmapMask *desk_pressed_mask;
    RrPixmapMask *shade_mask;
    RrPixmapMask *shade_toggled_mask;
    RrPixmapMask *shade_hover_mask;
    RrPixmapMask *shade_disabled_mask;
    RrPixmapMask *shade_pressed_mask;
    RrPixmapMask *close_mask;
    RrPixmapMask *close_hover_mask;
    RrPixmapMask *close_disabled_mask;
    RrPixmapMask *close_pressed_mask;
    RrPixmapMask *broken_close_mask;
    RrPixmapMask *broken_close_hover_mask;
    RrPixmapMask *broken_close_disabled_mask;
    RrPixmapMask *broken_close_pressed_mask;

    RrPixmapMask *menu_bullet_mask; /* submenu pointer */
    RrPixmapMask *menu_toggle_mask; /* menu boolean */

    /* global appearances */
    AZAppearance *a_disabled_focused_max;
    AZAppearance *a_disabled_unfocused_max;
    AZAppearance *a_hover_focused_max;
    AZAppearance *a_hover_unfocused_max;
    AZAppearance *a_toggled_focused_max;
    AZAppearance *a_toggled_unfocused_max;
    AZAppearance *a_focused_unpressed_max;
    AZAppearance *a_focused_pressed_max;
    AZAppearance *a_unfocused_unpressed_max;
    AZAppearance *a_unfocused_pressed_max;
    AZAppearance *a_disabled_focused_close;
    AZAppearance *a_disabled_unfocused_close;
    AZAppearance *a_hover_focused_close;
    AZAppearance *a_hover_unfocused_close;
    AZAppearance *a_focused_unpressed_close;
    AZAppearance *a_focused_pressed_close;
    AZAppearance *a_unfocused_unpressed_close;
    AZAppearance *a_unfocused_pressed_close;
    AZAppearance *a_disabled_focused_broken_close;
    AZAppearance *a_disabled_unfocused_broken_close;
    AZAppearance *a_hover_focused_broken_close;
    AZAppearance *a_hover_unfocused_broken_close;
    AZAppearance *a_focused_unpressed_broken_close;
    AZAppearance *a_focused_pressed_broken_close;
    AZAppearance *a_unfocused_unpressed_broken_close;
    AZAppearance *a_unfocused_pressed_broken_close;
    AZAppearance *a_disabled_focused_desk;
    AZAppearance *a_disabled_unfocused_desk;
    AZAppearance *a_hover_focused_desk;
    AZAppearance *a_hover_unfocused_desk;
    AZAppearance *a_toggled_focused_desk;
    AZAppearance *a_toggled_unfocused_desk;
    AZAppearance *a_focused_unpressed_desk;
    AZAppearance *a_focused_pressed_desk;
    AZAppearance *a_unfocused_unpressed_desk;
    AZAppearance *a_unfocused_pressed_desk;
    AZAppearance *a_disabled_focused_shade;
    AZAppearance *a_disabled_unfocused_shade;
    AZAppearance *a_hover_focused_shade;
    AZAppearance *a_hover_unfocused_shade;
    AZAppearance *a_toggled_focused_shade;
    AZAppearance *a_toggled_unfocused_shade;
    AZAppearance *a_focused_unpressed_shade;
    AZAppearance *a_focused_pressed_shade;
    AZAppearance *a_unfocused_unpressed_shade;
    AZAppearance *a_unfocused_pressed_shade;
    AZAppearance *a_disabled_focused_iconify;
    AZAppearance *a_disabled_unfocused_iconify;
    AZAppearance *a_hover_focused_iconify;
    AZAppearance *a_hover_unfocused_iconify;
    AZAppearance *a_focused_unpressed_iconify;
    AZAppearance *a_focused_pressed_iconify;
    AZAppearance *a_unfocused_unpressed_iconify;
    AZAppearance *a_unfocused_pressed_iconify;
    AZAppearance *a_focused_grip;
    AZAppearance *a_unfocused_grip;
    AZAppearance *a_focused_title;
    AZAppearance *a_unfocused_title;
    AZAppearance *a_focused_label;
    AZAppearance *a_unfocused_label;
    /* always parentrelative, so no focused/unfocused */
    AZAppearance *a_icon;
    AZAppearance *a_focused_handle;
    AZAppearance *a_unfocused_handle;
    AZAppearance *a_menu_title;
    AZAppearance *a_menu;
    AZAppearance *a_menu_normal;
    AZAppearance *a_menu_disabled;
    AZAppearance *a_menu_selected;
    AZAppearance *a_menu_text_normal;
    AZAppearance *a_menu_text_disabled;
    AZAppearance *a_menu_text_selected;
    AZAppearance *a_menu_bullet_normal;
    AZAppearance *a_menu_bullet_selected;
    AZAppearance *a_clear;     /* clear with no texture */
    AZAppearance *a_clear_tex; /* clear with a texture */

    AZAppearance *app_hilite_bg;
    AZAppearance *app_hilite_fg; /* never parent relative */
    AZAppearance *app_hilite_label; /* can be parent relative */
    AZAppearance *app_unhilite_fg; /* never parent relative */

};

RrTheme* RrThemeNew(const AZInstance *inst, NSString *theme);
void RrThemeFree(RrTheme *theme);

#endif
