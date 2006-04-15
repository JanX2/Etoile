/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   theme.c for the Openbox window manager
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
#include "color.h"
#include "font.h"
#include "mask.h"
#include "theme.h"
#include "icon.h"
#include "parse.h"

#include <X11/Xlib.h>
#include <X11/Xresource.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

#define DEFAULT_THEME "TheBear"

static XrmDatabase loaddb(RrTheme *theme, gchar *name);
static BOOL read_int(XrmDatabase db, gchar *rname, int *value);
static BOOL read_string(XrmDatabase db, gchar *rname, gchar **value);
static BOOL read_color(XrmDatabase db, const RrInstance *inst,
                           gchar *rname, RrColor **value);
static BOOL read_mask(const RrInstance *inst,
                          gchar *maskname, RrTheme *theme,
                          RrPixmapMask **value);
static BOOL read_appearance(XrmDatabase db, const RrInstance *inst,
                                gchar *rname, RrAppearance *value,
                                BOOL allow_trans);
static RrPixel32* read_c_image(int width, int height, const guint8 *data);
static void set_default_appearance(RrAppearance *a);

RrTheme* RrThemeNew(const RrInstance *inst, gchar *name)
{
    XrmDatabase db = NULL;
    RrJustify winjust, mtitlejust;
    gchar *str;
    gchar *font_str;
    RrTheme *theme;

    theme = g_new0(RrTheme, 1);

    theme->inst = inst;

    theme->show_handle = YES;

    theme->a_disabled_focused_max = RrAppearanceNew(inst, 1);
    theme->a_disabled_unfocused_max = RrAppearanceNew(inst, 1);
    theme->a_hover_focused_max = RrAppearanceNew(inst, 1);
    theme->a_hover_unfocused_max = RrAppearanceNew(inst, 1);
    theme->a_toggled_focused_max = RrAppearanceNew(inst, 1);
    theme->a_toggled_unfocused_max = RrAppearanceNew(inst, 1);
    theme->a_focused_unpressed_max = RrAppearanceNew(inst, 1);
    theme->a_focused_pressed_max = RrAppearanceNew(inst, 1);
    theme->a_unfocused_unpressed_max = RrAppearanceNew(inst, 1);
    theme->a_unfocused_pressed_max = RrAppearanceNew(inst, 1);
    theme->a_focused_grip = RrAppearanceNew(inst, 0);
    theme->a_unfocused_grip = RrAppearanceNew(inst, 0);
    theme->a_focused_title = RrAppearanceNew(inst, 0);
    theme->a_unfocused_title = RrAppearanceNew(inst, 0);
    theme->a_focused_label = RrAppearanceNew(inst, 1);
    theme->a_unfocused_label = RrAppearanceNew(inst, 1);
    theme->a_icon = RrAppearanceNew(inst, 1);
    theme->a_focused_handle = RrAppearanceNew(inst, 0);
    theme->a_unfocused_handle = RrAppearanceNew(inst, 0);
    theme->a_menu = RrAppearanceNew(inst, 0);
    theme->a_menu_title = RrAppearanceNew(inst, 1);
    theme->a_menu_normal = RrAppearanceNew(inst, 0);
    theme->a_menu_disabled = RrAppearanceNew(inst, 0);
    theme->a_menu_selected = RrAppearanceNew(inst, 0);
    theme->a_menu_text_normal = RrAppearanceNew(inst, 1);
    theme->a_menu_text_disabled = RrAppearanceNew(inst, 1);
    theme->a_menu_text_selected = RrAppearanceNew(inst, 1);
    theme->a_menu_bullet_normal = RrAppearanceNew(inst, 1);
    theme->a_menu_bullet_selected = RrAppearanceNew(inst, 1);
    theme->a_clear = RrAppearanceNew(inst, 0);
    theme->a_clear_tex = RrAppearanceNew(inst, 1);

    if (name) {
        db = loaddb(theme, name);
        if (db == NULL) {
            g_warning("Failed to load the theme '%s'\n"
                      "Falling back to the default: '%s'",
                      name, DEFAULT_THEME);
        } else
            theme->name = g_path_get_basename(name);
    }
    if (db == NULL) {
        db = loaddb(theme, DEFAULT_THEME);
        if (db == NULL) {
            g_warning("Failed to load the theme '%s'.", DEFAULT_THEME);
            return NULL;
        } else
            theme->name = g_path_get_basename(DEFAULT_THEME);
    }

    /* load the font stuff */
    if (!read_string(db, "window.active.label.text.font", &font_str))
        font_str = "arial,sans:bold:pixelsize=10:shadow=y:shadowtint=50";

    if (!(theme->win_font_focused = RrFontOpen(inst, font_str))) {
        RrThemeFree(theme);
        return NULL;
    }
    theme->win_font_height = RrFontHeight(theme->win_font_focused);

    if (!read_string(db, "window.inactive.label.text.font", &font_str))
        /* font_str will already be set to the last one */;

    if (!(theme->win_font_unfocused = RrFontOpen(inst, font_str))) {
        RrThemeFree(theme);
        return NULL;
    }
    theme->win_font_height = MAX(theme->win_font_height,
                                 RrFontHeight(theme->win_font_unfocused));

    winjust = RR_JUSTIFY_LEFT;
    if (read_string(db, "window.label.text.justify", &str)) {
        if (!g_ascii_strcasecmp(str, "right"))
            winjust = RR_JUSTIFY_RIGHT;
        else if (!g_ascii_strcasecmp(str, "center"))
            winjust = RR_JUSTIFY_CENTER;
    }

    if (!read_string(db, "menu.title.text.font", &font_str))
        font_str = "arial,sans:bold:pixelsize=12:shadow=y";

    if (!(theme->menu_title_font = RrFontOpen(inst, font_str))) {
        RrThemeFree(theme);
        return NULL;
    }
    theme->menu_title_font_height = RrFontHeight(theme->menu_title_font);

    mtitlejust = RR_JUSTIFY_LEFT;
    if (read_string(db, "menu.title.text.justify", &str)) {
        if (!g_ascii_strcasecmp(str, "right"))
            mtitlejust = RR_JUSTIFY_RIGHT;
        else if (!g_ascii_strcasecmp(str, "center"))
            mtitlejust = RR_JUSTIFY_CENTER;
    }

    if (!read_string(db, "menu.items.font", &font_str))
        font_str = "arial,sans:bold:pixelsize=11:shadow=y";

    if (!(theme->menu_font = RrFontOpen(inst, font_str))) {
        RrThemeFree(theme);
        return NULL;
    }
    theme->menu_font_height = RrFontHeight(theme->menu_font);

    /* load direct dimensions */
    if (!read_int(db, "menu.overlap", &theme->menu_overlap) ||
        theme->menu_overlap < 0 || theme->menu_overlap > 20)
        theme->menu_overlap = 0;
    if (!read_int(db, "window.handle.width", &theme->handle_height))
        theme->handle_height = 6;
    if (!theme->handle_height)
        theme->show_handle = NO;
    if (theme->handle_height <= 0 || theme->handle_height > 100)
        theme->handle_height = 6;
    if (!read_int(db, "padding.width", &theme->padding) ||
        theme->padding < 0 || theme->padding > 100)
        theme->padding = 3;
    if (!read_int(db, "border.width", &theme->bwidth) ||
        theme->bwidth < 0 || theme->bwidth > 100)
        theme->bwidth = 1;
    if (!read_int(db, "window.client.padding.width", &theme->cbwidth) ||
        theme->cbwidth < 0 || theme->cbwidth > 100)
        theme->cbwidth = theme->padding;

    /* load colors */
    if (!read_color(db, inst,
                    "border.color", &theme->b_color))
        theme->b_color = RrColorNew(inst, 0, 0, 0);
    if (!read_color(db, inst,
                    "window.active.client.color",
                    &theme->cb_focused_color))
        theme->cb_focused_color = RrColorNew(inst, 0xff, 0xff, 0xff);
    if (!read_color(db, inst,
                    "window.inactive.client.color",
                    &theme->cb_unfocused_color))
        theme->cb_unfocused_color = RrColorNew(inst, 0xff, 0xff, 0xff);
    if (!read_color(db, inst,
                    "window.active.label.text.color",
                    &theme->title_focused_color))
        theme->title_focused_color = RrColorNew(inst, 0x0, 0x0, 0x0);
    if (!read_color(db, inst,
                    "window.inactive.label.text.color",
                    &theme->title_unfocused_color))
        theme->title_unfocused_color = RrColorNew(inst, 0xff, 0xff, 0xff);
    if (!read_color(db, inst,
                    "window.active.button.unpressed.image.color",
                    &theme->titlebut_focused_unpressed_color))
        theme->titlebut_focused_unpressed_color = RrColorNew(inst, 0, 0, 0);
    if (!read_color(db, inst,
                    "window.inactive.button.unpressed.image.color",
                    &theme->titlebut_unfocused_unpressed_color))
        theme->titlebut_unfocused_unpressed_color =
            RrColorNew(inst, 0xff, 0xff, 0xff);
    if (!read_color(db, inst,
                    "window.active.button.pressed.image.color",
                    &theme->titlebut_focused_pressed_color))
        theme->titlebut_focused_pressed_color =
            RrColorNew(inst,
                       theme->titlebut_focused_unpressed_color->r,
                       theme->titlebut_focused_unpressed_color->g,
                       theme->titlebut_focused_unpressed_color->b);
    if (!read_color(db, inst,
                    "window.inactive.button.pressed.image.color",
                    &theme->titlebut_unfocused_pressed_color))
        theme->titlebut_unfocused_pressed_color =
            RrColorNew(inst,
                       theme->titlebut_unfocused_unpressed_color->r,
                       theme->titlebut_unfocused_unpressed_color->g,
                       theme->titlebut_unfocused_unpressed_color->b);
    if (!read_color(db, inst,
                    "window.active.button.disabled.image.color",
                    &theme->titlebut_disabled_focused_color))
        theme->titlebut_disabled_focused_color =
            RrColorNew(inst, 0xff, 0xff, 0xff);
    if (!read_color(db, inst,
                    "window.inactive.button.disabled.image.color",
                    &theme->titlebut_disabled_unfocused_color))
        theme->titlebut_disabled_unfocused_color = RrColorNew(inst, 0, 0, 0);
    if (!read_color(db, inst,
                    "window.active.button.hover.image.color",
                    &theme->titlebut_hover_focused_color))
        theme->titlebut_hover_focused_color =
            RrColorNew(inst,
                       theme->titlebut_focused_unpressed_color->r,
                       theme->titlebut_focused_unpressed_color->g,
                       theme->titlebut_focused_unpressed_color->b);
    if (!read_color(db, inst,
                    "window.inactive.button.hover.image.color",
                    &theme->titlebut_hover_unfocused_color))
        theme->titlebut_hover_unfocused_color =
            RrColorNew(inst,
                       theme->titlebut_unfocused_unpressed_color->r,
                       theme->titlebut_unfocused_unpressed_color->g,
                       theme->titlebut_unfocused_unpressed_color->b);
    if (!read_color(db, inst,
                    "window.active.button.toggled.image.color",
                    &theme->titlebut_toggled_focused_color))
        theme->titlebut_toggled_focused_color =
            RrColorNew(inst,
                       theme->titlebut_focused_pressed_color->r,
                       theme->titlebut_focused_pressed_color->g,
                       theme->titlebut_focused_pressed_color->b);
    if (!read_color(db, inst,
                    "window.inactive.button.toggled.image.color",
                    &theme->titlebut_toggled_unfocused_color))
        theme->titlebut_toggled_unfocused_color =
            RrColorNew(inst,
                       theme->titlebut_unfocused_pressed_color->r,
                       theme->titlebut_unfocused_pressed_color->g,
                       theme->titlebut_unfocused_pressed_color->b);
    if (!read_color(db, inst,
                    "menu.title.text.color", &theme->menu_title_color))
        theme->menu_title_color = RrColorNew(inst, 0, 0, 0);
    if (!read_color(db, inst,
                    "menu.items.text.color", &theme->menu_color))
        theme->menu_color = RrColorNew(inst, 0xff, 0xff, 0xff);
    if (!read_color(db, inst,
                    "menu.items.disabled.text.color",
                    &theme->menu_disabled_color))
        theme->menu_disabled_color = RrColorNew(inst, 0, 0, 0);
    if (!read_color(db, inst,
                    "menu.items.active.text.color",
                    &theme->menu_selected_color))
        theme->menu_selected_color = RrColorNew(inst, 0, 0, 0);
    
    if (read_mask(inst, "max.xbm", theme, &theme->max_mask)) {
        if (!read_mask(inst, "max_pressed.xbm", theme,
                       &theme->max_pressed_mask)) {
            theme->max_pressed_mask = RrPixmapMaskCopy(theme->max_mask);
        } 
        if (!read_mask(inst, "max_toggled.xbm", theme,
                       &theme->max_toggled_mask)) {
            theme->max_toggled_mask =
                RrPixmapMaskCopy(theme->max_pressed_mask);
        }
        if (!read_mask(inst, "max_disabled.xbm", theme,
                       &theme->max_disabled_mask)) {
            theme->max_disabled_mask = RrPixmapMaskCopy(theme->max_mask);
        } 
        if (!read_mask(inst, "max_hover.xbm", theme, &theme->max_hover_mask)) {
            theme->max_hover_mask = RrPixmapMaskCopy(theme->max_mask);
        }
    } else {
        {
            guchar data[] = { 0x7f, 0x7f, 0x7f, 0x41, 0x41, 0x41, 0x7f };
            theme->max_mask = RrPixmapMaskNew(inst, 7, 7, (gchar*)data);
        }
        {
            guchar data[] = { 0x7c, 0x44, 0x47, 0x47, 0x7f, 0x1f, 0x1f };
            theme->max_toggled_mask = RrPixmapMaskNew(inst, 7, 7, (gchar*)data);
        }
        theme->max_pressed_mask = RrPixmapMaskCopy(theme->max_mask);
        theme->max_disabled_mask = RrPixmapMaskCopy(theme->max_mask);
        theme->max_hover_mask = RrPixmapMaskCopy(theme->max_mask);
    }

    if (read_mask(inst, "iconify.xbm", theme, &theme->iconify_mask)) {
        if (!read_mask(inst, "iconify_pressed.xbm", theme,
                       &theme->iconify_pressed_mask)) {
            theme->iconify_pressed_mask =
                RrPixmapMaskCopy(theme->iconify_mask);
        } 
        if (!read_mask(inst, "iconify_disabled.xbm", theme,
                       &theme->iconify_disabled_mask)) {
            theme->iconify_disabled_mask =
                RrPixmapMaskCopy(theme->iconify_mask);
        } 
        if (!read_mask(inst, "iconify_hover.xbm", theme,
                       &theme->iconify_hover_mask)) {
            theme->iconify_hover_mask = RrPixmapMaskCopy(theme->iconify_mask);
        }
    } else {
        {
            guchar data[] = { 0x00, 0x00, 0x00, 0x00, 0x7f, 0x7f, 0x7f };
            theme->iconify_mask = RrPixmapMaskNew(inst, 7, 7, (gchar*)data);
        }
        theme->iconify_pressed_mask = RrPixmapMaskCopy(theme->iconify_mask);
        theme->iconify_disabled_mask = RrPixmapMaskCopy(theme->iconify_mask);
        theme->iconify_hover_mask = RrPixmapMaskCopy(theme->iconify_mask);
    }

    theme->def_win_icon = read_c_image(OB_DEFAULT_ICON_WIDTH,
                                       OB_DEFAULT_ICON_HEIGHT,
                                       OB_DEFAULT_ICON_pixel_data);

    if (read_mask(inst, "desk.xbm", theme, &theme->desk_mask)) {
        if (!read_mask(inst, "desk_pressed.xbm", theme,
                       &theme->desk_pressed_mask)) {
            theme->desk_pressed_mask = RrPixmapMaskCopy(theme->desk_mask);
        } 
        if (!read_mask(inst, "desk_toggled.xbm", theme,
                       &theme->desk_toggled_mask)) {
            theme->desk_toggled_mask =
                RrPixmapMaskCopy(theme->desk_pressed_mask);
        }
        if (!read_mask(inst, "desk_disabled.xbm", theme,
                       &theme->desk_disabled_mask)) {
            theme->desk_disabled_mask = RrPixmapMaskCopy(theme->desk_mask);
        } 
        if (!read_mask(inst, "desk_hover.xbm", theme, 
                       &theme->desk_hover_mask)) {
            theme->desk_hover_mask = RrPixmapMaskCopy(theme->desk_mask);
        }
    } else {
        {
            guchar data[] = { 0x63, 0x63, 0x00, 0x00, 0x00, 0x63, 0x63 };
            theme->desk_mask = RrPixmapMaskNew(inst, 7, 7, (gchar*)data);
        }
        {
            guchar data[] = { 0x00, 0x36, 0x36, 0x08, 0x36, 0x36, 0x00 };
            theme->desk_toggled_mask = RrPixmapMaskNew(inst, 7, 7,
                                                       (gchar*)data);
        }
        theme->desk_pressed_mask = RrPixmapMaskCopy(theme->desk_mask);
        theme->desk_disabled_mask = RrPixmapMaskCopy(theme->desk_mask);
        theme->desk_hover_mask = RrPixmapMaskCopy(theme->desk_mask);
    }

    if (read_mask(inst, "shade.xbm", theme, &theme->shade_mask)) {
        if (!read_mask(inst, "shade_pressed.xbm", theme,
                       &theme->shade_pressed_mask)) {
            theme->shade_pressed_mask = RrPixmapMaskCopy(theme->shade_mask);
        } 
        if (!read_mask(inst, "shade_toggled.xbm", theme,
                       &theme->shade_toggled_mask)) {
            theme->shade_toggled_mask =
                RrPixmapMaskCopy(theme->shade_pressed_mask);
        }
        if (!read_mask(inst, "shade_disabled.xbm", theme,
                       &theme->shade_disabled_mask)) {
            theme->shade_disabled_mask = RrPixmapMaskCopy(theme->shade_mask);
        } 
        if (!read_mask(inst, "shade_hover.xbm", theme, 
                       &theme->shade_hover_mask)) {
            theme->shade_hover_mask = RrPixmapMaskCopy(theme->shade_mask);
        }
    } else {
        {
            guchar data[] = { 0x7f, 0x7f, 0x7f, 0x00, 0x00, 0x00, 0x00 };
            theme->shade_mask = RrPixmapMaskNew(inst, 7, 7, (gchar*)data);
        }
        {
            guchar data[] = { 0x7f, 0x7f, 0x7f, 0x00, 0x00, 0x00, 0x7f };
            theme->shade_toggled_mask = RrPixmapMaskNew(inst, 7, 7,
                                                        (gchar*)data);
        }
        theme->shade_pressed_mask = RrPixmapMaskCopy(theme->shade_mask);
        theme->shade_disabled_mask = RrPixmapMaskCopy(theme->shade_mask);
        theme->shade_hover_mask = RrPixmapMaskCopy(theme->shade_mask);
    }

    if (read_mask(inst, "close.xbm", theme, &theme->close_mask)) {
        if (!read_mask(inst, "close_pressed.xbm", theme,
                       &theme->close_pressed_mask)) {
            theme->close_pressed_mask = RrPixmapMaskCopy(theme->close_mask);
        } 
        if (!read_mask(inst, "close_disabled.xbm", theme,
                       &theme->close_disabled_mask)) {
            theme->close_disabled_mask = RrPixmapMaskCopy(theme->close_mask);
        } 
        if (!read_mask(inst, "close_hover.xbm", theme,
                       &theme->close_hover_mask)) {
            theme->close_hover_mask = RrPixmapMaskCopy(theme->close_mask);
        }
    } else {
        {
            guchar data[] = { 0x63, 0x77, 0x3e, 0x1c, 0x3e, 0x77, 0x63 };
            theme->close_mask = RrPixmapMaskNew(inst, 7, 7, (gchar*)data);
        }
        theme->close_pressed_mask = RrPixmapMaskCopy(theme->close_mask);
        theme->close_disabled_mask = RrPixmapMaskCopy(theme->close_mask);
        theme->close_hover_mask = RrPixmapMaskCopy(theme->close_mask);
    }

    if (!read_mask(inst, "bullet.xbm", theme, &theme->menu_bullet_mask)) {
        guchar data[] = { 0x01, 0x03, 0x07, 0x0f, 0x07, 0x03, 0x01 };
        theme->menu_bullet_mask = RrPixmapMaskNew(inst, 4, 7, (gchar*)data);
    }

    /* read the decoration textures */
    if (!read_appearance(db, inst,
                         "window.active.title.bg", theme->a_focused_title,
                         NO))
        set_default_appearance(theme->a_focused_title);
    if (!read_appearance(db, inst,
                         "window.inactive.title.bg", theme->a_unfocused_title,
                         NO))
        set_default_appearance(theme->a_unfocused_title);
    if (!read_appearance(db, inst,
                         "window.active.label.bg", theme->a_focused_label,
                         YES))
        set_default_appearance(theme->a_focused_label);
    if (!read_appearance(db, inst,
                         "window.inactive.label.bg", theme->a_unfocused_label,
                         YES))
        set_default_appearance(theme->a_unfocused_label);
    if (!read_appearance(db, inst,
                         "window.active.handle.bg", theme->a_focused_handle,
                         NO))
        set_default_appearance(theme->a_focused_handle);
    if (!read_appearance(db, inst,
                         "window.inactive.handle.bg",theme->a_unfocused_handle,
                         NO))
        set_default_appearance(theme->a_unfocused_handle);
    if (!read_appearance(db, inst,
                         "window.active.grip.bg", theme->a_focused_grip,
                         YES))
        set_default_appearance(theme->a_focused_grip);
    if (!read_appearance(db, inst,
                         "window.inactive.grip.bg", theme->a_unfocused_grip,
                         YES))
        set_default_appearance(theme->a_unfocused_grip);
    if (!read_appearance(db, inst,
                         "menu.items.bg", theme->a_menu,
                         NO))
        set_default_appearance(theme->a_menu);
    if (!read_appearance(db, inst,
                         "menu.title.bg", theme->a_menu_title,
                         NO))
        set_default_appearance(theme->a_menu_title);
    if (!read_appearance(db, inst,
                         "menu.items.active.bg", theme->a_menu_selected,
                         YES))
        set_default_appearance(theme->a_menu_selected);

    /* read the appearances for rendering non-decorations */
    theme->app_hilite_bg = RrAppearanceCopy(theme->a_focused_title);
    theme->app_hilite_label = RrAppearanceCopy(theme->a_focused_label);
    if (theme->a_focused_label->surface.grad != RR_SURFACE_PARENTREL)
        theme->app_hilite_fg = RrAppearanceCopy(theme->a_focused_label);
    else
        theme->app_hilite_fg = RrAppearanceCopy(theme->a_focused_title);
    theme->app_unhilite_bg = RrAppearanceCopy(theme->a_unfocused_title);
    theme->app_unhilite_label = RrAppearanceCopy(theme->a_unfocused_label);
    if (theme->a_unfocused_label->surface.grad != RR_SURFACE_PARENTREL)
        theme->app_unhilite_fg = RrAppearanceCopy(theme->a_unfocused_label);
    else
        theme->app_unhilite_fg = RrAppearanceCopy(theme->a_unfocused_title);

    /* read buttons textures */
    if (!read_appearance(db, inst,
                         "window.active.button.disabled.bg",
                         theme->a_disabled_focused_max,
                         YES))
        set_default_appearance(theme->a_disabled_focused_max);
    if (!read_appearance(db, inst,
                         "window.inactive.button.disabled.bg",
                         theme->a_disabled_unfocused_max,
                         YES))
        set_default_appearance(theme->a_disabled_unfocused_max);
    if (!read_appearance(db, inst,
                         "window.active.button.pressed.bg",
                         theme->a_focused_pressed_max,
                         YES))
        set_default_appearance(theme->a_focused_pressed_max);
    if (!read_appearance(db, inst,
                         "window.inactive.button.pressed.bg",
                         theme->a_unfocused_pressed_max,
                         YES))
        set_default_appearance(theme->a_unfocused_pressed_max);
    if (!read_appearance(db, inst,
                         "window.active.button.toggled.bg",
                         theme->a_toggled_focused_max,
                         YES))
    {
        RrAppearanceFree(theme->a_toggled_focused_max);
        theme->a_toggled_focused_max =
            RrAppearanceCopy(theme->a_focused_pressed_max);
    }
    if (!read_appearance(db, inst,
                         "window.inactive.button.toggled.bg",
                         theme->a_toggled_unfocused_max,
                         YES))
    {
        RrAppearanceFree(theme->a_toggled_unfocused_max);
        theme->a_toggled_unfocused_max =
            RrAppearanceCopy(theme->a_unfocused_pressed_max);
    }
    if (!read_appearance(db, inst,
                         "window.active.button.unpressed.bg",
                         theme->a_focused_unpressed_max,
                         YES))
        set_default_appearance(theme->a_focused_unpressed_max);
    if (!read_appearance(db, inst,
                         "window.inactive.button.unpressed.bg",
                         theme->a_unfocused_unpressed_max,
                         YES))
        set_default_appearance(theme->a_unfocused_unpressed_max);
    if (!read_appearance(db, inst,
                         "window.active.button.hover.bg",
                         theme->a_hover_focused_max,
                         YES))
    {
        RrAppearanceFree(theme->a_hover_focused_max);
        theme->a_hover_focused_max =
            RrAppearanceCopy(theme->a_focused_unpressed_max);
    }
    if (!read_appearance(db, inst,
                         "window.inactive.button.hover.bg",
                         theme->a_hover_unfocused_max,
                         YES))
    {
        RrAppearanceFree(theme->a_hover_unfocused_max);
        theme->a_hover_unfocused_max =
            RrAppearanceCopy(theme->a_unfocused_unpressed_max);
    }

    theme->a_disabled_focused_close =
        RrAppearanceCopy(theme->a_disabled_focused_max);
    theme->a_disabled_unfocused_close =
        RrAppearanceCopy(theme->a_disabled_unfocused_max);
    theme->a_hover_focused_close =
        RrAppearanceCopy(theme->a_hover_focused_max);
    theme->a_hover_unfocused_close =
        RrAppearanceCopy(theme->a_hover_unfocused_max);
    theme->a_unfocused_unpressed_close =
        RrAppearanceCopy(theme->a_unfocused_unpressed_max);
    theme->a_unfocused_pressed_close =
        RrAppearanceCopy(theme->a_unfocused_pressed_max);
    theme->a_focused_unpressed_close =
        RrAppearanceCopy(theme->a_focused_unpressed_max);
    theme->a_focused_pressed_close =
        RrAppearanceCopy(theme->a_focused_pressed_max);
    theme->a_disabled_focused_desk =
        RrAppearanceCopy(theme->a_disabled_focused_max);
    theme->a_disabled_unfocused_desk =
        RrAppearanceCopy(theme->a_disabled_unfocused_max);
    theme->a_hover_focused_desk =
        RrAppearanceCopy(theme->a_hover_focused_max);
    theme->a_hover_unfocused_desk =
        RrAppearanceCopy(theme->a_hover_unfocused_max); 
    theme->a_toggled_focused_desk =
        RrAppearanceCopy(theme->a_toggled_focused_max);
    theme->a_toggled_unfocused_desk =
        RrAppearanceCopy(theme->a_toggled_unfocused_max);
    theme->a_unfocused_unpressed_desk =
        RrAppearanceCopy(theme->a_unfocused_unpressed_max);
    theme->a_unfocused_pressed_desk =
        RrAppearanceCopy(theme->a_unfocused_pressed_max);
    theme->a_focused_unpressed_desk =
        RrAppearanceCopy(theme->a_focused_unpressed_max);
    theme->a_focused_pressed_desk =
        RrAppearanceCopy(theme->a_focused_pressed_max);
    theme->a_disabled_focused_shade =
        RrAppearanceCopy(theme->a_disabled_focused_max);
    theme->a_disabled_unfocused_shade =
        RrAppearanceCopy(theme->a_disabled_unfocused_max);
    theme->a_hover_focused_shade =
        RrAppearanceCopy(theme->a_hover_focused_max);
    theme->a_hover_unfocused_shade =
        RrAppearanceCopy(theme->a_hover_unfocused_max);
    theme->a_toggled_focused_shade =
        RrAppearanceCopy(theme->a_toggled_focused_max);
    theme->a_toggled_unfocused_shade =
        RrAppearanceCopy(theme->a_toggled_unfocused_max);
    theme->a_unfocused_unpressed_shade =
        RrAppearanceCopy(theme->a_unfocused_unpressed_max);
    theme->a_unfocused_pressed_shade =
        RrAppearanceCopy(theme->a_unfocused_pressed_max);
    theme->a_focused_unpressed_shade =
        RrAppearanceCopy(theme->a_focused_unpressed_max);
    theme->a_focused_pressed_shade =
        RrAppearanceCopy(theme->a_focused_pressed_max);
    theme->a_disabled_focused_iconify =
        RrAppearanceCopy(theme->a_disabled_focused_max);
    theme->a_disabled_unfocused_iconify =
        RrAppearanceCopy(theme->a_disabled_focused_max);
    theme->a_hover_focused_iconify =
        RrAppearanceCopy(theme->a_hover_focused_max);
    theme->a_hover_unfocused_iconify =
        RrAppearanceCopy(theme->a_hover_unfocused_max);
    theme->a_unfocused_unpressed_iconify =
        RrAppearanceCopy(theme->a_unfocused_unpressed_max);
    theme->a_unfocused_pressed_iconify =
        RrAppearanceCopy(theme->a_unfocused_pressed_max);
    theme->a_focused_unpressed_iconify =
        RrAppearanceCopy(theme->a_focused_unpressed_max);
    theme->a_focused_pressed_iconify =
        RrAppearanceCopy(theme->a_focused_pressed_max);

    theme->a_icon->surface.grad =
        theme->a_clear->surface.grad =
        theme->a_clear_tex->surface.grad =
        theme->a_menu_normal->surface.grad =
        theme->a_menu_disabled->surface.grad =
        theme->a_menu_text_normal->surface.grad =
        theme->a_menu_text_disabled->surface.grad =
        theme->a_menu_text_selected->surface.grad =
        theme->a_menu_bullet_normal->surface.grad =
        theme->a_menu_bullet_selected->surface.grad = RR_SURFACE_PARENTREL;

    /* set up the textures */
    theme->a_focused_label->texture[0].type = 
        theme->app_hilite_label->texture[0].type = RR_TEXTURE_TEXT;
    theme->a_focused_label->texture[0].data.text.justify = winjust;
    theme->app_hilite_label->texture[0].data.text.justify = RR_JUSTIFY_LEFT;
    theme->a_focused_label->texture[0].data.text.font =
        theme->app_hilite_label->texture[0].data.text.font =
        theme->win_font_focused;
    theme->a_focused_label->texture[0].data.text.color =
        theme->app_hilite_label->texture[0].data.text.color =
        theme->title_focused_color;

    theme->a_unfocused_label->texture[0].type =
        theme->app_unhilite_label->texture[0].type = RR_TEXTURE_TEXT;
    theme->a_unfocused_label->texture[0].data.text.justify = winjust;
    theme->app_unhilite_label->texture[0].data.text.justify =
        RR_JUSTIFY_LEFT;
    theme->a_unfocused_label->texture[0].data.text.font =
        theme->app_unhilite_label->texture[0].data.text.font =
        theme->win_font_unfocused;
    theme->a_unfocused_label->texture[0].data.text.color =
        theme->app_unhilite_label->texture[0].data.text.color =
        theme->title_unfocused_color;

    theme->a_menu_title->texture[0].type = RR_TEXTURE_TEXT;
    theme->a_menu_title->texture[0].data.text.justify = mtitlejust;
    theme->a_menu_title->texture[0].data.text.font = theme->menu_title_font;
    theme->a_menu_title->texture[0].data.text.color = theme->menu_title_color;

    theme->a_menu_text_normal->texture[0].type =
        theme->a_menu_text_disabled->texture[0].type = 
        theme->a_menu_text_selected->texture[0].type = RR_TEXTURE_TEXT;
    theme->a_menu_text_normal->texture[0].data.text.justify = 
        theme->a_menu_text_disabled->texture[0].data.text.justify = 
        theme->a_menu_text_selected->texture[0].data.text.justify =
        RR_JUSTIFY_LEFT;
    theme->a_menu_text_normal->texture[0].data.text.font =
        theme->a_menu_text_disabled->texture[0].data.text.font =
        theme->a_menu_text_selected->texture[0].data.text.font =
        theme->menu_font;
    theme->a_menu_text_normal->texture[0].data.text.color = theme->menu_color;
    theme->a_menu_text_disabled->texture[0].data.text.color =
        theme->menu_disabled_color;
    theme->a_menu_text_selected->texture[0].data.text.color =
        theme->menu_selected_color;

    theme->a_disabled_focused_max->texture[0].type = 
        theme->a_disabled_unfocused_max->texture[0].type = 
        theme->a_hover_focused_max->texture[0].type = 
        theme->a_hover_unfocused_max->texture[0].type = 
        theme->a_toggled_focused_max->texture[0].type = 
        theme->a_toggled_unfocused_max->texture[0].type = 
        theme->a_focused_unpressed_max->texture[0].type = 
        theme->a_focused_pressed_max->texture[0].type = 
        theme->a_unfocused_unpressed_max->texture[0].type = 
        theme->a_unfocused_pressed_max->texture[0].type = 
        theme->a_disabled_focused_close->texture[0].type = 
        theme->a_disabled_unfocused_close->texture[0].type = 
        theme->a_hover_focused_close->texture[0].type = 
        theme->a_hover_unfocused_close->texture[0].type = 
        theme->a_focused_unpressed_close->texture[0].type = 
        theme->a_focused_pressed_close->texture[0].type = 
        theme->a_unfocused_unpressed_close->texture[0].type = 
        theme->a_unfocused_pressed_close->texture[0].type = 
        theme->a_disabled_focused_desk->texture[0].type = 
        theme->a_disabled_unfocused_desk->texture[0].type = 
        theme->a_hover_focused_desk->texture[0].type = 
        theme->a_hover_unfocused_desk->texture[0].type = 
        theme->a_toggled_focused_desk->texture[0].type = 
        theme->a_toggled_unfocused_desk->texture[0].type = 
        theme->a_focused_unpressed_desk->texture[0].type = 
        theme->a_focused_pressed_desk->texture[0].type = 
        theme->a_unfocused_unpressed_desk->texture[0].type = 
        theme->a_unfocused_pressed_desk->texture[0].type = 
        theme->a_disabled_focused_shade->texture[0].type = 
        theme->a_disabled_unfocused_shade->texture[0].type = 
        theme->a_hover_focused_shade->texture[0].type = 
        theme->a_hover_unfocused_shade->texture[0].type = 
        theme->a_toggled_focused_shade->texture[0].type = 
        theme->a_toggled_unfocused_shade->texture[0].type = 
        theme->a_focused_unpressed_shade->texture[0].type = 
        theme->a_focused_pressed_shade->texture[0].type = 
        theme->a_unfocused_unpressed_shade->texture[0].type = 
        theme->a_unfocused_pressed_shade->texture[0].type = 
        theme->a_disabled_focused_iconify->texture[0].type = 
        theme->a_disabled_unfocused_iconify->texture[0].type = 
        theme->a_hover_focused_iconify->texture[0].type = 
        theme->a_hover_unfocused_iconify->texture[0].type = 
        theme->a_focused_unpressed_iconify->texture[0].type = 
        theme->a_focused_pressed_iconify->texture[0].type = 
        theme->a_unfocused_unpressed_iconify->texture[0].type = 
        theme->a_unfocused_pressed_iconify->texture[0].type =
        theme->a_menu_bullet_normal->texture[0].type =
        theme->a_menu_bullet_selected->texture[0].type = RR_TEXTURE_MASK;
    
    theme->a_disabled_focused_max->texture[0].data.mask.mask = 
        theme->a_disabled_unfocused_max->texture[0].data.mask.mask = 
        theme->max_disabled_mask;
    theme->a_hover_focused_max->texture[0].data.mask.mask = 
        theme->a_hover_unfocused_max->texture[0].data.mask.mask = 
        theme->max_hover_mask;
    theme->a_focused_pressed_max->texture[0].data.mask.mask = 
        theme->a_unfocused_pressed_max->texture[0].data.mask.mask =
        theme->max_pressed_mask;
    theme->a_focused_unpressed_max->texture[0].data.mask.mask = 
        theme->a_unfocused_unpressed_max->texture[0].data.mask.mask = 
        theme->max_mask;
    theme->a_toggled_focused_max->texture[0].data.mask.mask = 
        theme->a_toggled_unfocused_max->texture[0].data.mask.mask =
        theme->max_toggled_mask;
    theme->a_disabled_focused_close->texture[0].data.mask.mask = 
        theme->a_disabled_unfocused_close->texture[0].data.mask.mask = 
        theme->close_disabled_mask;
    theme->a_hover_focused_close->texture[0].data.mask.mask = 
        theme->a_hover_unfocused_close->texture[0].data.mask.mask = 
        theme->close_hover_mask;
    theme->a_focused_pressed_close->texture[0].data.mask.mask = 
        theme->a_unfocused_pressed_close->texture[0].data.mask.mask =
        theme->close_pressed_mask;
    theme->a_focused_unpressed_close->texture[0].data.mask.mask = 
        theme->a_unfocused_unpressed_close->texture[0].data.mask.mask =
        theme->close_mask;
    theme->a_disabled_focused_desk->texture[0].data.mask.mask = 
        theme->a_disabled_unfocused_desk->texture[0].data.mask.mask = 
        theme->desk_disabled_mask;
    theme->a_hover_focused_desk->texture[0].data.mask.mask = 
        theme->a_hover_unfocused_desk->texture[0].data.mask.mask = 
        theme->desk_hover_mask;
    theme->a_focused_pressed_desk->texture[0].data.mask.mask = 
        theme->a_unfocused_pressed_desk->texture[0].data.mask.mask =
        theme->desk_pressed_mask;
    theme->a_focused_unpressed_desk->texture[0].data.mask.mask = 
        theme->a_unfocused_unpressed_desk->texture[0].data.mask.mask = 
        theme->desk_mask;
    theme->a_toggled_focused_desk->texture[0].data.mask.mask = 
        theme->a_toggled_unfocused_desk->texture[0].data.mask.mask =
        theme->desk_toggled_mask;
    theme->a_disabled_focused_shade->texture[0].data.mask.mask = 
        theme->a_disabled_unfocused_shade->texture[0].data.mask.mask = 
        theme->shade_disabled_mask;
    theme->a_hover_focused_shade->texture[0].data.mask.mask = 
        theme->a_hover_unfocused_shade->texture[0].data.mask.mask = 
        theme->shade_hover_mask;
    theme->a_focused_pressed_shade->texture[0].data.mask.mask = 
        theme->a_unfocused_pressed_shade->texture[0].data.mask.mask =
        theme->shade_pressed_mask;
    theme->a_focused_unpressed_shade->texture[0].data.mask.mask = 
        theme->a_unfocused_unpressed_shade->texture[0].data.mask.mask = 
        theme->shade_mask;
    theme->a_toggled_focused_shade->texture[0].data.mask.mask = 
        theme->a_toggled_unfocused_shade->texture[0].data.mask.mask =
        theme->shade_toggled_mask;
    theme->a_disabled_focused_iconify->texture[0].data.mask.mask = 
        theme->a_disabled_unfocused_iconify->texture[0].data.mask.mask = 
        theme->iconify_disabled_mask;
    theme->a_hover_focused_iconify->texture[0].data.mask.mask = 
        theme->a_hover_unfocused_iconify->texture[0].data.mask.mask = 
        theme->iconify_hover_mask;
    theme->a_focused_pressed_iconify->texture[0].data.mask.mask = 
        theme->a_unfocused_pressed_iconify->texture[0].data.mask.mask =
        theme->iconify_pressed_mask;
    theme->a_focused_unpressed_iconify->texture[0].data.mask.mask = 
        theme->a_unfocused_unpressed_iconify->texture[0].data.mask.mask = 
        theme->iconify_mask;
    theme->a_menu_bullet_normal->texture[0].data.mask.mask = 
    theme->a_menu_bullet_selected->texture[0].data.mask.mask = 
        theme->menu_bullet_mask;
    theme->a_disabled_focused_max->texture[0].data.mask.color = 
        theme->a_disabled_focused_close->texture[0].data.mask.color = 
        theme->a_disabled_focused_desk->texture[0].data.mask.color = 
        theme->a_disabled_focused_shade->texture[0].data.mask.color = 
        theme->a_disabled_focused_iconify->texture[0].data.mask.color = 
        theme->titlebut_disabled_focused_color;
    theme->a_disabled_unfocused_max->texture[0].data.mask.color = 
        theme->a_disabled_unfocused_close->texture[0].data.mask.color = 
        theme->a_disabled_unfocused_desk->texture[0].data.mask.color = 
        theme->a_disabled_unfocused_shade->texture[0].data.mask.color = 
        theme->a_disabled_unfocused_iconify->texture[0].data.mask.color = 
        theme->titlebut_disabled_unfocused_color;
    theme->a_hover_focused_max->texture[0].data.mask.color = 
        theme->a_hover_focused_close->texture[0].data.mask.color = 
        theme->a_hover_focused_desk->texture[0].data.mask.color = 
        theme->a_hover_focused_shade->texture[0].data.mask.color = 
        theme->a_hover_focused_iconify->texture[0].data.mask.color = 
        theme->titlebut_hover_focused_color;
    theme->a_hover_unfocused_max->texture[0].data.mask.color = 
        theme->a_hover_unfocused_close->texture[0].data.mask.color = 
        theme->a_hover_unfocused_desk->texture[0].data.mask.color = 
        theme->a_hover_unfocused_shade->texture[0].data.mask.color = 
        theme->a_hover_unfocused_iconify->texture[0].data.mask.color = 
        theme->titlebut_hover_unfocused_color;
    theme->a_toggled_focused_max->texture[0].data.mask.color = 
        theme->a_toggled_focused_desk->texture[0].data.mask.color = 
        theme->a_toggled_focused_shade->texture[0].data.mask.color = 
        theme->titlebut_toggled_focused_color;
    theme->a_toggled_unfocused_max->texture[0].data.mask.color = 
        theme->a_toggled_unfocused_desk->texture[0].data.mask.color = 
        theme->a_toggled_unfocused_shade->texture[0].data.mask.color = 
        theme->titlebut_toggled_unfocused_color;
    theme->a_focused_unpressed_max->texture[0].data.mask.color = 
        theme->a_focused_unpressed_close->texture[0].data.mask.color = 
        theme->a_focused_unpressed_desk->texture[0].data.mask.color = 
        theme->a_focused_unpressed_shade->texture[0].data.mask.color = 
        theme->a_focused_unpressed_iconify->texture[0].data.mask.color = 
        theme->titlebut_focused_unpressed_color;
    theme->a_focused_pressed_max->texture[0].data.mask.color = 
        theme->a_focused_pressed_close->texture[0].data.mask.color = 
        theme->a_focused_pressed_desk->texture[0].data.mask.color = 
        theme->a_focused_pressed_shade->texture[0].data.mask.color = 
        theme->a_focused_pressed_iconify->texture[0].data.mask.color =
        theme->titlebut_focused_pressed_color;
    theme->a_unfocused_unpressed_max->texture[0].data.mask.color = 
        theme->a_unfocused_unpressed_close->texture[0].data.mask.color = 
        theme->a_unfocused_unpressed_desk->texture[0].data.mask.color = 
        theme->a_unfocused_unpressed_shade->texture[0].data.mask.color = 
        theme->a_unfocused_unpressed_iconify->texture[0].data.mask.color = 
        theme->titlebut_unfocused_unpressed_color;
    theme->a_unfocused_pressed_max->texture[0].data.mask.color = 
        theme->a_unfocused_pressed_close->texture[0].data.mask.color = 
        theme->a_unfocused_pressed_desk->texture[0].data.mask.color = 
        theme->a_unfocused_pressed_shade->texture[0].data.mask.color = 
        theme->a_unfocused_pressed_iconify->texture[0].data.mask.color =
        theme->titlebut_unfocused_pressed_color;
    theme->a_menu_bullet_normal->texture[0].data.mask.color = 
        theme->menu_color;
    theme->a_menu_bullet_selected->texture[0].data.mask.color = 
        theme->menu_selected_color;

    XrmDestroyDatabase(db);

    {
        int ft, fb, fl, fr, ut, ub, ul, ur;

        RrMargins(theme->a_focused_label, &fl, &ft, &fr, &fb);
        RrMargins(theme->a_unfocused_label, &ul, &ut, &ur, &ub);
        theme->label_height = theme->win_font_height + MAX(ft + fb, ut + ub);

        /* this would be nice I think, since padding.width can now be 0,
           but it breaks frame.c horribly and I don't feel like fixing that
           right now, so if anyone complains, here is how to keep text from
           going over the title's bevel/border with a padding.width of 0 and a
           bevelless/borderless label
           RrMargins(theme->a_focused_title, &fl, &ft, &fr, &fb);
           RrMargins(theme->a_unfocused_title, &ul, &ut, &ur, &ub);
           theme->title_height = theme->label_height +
           MAX(MAX(theme->padding * 2, ft + fb),
           MAX(theme->padding * 2, ut + ub));
        */
        theme->title_height = theme->label_height + theme->padding * 2;
        /* this should match the above title_height given the same font size
           for both. */
        theme->menu_title_height = theme->menu_title_font_height +
            theme->padding * 2;
    }
    theme->button_size = theme->label_height - 2;
    theme->grip_width = theme->title_height * 1.5;

    return theme;
}

void RrThemeFree(RrTheme *theme)
{
    if (theme) {
        g_free(theme->path);
        g_free(theme->name);

        RrColorFree(theme->b_color);
        RrColorFree(theme->cb_unfocused_color);
        RrColorFree(theme->cb_focused_color);
        RrColorFree(theme->title_unfocused_color);
        RrColorFree(theme->title_focused_color);
        RrColorFree(theme->titlebut_disabled_focused_color);
        RrColorFree(theme->titlebut_disabled_unfocused_color);
        RrColorFree(theme->titlebut_hover_focused_color);
        RrColorFree(theme->titlebut_hover_unfocused_color);
        RrColorFree(theme->titlebut_toggled_focused_color);
        RrColorFree(theme->titlebut_toggled_unfocused_color);
        RrColorFree(theme->titlebut_unfocused_pressed_color);
        RrColorFree(theme->titlebut_focused_pressed_color);
        RrColorFree(theme->titlebut_unfocused_unpressed_color);
        RrColorFree(theme->titlebut_focused_unpressed_color);
        RrColorFree(theme->menu_color);
        RrColorFree(theme->menu_title_color);
        RrColorFree(theme->menu_disabled_color);
        RrColorFree(theme->menu_selected_color);

        g_free(theme->def_win_icon);

        RrPixmapMaskFree(theme->max_mask);
        RrPixmapMaskFree(theme->max_toggled_mask);
        RrPixmapMaskFree(theme->max_disabled_mask);
        RrPixmapMaskFree(theme->max_hover_mask);
        RrPixmapMaskFree(theme->max_pressed_mask);
        RrPixmapMaskFree(theme->desk_mask);
        RrPixmapMaskFree(theme->desk_toggled_mask);
        RrPixmapMaskFree(theme->desk_disabled_mask);
        RrPixmapMaskFree(theme->desk_hover_mask);
        RrPixmapMaskFree(theme->desk_pressed_mask);
        RrPixmapMaskFree(theme->shade_mask);
        RrPixmapMaskFree(theme->shade_toggled_mask);
        RrPixmapMaskFree(theme->shade_disabled_mask);
        RrPixmapMaskFree(theme->shade_hover_mask);
        RrPixmapMaskFree(theme->shade_pressed_mask);
        RrPixmapMaskFree(theme->iconify_mask);
        RrPixmapMaskFree(theme->iconify_disabled_mask);
        RrPixmapMaskFree(theme->iconify_hover_mask);
        RrPixmapMaskFree(theme->iconify_pressed_mask);
        RrPixmapMaskFree(theme->close_mask);
        RrPixmapMaskFree(theme->close_disabled_mask);
        RrPixmapMaskFree(theme->close_hover_mask);
        RrPixmapMaskFree(theme->close_pressed_mask);
        RrPixmapMaskFree(theme->menu_bullet_mask);

        RrFontClose(theme->win_font_focused); 
        RrFontClose(theme->win_font_unfocused);
        RrFontClose(theme->menu_title_font);
        RrFontClose(theme->menu_font);

        RrAppearanceFree(theme->a_disabled_focused_max);
        RrAppearanceFree(theme->a_disabled_unfocused_max);
        RrAppearanceFree(theme->a_hover_focused_max);
        RrAppearanceFree(theme->a_hover_unfocused_max);
        RrAppearanceFree(theme->a_toggled_focused_max);
        RrAppearanceFree(theme->a_toggled_unfocused_max);
        RrAppearanceFree(theme->a_focused_unpressed_max);
        RrAppearanceFree(theme->a_focused_pressed_max);
        RrAppearanceFree(theme->a_unfocused_unpressed_max);
        RrAppearanceFree(theme->a_unfocused_pressed_max);
        RrAppearanceFree(theme->a_disabled_focused_close);
        RrAppearanceFree(theme->a_disabled_unfocused_close);
        RrAppearanceFree(theme->a_hover_focused_close);
        RrAppearanceFree(theme->a_hover_unfocused_close);
        RrAppearanceFree(theme->a_focused_unpressed_close);
        RrAppearanceFree(theme->a_focused_pressed_close);
        RrAppearanceFree(theme->a_unfocused_unpressed_close);
        RrAppearanceFree(theme->a_unfocused_pressed_close);
        RrAppearanceFree(theme->a_disabled_focused_desk);
        RrAppearanceFree(theme->a_disabled_unfocused_desk);
        RrAppearanceFree(theme->a_hover_focused_desk);
        RrAppearanceFree(theme->a_hover_unfocused_desk);
        RrAppearanceFree(theme->a_toggled_focused_desk);
        RrAppearanceFree(theme->a_toggled_unfocused_desk);
        RrAppearanceFree(theme->a_focused_unpressed_desk);
        RrAppearanceFree(theme->a_focused_pressed_desk);
        RrAppearanceFree(theme->a_unfocused_unpressed_desk);
        RrAppearanceFree(theme->a_unfocused_pressed_desk);
        RrAppearanceFree(theme->a_disabled_focused_shade);
        RrAppearanceFree(theme->a_disabled_unfocused_shade);
        RrAppearanceFree(theme->a_hover_focused_shade);
        RrAppearanceFree(theme->a_hover_unfocused_shade);
        RrAppearanceFree(theme->a_toggled_focused_shade);
        RrAppearanceFree(theme->a_toggled_unfocused_shade);
        RrAppearanceFree(theme->a_focused_unpressed_shade);
        RrAppearanceFree(theme->a_focused_pressed_shade);
        RrAppearanceFree(theme->a_unfocused_unpressed_shade);
        RrAppearanceFree(theme->a_unfocused_pressed_shade);
        RrAppearanceFree(theme->a_disabled_focused_iconify);
        RrAppearanceFree(theme->a_disabled_unfocused_iconify);
        RrAppearanceFree(theme->a_hover_focused_iconify);
        RrAppearanceFree(theme->a_hover_unfocused_iconify);
        RrAppearanceFree(theme->a_focused_unpressed_iconify);
        RrAppearanceFree(theme->a_focused_pressed_iconify);
        RrAppearanceFree(theme->a_unfocused_unpressed_iconify);
        RrAppearanceFree(theme->a_unfocused_pressed_iconify);
        RrAppearanceFree(theme->a_focused_grip);
        RrAppearanceFree(theme->a_unfocused_grip);
        RrAppearanceFree(theme->a_focused_title);
        RrAppearanceFree(theme->a_unfocused_title);
        RrAppearanceFree(theme->a_focused_label);
        RrAppearanceFree(theme->a_unfocused_label);
        RrAppearanceFree(theme->a_icon);
        RrAppearanceFree(theme->a_focused_handle);
        RrAppearanceFree(theme->a_unfocused_handle);
        RrAppearanceFree(theme->a_menu);
        RrAppearanceFree(theme->a_menu_title);
        RrAppearanceFree(theme->a_menu_normal);
        RrAppearanceFree(theme->a_menu_disabled);
        RrAppearanceFree(theme->a_menu_selected);
        RrAppearanceFree(theme->a_menu_text_normal);
        RrAppearanceFree(theme->a_menu_text_disabled);
        RrAppearanceFree(theme->a_menu_text_selected);
        RrAppearanceFree(theme->a_menu_bullet_normal);
        RrAppearanceFree(theme->a_menu_bullet_selected);
        RrAppearanceFree(theme->a_clear);
        RrAppearanceFree(theme->a_clear_tex);
        RrAppearanceFree(theme->app_hilite_bg);
        RrAppearanceFree(theme->app_unhilite_bg);
        RrAppearanceFree(theme->app_hilite_fg);
        RrAppearanceFree(theme->app_unhilite_fg);
        RrAppearanceFree(theme->app_hilite_label);
        RrAppearanceFree(theme->app_unhilite_label);

        g_free(theme);
    }
}

static XrmDatabase loaddb(RrTheme *theme, gchar *name)
{
    XrmDatabase db = NULL;
    gchar *s;

    if (name[0] == '/') {
        s = g_build_filename(name, "openbox-3", "themerc", NULL);
        if ((db = XrmGetFileDatabase(s)))
            theme->path = g_path_get_dirname(s);
        g_free(s);
    } else {
        /* XXX backwards compatibility, remove me sometime later */
        s = g_build_filename(g_get_home_dir(), ".themes", name,
                             "openbox-3", "themerc", NULL);
        if ((db = XrmGetFileDatabase(s)))
            theme->path = g_path_get_dirname(s);
        g_free(s);

	int i, count = [parse_xdg_data_dir_paths() count];
	for (i = 0; (db == NULL) && (i < count); i++) 
        {
	    char *p = (char*)[[parse_xdg_data_dir_paths() objectAtIndex: i] fileSystemRepresentation];
            s = g_build_filename(p, "themes", name,
                                 "openbox-3", "themerc", NULL);
            if ((db = XrmGetFileDatabase(s)))
                theme->path = g_path_get_dirname(s);
            g_free(s);
        }
    }

    if (db == NULL) {
        s = g_build_filename(name, "themerc", NULL);
        if ((db = XrmGetFileDatabase(s)))
            theme->path = g_path_get_dirname(s);
        g_free(s);
    }

    return db;
}

static gchar *create_class_name(gchar *rname)
{
    gchar *rclass = g_strdup(rname);
    gchar *p = rclass;

    while (YES) {
        *p = toupper(*p);
        p = strchr(p+1, '.');
        if (p == NULL) break;
        ++p;
        if (*p == '\0') break;
    }
    return rclass;
}

static BOOL read_int(XrmDatabase db, gchar *rname, int *value)
{
    BOOL ret = NO;
    gchar *rclass = create_class_name(rname);
    gchar *rettype, *end;
    XrmValue retvalue;
  
    if (XrmGetResource(db, rname, rclass, &rettype, &retvalue) &&
        retvalue.addr != NULL) {
        *value = (int)strtol(retvalue.addr, &end, 10);
        if (end != retvalue.addr)
            ret = YES;
    }

    g_free(rclass);
    return ret;
}

static BOOL read_string(XrmDatabase db, gchar *rname, gchar **value)
{
    BOOL ret = NO;
    gchar *rclass = create_class_name(rname);
    gchar *rettype;
    XrmValue retvalue;
  
    if (XrmGetResource(db, rname, rclass, &rettype, &retvalue) &&
        retvalue.addr != NULL) {
        *value = retvalue.addr;
        ret = YES;
    }

    g_free(rclass);
    return ret;
}

static BOOL read_color(XrmDatabase db, const RrInstance *inst,
                           gchar *rname, RrColor **value)
{
    BOOL ret = NO;
    gchar *rclass = create_class_name(rname);
    gchar *rettype;
    XrmValue retvalue;
  
    if (XrmGetResource(db, rname, rclass, &rettype, &retvalue) &&
        retvalue.addr != NULL) {
        RrColor *c = RrColorParse(inst, retvalue.addr);
        if (c != NULL) {
            *value = c;
            ret = YES;
        }
    }

    g_free(rclass);
    return ret;
}

static BOOL read_mask(const RrInstance *inst,
                          gchar *maskname, RrTheme *theme,
                          RrPixmapMask **value)
{
    BOOL ret = NO;
    gchar *s;
    int hx, hy; /* ignored */
    guint w, h;
    guchar *b;

    s = g_build_filename(theme->path, maskname, NULL);
    if (XReadBitmapFileData(s, &w, &h, &b, &hx, &hy) == BitmapSuccess) {
        ret = YES;
        *value = RrPixmapMaskNew(inst, w, h, (gchar*)b);
        XFree(b);
    }
    g_free(s);

    return ret;
}

static void parse_appearance(gchar *tex, RrSurfaceColorType *grad,
                             RrReliefType *relief, RrBevelType *bevel,
                             BOOL *interlaced, BOOL *border,
                             BOOL allow_trans)
{
    gchar *t;

    /* convert to all lowercase */
    for (t = tex; *t != '\0'; ++t)
        *t = g_ascii_tolower(*t);

    if (allow_trans && strstr(tex, "parentrelative") != NULL) {
        *grad = RR_SURFACE_PARENTREL;
    } else {
        if (strstr(tex, "gradient") != NULL) {
            if (strstr(tex, "crossdiagonal") != NULL)
                *grad = RR_SURFACE_CROSS_DIAGONAL;
            else if (strstr(tex, "pyramid") != NULL)
                *grad = RR_SURFACE_PYRAMID;
            else if (strstr(tex, "horizontal") != NULL)
                *grad = RR_SURFACE_HORIZONTAL;
            else if (strstr(tex, "vertical") != NULL)
                *grad = RR_SURFACE_VERTICAL;
            else
                *grad = RR_SURFACE_DIAGONAL;
        } else {
            *grad = RR_SURFACE_SOLID;
        }

        if (strstr(tex, "sunken") != NULL)
            *relief = RR_RELIEF_SUNKEN;
        else if (strstr(tex, "flat") != NULL)
            *relief = RR_RELIEF_FLAT;
        else
            *relief = RR_RELIEF_RAISED;

        *border = NO;
        if (*relief == RR_RELIEF_FLAT) {
            if (strstr(tex, "border") != NULL)
                *border = YES;
        } else {
            if (strstr(tex, "bevel2") != NULL)
                *bevel = RR_BEVEL_2;
            else
                *bevel = RR_BEVEL_1;
        }

        if (strstr(tex, "interlaced") != NULL)
            *interlaced = YES;
        else
            *interlaced = NO;
    }
}


static BOOL read_appearance(XrmDatabase db, const RrInstance *inst,
                                gchar *rname, RrAppearance *value,
                                BOOL allow_trans)
{
    BOOL ret = NO;
    gchar *rclass = create_class_name(rname);
    gchar *cname, *ctoname, *bcname, *icname;
    gchar *rettype;
    XrmValue retvalue;

    cname = g_strconcat(rname, ".color", NULL);
    ctoname = g_strconcat(rname, ".colorTo", NULL);
    bcname = g_strconcat(rname, ".border.color", NULL);
    icname = g_strconcat(rname, ".interlace.color", NULL);

    if (XrmGetResource(db, rname, rclass, &rettype, &retvalue) &&
        retvalue.addr != NULL) {
        parse_appearance(retvalue.addr,
                         &value->surface.grad,
                         &value->surface.relief,
                         &value->surface.bevel,
                         &value->surface.interlaced,
                         &value->surface.border,
                         allow_trans);
        if (!read_color(db, inst, cname, &value->surface.primary))
            value->surface.primary = RrColorNew(inst, 0, 0, 0);
        if (!read_color(db, inst, ctoname, &value->surface.secondary))
            value->surface.secondary = RrColorNew(inst, 0, 0, 0);
        if (value->surface.border)
            if (!read_color(db, inst, bcname,
                            &value->surface.border_color))
                value->surface.border_color = RrColorNew(inst, 0, 0, 0);
        if (value->surface.interlaced)
            if (!read_color(db, inst, icname,
                            &value->surface.interlace_color))
                value->surface.interlace_color = RrColorNew(inst, 0, 0, 0);
        ret = YES;
    }

    g_free(icname);
    g_free(bcname);
    g_free(ctoname);
    g_free(cname);
    g_free(rclass);
    return ret;
}

static void set_default_appearance(RrAppearance *a)
{
    a->surface.grad = RR_SURFACE_SOLID;
    a->surface.relief = RR_RELIEF_FLAT;
    a->surface.bevel = RR_BEVEL_1;
    a->surface.interlaced = NO;
    a->surface.border = NO;
    a->surface.primary = RrColorNew(a->inst, 0, 0, 0);
    a->surface.secondary = RrColorNew(a->inst, 0, 0, 0);
}

/* Reads the output from gimp's C-Source file format into valid RGBA data for
   an RrTextureRGBA. */
static RrPixel32* read_c_image(int width, int height, const guint8 *data)
{
    RrPixel32 *im, *p;
    int i;

    p = im = g_memdup(data, width * height * sizeof(RrPixel32));

    for (i = 0; i < width * height; ++i) {
        guchar a = ((*p >> 24) & 0xff);
        guchar b = ((*p >> 16) & 0xff);
        guchar g = ((*p >>  8) & 0xff);
        guchar r = ((*p >>  0) & 0xff);

        *p = ((r << RrDefaultRedOffset) +
              (g << RrDefaultGreenOffset) +
              (b << RrDefaultBlueOffset) +
              (a << RrDefaultAlphaOffset));
        p++;
    }

    return im;
}
