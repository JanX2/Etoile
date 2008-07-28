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
#import "instance.h"

#include <X11/Xlib.h>
#include <X11/Xresource.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

#define DEFAULT_THEME "Azalea"

static XrmDatabase loaddb(RrTheme *theme, NSString *name);
//static BOOL read_bool(XrmDatabase db, char *rname, BOOL *value);
static BOOL read_int(XrmDatabase db, char *rname, int *value);
static BOOL read_string(XrmDatabase db, char *rname, char **value);
static BOOL read_color(XrmDatabase db, const AZInstance *inst,
                           char *rname, RrColor **value);
static BOOL read_mask(const AZInstance *inst,
                          char *maskname, RrTheme *theme,
                          RrPixmapMask **value);
static BOOL read_appearance(XrmDatabase db, const AZInstance *inst,
                                char *rname, AZAppearance *value,
                                BOOL allow_trans);
static RrPixel32* read_c_image(int width, int height, const unsigned char *data);
static void set_default_appearance(AZAppearance *a);

RrTheme* RrThemeNew(const AZInstance *inst, NSString *name)
{
    XrmDatabase db = NULL;
    RrJustify winjust, mtitlejust;
    char *str;
    char *font_str;
    RrTheme *theme;

    theme = calloc(sizeof(RrTheme), 1);

    theme->inst = inst;

    theme->show_handle = YES;

    theme->a_disabled_focused_max = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 1];
    theme->a_disabled_unfocused_max = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 1];
    theme->a_hover_focused_max = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 1];
    theme->a_hover_unfocused_max = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 1];
    theme->a_toggled_focused_max = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 1];
    theme->a_toggled_unfocused_max = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 1];
    theme->a_focused_unpressed_max = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 1];
    theme->a_focused_pressed_max = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 1];
    theme->a_unfocused_unpressed_max = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 1];
    theme->a_unfocused_pressed_max = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 1];
    theme->a_focused_grip = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 0];
    theme->a_unfocused_grip = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 0];
    theme->a_focused_title = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 0];
    theme->a_unfocused_title = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 0];
    theme->a_focused_label = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 1];
    theme->a_unfocused_label = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 1];
    theme->a_icon = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 1];
    theme->a_focused_handle = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 0];
    theme->a_unfocused_handle = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 0];
    theme->a_menu = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 0];
    theme->a_menu_title = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 1];
    theme->a_menu_normal = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 0];
    theme->a_menu_disabled = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 0];
    theme->a_menu_selected = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 0];
    theme->a_menu_text_normal = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 1];
    theme->a_menu_text_disabled = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 1];
    theme->a_menu_text_selected = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 1];
    theme->a_menu_bullet_normal = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 1];
    theme->a_menu_bullet_selected = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 1];
    theme->a_clear = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 0];
    theme->a_clear_tex = [[AZAppearance alloc] initWithInstance: inst numberOfTextures: 1];

    if (name) {
        db = loaddb(theme, name);
        if (db == NULL) {
            NSLog(@"Warning: Failed to load the theme '%@'\n"
                      "Falling back to the default: '%s'",
                      name, DEFAULT_THEME);
        } else
            ASSIGN(theme->name, [name lastPathComponent]);
    }
    if (db == NULL) {
        db = loaddb(theme, [NSString stringWithCString: DEFAULT_THEME]);
        if (db == NULL) {
            NSLog(@"Warning: Failed to load the theme '%s'.", DEFAULT_THEME);
            return NULL;
        } else
            ASSIGN(theme->name, [[NSString stringWithCString: DEFAULT_THEME] lastPathComponent]);
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
        if (!strcasecmp(str, "right"))
            winjust = RR_JUSTIFY_RIGHT;
        else if (!strcasecmp(str, "center"))
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
        if (!strcasecmp(str, "right"))
            mtitlejust = RR_JUSTIFY_RIGHT;
        else if (!strcasecmp(str, "center"))
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
            unsigned char data[] = { 0x7f, 0x7f, 0x7f, 0x41, 0x41, 0x41, 0x7f };
            theme->max_mask = RrPixmapMaskNew(inst, 7, 7, (char*)data);
        }
        {
            unsigned char data[] = { 0x7c, 0x44, 0x47, 0x47, 0x7f, 0x1f, 0x1f };
            theme->max_toggled_mask = RrPixmapMaskNew(inst, 7, 7, (char*)data);
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
            unsigned char data[] = { 0x00, 0x00, 0x00, 0x00, 0x7f, 0x7f, 0x7f };
            theme->iconify_mask = RrPixmapMaskNew(inst, 7, 7, (char*)data);
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
            unsigned char data[] = { 0x63, 0x63, 0x00, 0x00, 0x00, 0x63, 0x63 };
            theme->desk_mask = RrPixmapMaskNew(inst, 7, 7, (char*)data);
        }
        {
            unsigned char data[] = { 0x00, 0x36, 0x36, 0x08, 0x36, 0x36, 0x00 };
            theme->desk_toggled_mask = RrPixmapMaskNew(inst, 7, 7,
                                                       (char*)data);
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
            unsigned char data[] = { 0x7f, 0x7f, 0x7f, 0x00, 0x00, 0x00, 0x00 };
            theme->shade_mask = RrPixmapMaskNew(inst, 7, 7, (char*)data);
        }
        {
            unsigned char data[] = { 0x7f, 0x7f, 0x7f, 0x00, 0x00, 0x00, 0x7f };
            theme->shade_toggled_mask = RrPixmapMaskNew(inst, 7, 7,
                                                        (char*)data);
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
            unsigned char data[] = { 0x63, 0x77, 0x3e, 0x1c, 0x3e, 0x77, 0x63 };
            theme->close_mask = RrPixmapMaskNew(inst, 7, 7, (char*)data);
        }
        theme->close_pressed_mask = RrPixmapMaskCopy(theme->close_mask);
        theme->close_disabled_mask = RrPixmapMaskCopy(theme->close_mask);
        theme->close_hover_mask = RrPixmapMaskCopy(theme->close_mask);
    }

    if (read_mask(inst, "broken_close.xbm", theme, &theme->broken_close_mask)) {
        if (!read_mask(inst, "broken_close_pressed.xbm", theme,
                       &theme->broken_close_pressed_mask)) {
            theme->broken_close_pressed_mask = RrPixmapMaskCopy(theme->broken_close_mask);
        } 
        if (!read_mask(inst, "broken_close_disabled.xbm", theme,
                       &theme->broken_close_disabled_mask)) {
            theme->broken_close_disabled_mask = RrPixmapMaskCopy(theme->broken_close_mask);
        } 
        if (!read_mask(inst, "broken_close_hover.xbm", theme,
                       &theme->broken_close_hover_mask)) {
            theme->broken_close_hover_mask = RrPixmapMaskCopy(theme->broken_close_mask);
        }
    } else {
        {
            unsigned char data[] = { 0x63, 0x77, 0x3e, 0x1c, 0x3e, 0x77, 0x63 };
            theme->broken_close_mask = RrPixmapMaskNew(inst, 7, 7, (char*)data);
        }
        theme->broken_close_pressed_mask = RrPixmapMaskCopy(theme->broken_close_mask);
        theme->broken_close_disabled_mask = RrPixmapMaskCopy(theme->broken_close_mask);
        theme->broken_close_hover_mask = RrPixmapMaskCopy(theme->broken_close_mask);
    }

    if (!read_mask(inst, "bullet.xbm", theme, &theme->menu_bullet_mask)) {
        unsigned char data[] = { 0x01, 0x03, 0x07, 0x0f, 0x07, 0x03, 0x01 };
        theme->menu_bullet_mask = RrPixmapMaskNew(inst, 4, 7, (char*)data);
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
    theme->app_hilite_bg = [theme->a_focused_title copy];
    theme->app_hilite_label = [theme->a_focused_label copy];
    if ([theme->a_focused_label surface].grad != RR_SURFACE_PARENTREL)
        theme->app_hilite_fg = [theme->a_focused_label copy];
    else
        theme->app_hilite_fg = [theme->a_focused_title copy];
    if ([theme->a_unfocused_label surface].grad != RR_SURFACE_PARENTREL)
        theme->app_unhilite_fg = [theme->a_unfocused_label copy];
    else
        theme->app_unhilite_fg = [theme->a_unfocused_title copy];

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
        DESTROY(theme->a_toggled_focused_max);
        theme->a_toggled_focused_max =
            [theme->a_focused_pressed_max copy];
    }
    if (!read_appearance(db, inst,
                         "window.inactive.button.toggled.bg",
                         theme->a_toggled_unfocused_max,
                         YES))
    {
        DESTROY(theme->a_toggled_unfocused_max);
        theme->a_toggled_unfocused_max =
            [theme->a_unfocused_pressed_max copy];
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
        DESTROY(theme->a_hover_focused_max);
        theme->a_hover_focused_max =
            [theme->a_focused_unpressed_max copy];
    }
    if (!read_appearance(db, inst,
                         "window.inactive.button.hover.bg",
                         theme->a_hover_unfocused_max,
                         YES))
    {
        DESTROY(theme->a_hover_unfocused_max);
        theme->a_hover_unfocused_max =
            [theme->a_unfocused_unpressed_max copy];
    }

    theme->a_disabled_focused_close =
        [theme->a_disabled_focused_max copy];
    theme->a_disabled_unfocused_close =
        [theme->a_disabled_unfocused_max copy];
    theme->a_hover_focused_close =
        [theme->a_hover_focused_max copy];
    theme->a_hover_unfocused_close =
        [theme->a_hover_unfocused_max copy];
    theme->a_unfocused_unpressed_close =
        [theme->a_unfocused_unpressed_max copy];
    theme->a_unfocused_pressed_close =
        [theme->a_unfocused_pressed_max copy];
    theme->a_focused_unpressed_close =
        [theme->a_focused_unpressed_max copy];
    theme->a_focused_pressed_close =
        [theme->a_focused_pressed_max copy];
    theme->a_disabled_focused_broken_close =
        [theme->a_disabled_focused_max copy];
    theme->a_disabled_unfocused_broken_close =
        [theme->a_disabled_unfocused_max copy];
    theme->a_hover_focused_broken_close =
        [theme->a_hover_focused_max copy];
    theme->a_hover_unfocused_broken_close =
        [theme->a_hover_unfocused_max copy];
    theme->a_unfocused_unpressed_broken_close =
        [theme->a_unfocused_unpressed_max copy];
    theme->a_unfocused_pressed_broken_close =
        [theme->a_unfocused_pressed_max copy];
    theme->a_focused_unpressed_broken_close =
        [theme->a_focused_unpressed_max copy];
    theme->a_focused_pressed_broken_close =
        [theme->a_focused_pressed_max copy];
    theme->a_disabled_focused_desk =
        [theme->a_disabled_focused_max copy];
    theme->a_disabled_unfocused_desk =
        [theme->a_disabled_unfocused_max copy];
    theme->a_hover_focused_desk =
        [theme->a_hover_focused_max copy];
    theme->a_hover_unfocused_desk =
        [theme->a_hover_unfocused_max copy]; 
    theme->a_toggled_focused_desk =
        [theme->a_toggled_focused_max copy];
    theme->a_toggled_unfocused_desk =
        [theme->a_toggled_unfocused_max copy];
    theme->a_unfocused_unpressed_desk =
        [theme->a_unfocused_unpressed_max copy];
    theme->a_unfocused_pressed_desk =
        [theme->a_unfocused_pressed_max copy];
    theme->a_focused_unpressed_desk =
        [theme->a_focused_unpressed_max copy];
    theme->a_focused_pressed_desk =
        [theme->a_focused_pressed_max copy];
    theme->a_disabled_focused_shade =
        [theme->a_disabled_focused_max copy];
    theme->a_disabled_unfocused_shade =
        [theme->a_disabled_unfocused_max copy];
    theme->a_hover_focused_shade =
        [theme->a_hover_focused_max copy];
    theme->a_hover_unfocused_shade =
        [theme->a_hover_unfocused_max copy];
    theme->a_toggled_focused_shade =
        [theme->a_toggled_focused_max copy];
    theme->a_toggled_unfocused_shade =
        [theme->a_toggled_unfocused_max copy];
    theme->a_unfocused_unpressed_shade =
        [theme->a_unfocused_unpressed_max copy];
    theme->a_unfocused_pressed_shade =
        [theme->a_unfocused_pressed_max copy];
    theme->a_focused_unpressed_shade =
        [theme->a_focused_unpressed_max copy];
    theme->a_focused_pressed_shade =
        [theme->a_focused_pressed_max copy];
    theme->a_disabled_focused_iconify =
        [theme->a_disabled_focused_max copy];
    theme->a_disabled_unfocused_iconify =
        [theme->a_disabled_focused_max copy];
    theme->a_hover_focused_iconify =
        [theme->a_hover_focused_max copy];
    theme->a_hover_unfocused_iconify =
        [theme->a_hover_unfocused_max copy];
    theme->a_unfocused_unpressed_iconify =
        [theme->a_unfocused_unpressed_max copy];
    theme->a_unfocused_pressed_iconify =
        [theme->a_unfocused_pressed_max copy];
    theme->a_focused_unpressed_iconify =
        [theme->a_focused_unpressed_max copy];
    theme->a_focused_pressed_iconify =
        [theme->a_focused_pressed_max copy];

    [theme->a_icon surfacePointer]->grad =
        [theme->a_clear surfacePointer]->grad =
        [theme->a_clear_tex surfacePointer]->grad =
        [theme->a_menu_normal surfacePointer]->grad =
        [theme->a_menu_disabled surfacePointer]->grad =
        [theme->a_menu_text_normal surfacePointer]->grad =
        [theme->a_menu_text_disabled surfacePointer]->grad =
        [theme->a_menu_text_selected surfacePointer]->grad =
        [theme->a_menu_bullet_normal surfacePointer]->grad =
        [theme->a_menu_bullet_selected surfacePointer]->grad = RR_SURFACE_PARENTREL;

    /* set up the textures */
    [theme->a_focused_label texture][0].type = 
        [theme->app_hilite_label texture][0].type = RR_TEXTURE_TEXT;
    [theme->a_focused_label texture][0].data.text.justify = winjust;
    [theme->app_hilite_label texture][0].data.text.justify = RR_JUSTIFY_LEFT;
    [theme->a_focused_label texture][0].data.text.font =
        [theme->app_hilite_label texture][0].data.text.font =
        theme->win_font_focused;
    [theme->a_focused_label texture][0].data.text.color =
        [theme->app_hilite_label texture][0].data.text.color =
        theme->title_focused_color;

    [theme->a_unfocused_label texture][0].type = RR_TEXTURE_TEXT;
    [theme->a_unfocused_label texture][0].data.text.justify = winjust;
    [theme->a_unfocused_label texture][0].data.text.font =
        theme->win_font_unfocused;
    [theme->a_unfocused_label texture][0].data.text.color =
        theme->title_unfocused_color;

    [theme->a_menu_title texture][0].type = RR_TEXTURE_TEXT;
    [theme->a_menu_title texture][0].data.text.justify = mtitlejust;
    [theme->a_menu_title texture][0].data.text.font = theme->menu_title_font;
    [theme->a_menu_title texture][0].data.text.color = theme->menu_title_color;

    [theme->a_menu_text_normal texture][0].type =
        [theme->a_menu_text_disabled texture][0].type = 
        [theme->a_menu_text_selected texture][0].type = RR_TEXTURE_TEXT;
    [theme->a_menu_text_normal texture][0].data.text.justify = 
        [theme->a_menu_text_disabled texture][0].data.text.justify = 
        [theme->a_menu_text_selected texture][0].data.text.justify =
        RR_JUSTIFY_LEFT;
    [theme->a_menu_text_normal texture][0].data.text.font =
        [theme->a_menu_text_disabled texture][0].data.text.font =
        [theme->a_menu_text_selected texture][0].data.text.font =
        theme->menu_font;
    [theme->a_menu_text_normal texture][0].data.text.color = theme->menu_color;
    [theme->a_menu_text_disabled texture][0].data.text.color =
        theme->menu_disabled_color;
    [theme->a_menu_text_selected texture][0].data.text.color =
        theme->menu_selected_color;

    [theme->a_disabled_focused_max texture][0].type = 
        [theme->a_disabled_unfocused_max texture][0].type = 
        [theme->a_hover_focused_max texture][0].type = 
        [theme->a_hover_unfocused_max texture][0].type = 
        [theme->a_toggled_focused_max texture][0].type = 
        [theme->a_toggled_unfocused_max texture][0].type = 
        [theme->a_focused_unpressed_max texture][0].type = 
        [theme->a_focused_pressed_max texture][0].type = 
        [theme->a_unfocused_unpressed_max texture][0].type = 
        [theme->a_unfocused_pressed_max texture][0].type = 
        [theme->a_disabled_focused_close texture][0].type = 
        [theme->a_disabled_unfocused_close texture][0].type = 
        [theme->a_hover_focused_close texture][0].type = 
        [theme->a_hover_unfocused_close texture][0].type = 
        [theme->a_focused_unpressed_close texture][0].type = 
        [theme->a_focused_pressed_close texture][0].type = 
        [theme->a_unfocused_unpressed_close texture][0].type = 
        [theme->a_unfocused_pressed_close texture][0].type = 
        [theme->a_disabled_focused_broken_close texture][0].type = 
        [theme->a_disabled_unfocused_broken_close texture][0].type = 
        [theme->a_hover_focused_broken_close texture][0].type = 
        [theme->a_hover_unfocused_broken_close texture][0].type = 
        [theme->a_focused_unpressed_broken_close texture][0].type = 
        [theme->a_focused_pressed_broken_close texture][0].type = 
        [theme->a_unfocused_unpressed_broken_close texture][0].type = 
        [theme->a_unfocused_pressed_broken_close texture][0].type = 
        [theme->a_disabled_focused_desk texture][0].type = 
        [theme->a_disabled_unfocused_desk texture][0].type = 
        [theme->a_hover_focused_desk texture][0].type = 
        [theme->a_hover_unfocused_desk texture][0].type = 
        [theme->a_toggled_focused_desk texture][0].type = 
        [theme->a_toggled_unfocused_desk texture][0].type = 
        [theme->a_focused_unpressed_desk texture][0].type = 
        [theme->a_focused_pressed_desk texture][0].type = 
        [theme->a_unfocused_unpressed_desk texture][0].type = 
        [theme->a_unfocused_pressed_desk texture][0].type = 
        [theme->a_disabled_focused_shade texture][0].type = 
        [theme->a_disabled_unfocused_shade texture][0].type = 
        [theme->a_hover_focused_shade texture][0].type = 
        [theme->a_hover_unfocused_shade texture][0].type = 
        [theme->a_toggled_focused_shade texture][0].type = 
        [theme->a_toggled_unfocused_shade texture][0].type = 
        [theme->a_focused_unpressed_shade texture][0].type = 
        [theme->a_focused_pressed_shade texture][0].type = 
        [theme->a_unfocused_unpressed_shade texture][0].type = 
        [theme->a_unfocused_pressed_shade texture][0].type = 
        [theme->a_disabled_focused_iconify texture][0].type = 
        [theme->a_disabled_unfocused_iconify texture][0].type = 
        [theme->a_hover_focused_iconify texture][0].type = 
        [theme->a_hover_unfocused_iconify texture][0].type = 
        [theme->a_focused_unpressed_iconify texture][0].type = 
        [theme->a_focused_pressed_iconify texture][0].type = 
        [theme->a_unfocused_unpressed_iconify texture][0].type = 
        [theme->a_unfocused_pressed_iconify texture][0].type =
        [theme->a_menu_bullet_normal texture][0].type =
        [theme->a_menu_bullet_selected texture][0].type = RR_TEXTURE_MASK;
    
    [theme->a_disabled_focused_max texture][0].data.mask.mask = 
        [theme->a_disabled_unfocused_max texture][0].data.mask.mask = 
        theme->max_disabled_mask;
    [theme->a_hover_focused_max texture][0].data.mask.mask = 
        [theme->a_hover_unfocused_max texture][0].data.mask.mask = 
        theme->max_hover_mask;
    [theme->a_focused_pressed_max texture][0].data.mask.mask = 
        [theme->a_unfocused_pressed_max texture][0].data.mask.mask =
        theme->max_pressed_mask;
    [theme->a_focused_unpressed_max texture][0].data.mask.mask = 
        [theme->a_unfocused_unpressed_max texture][0].data.mask.mask = 
        theme->max_mask;
    [theme->a_toggled_focused_max texture][0].data.mask.mask = 
        [theme->a_toggled_unfocused_max texture][0].data.mask.mask =
        theme->max_toggled_mask;
    [theme->a_disabled_focused_close texture][0].data.mask.mask = 
        [theme->a_disabled_unfocused_close texture][0].data.mask.mask = 
        theme->close_disabled_mask;
    [theme->a_hover_focused_close texture][0].data.mask.mask = 
        [theme->a_hover_unfocused_close texture][0].data.mask.mask = 
        theme->close_hover_mask;
    [theme->a_focused_pressed_close texture][0].data.mask.mask = 
        [theme->a_unfocused_pressed_close texture][0].data.mask.mask =
        theme->close_pressed_mask;
    [theme->a_focused_unpressed_close texture][0].data.mask.mask = 
        [theme->a_unfocused_unpressed_close texture][0].data.mask.mask =
        theme->close_mask;
    [theme->a_disabled_focused_broken_close texture][0].data.mask.mask = 
        [theme->a_disabled_unfocused_broken_close texture][0].data.mask.mask = 
        theme->broken_close_disabled_mask;
    [theme->a_hover_focused_broken_close texture][0].data.mask.mask = 
        [theme->a_hover_unfocused_broken_close texture][0].data.mask.mask = 
        theme->broken_close_hover_mask;
    [theme->a_focused_pressed_broken_close texture][0].data.mask.mask = 
        [theme->a_unfocused_pressed_broken_close texture][0].data.mask.mask =
        theme->broken_close_pressed_mask;
    [theme->a_focused_unpressed_broken_close texture][0].data.mask.mask = 
        [theme->a_unfocused_unpressed_broken_close texture][0].data.mask.mask =
        theme->broken_close_mask;
    [theme->a_disabled_focused_desk texture][0].data.mask.mask = 
        [theme->a_disabled_unfocused_desk texture][0].data.mask.mask = 
        theme->desk_disabled_mask;
    [theme->a_hover_focused_desk texture][0].data.mask.mask = 
        [theme->a_hover_unfocused_desk texture][0].data.mask.mask = 
        theme->desk_hover_mask;
    [theme->a_focused_pressed_desk texture][0].data.mask.mask = 
        [theme->a_unfocused_pressed_desk texture][0].data.mask.mask =
        theme->desk_pressed_mask;
    [theme->a_focused_unpressed_desk texture][0].data.mask.mask = 
        [theme->a_unfocused_unpressed_desk texture][0].data.mask.mask = 
        theme->desk_mask;
    [theme->a_toggled_focused_desk texture][0].data.mask.mask = 
        [theme->a_toggled_unfocused_desk texture][0].data.mask.mask =
        theme->desk_toggled_mask;
    [theme->a_disabled_focused_shade texture][0].data.mask.mask = 
        [theme->a_disabled_unfocused_shade texture][0].data.mask.mask = 
        theme->shade_disabled_mask;
    [theme->a_hover_focused_shade texture][0].data.mask.mask = 
        [theme->a_hover_unfocused_shade texture][0].data.mask.mask = 
        theme->shade_hover_mask;
    [theme->a_focused_pressed_shade texture][0].data.mask.mask = 
        [theme->a_unfocused_pressed_shade texture][0].data.mask.mask =
        theme->shade_pressed_mask;
    [theme->a_focused_unpressed_shade texture][0].data.mask.mask = 
        [theme->a_unfocused_unpressed_shade texture][0].data.mask.mask = 
        theme->shade_mask;
    [theme->a_toggled_focused_shade texture][0].data.mask.mask = 
        [theme->a_toggled_unfocused_shade texture][0].data.mask.mask =
        theme->shade_toggled_mask;
    [theme->a_disabled_focused_iconify texture][0].data.mask.mask = 
        [theme->a_disabled_unfocused_iconify texture][0].data.mask.mask = 
        theme->iconify_disabled_mask;
    [theme->a_hover_focused_iconify texture][0].data.mask.mask = 
        [theme->a_hover_unfocused_iconify texture][0].data.mask.mask = 
        theme->iconify_hover_mask;
    [theme->a_focused_pressed_iconify texture][0].data.mask.mask = 
        [theme->a_unfocused_pressed_iconify texture][0].data.mask.mask =
        theme->iconify_pressed_mask;
    [theme->a_focused_unpressed_iconify texture][0].data.mask.mask = 
        [theme->a_unfocused_unpressed_iconify texture][0].data.mask.mask = 
        theme->iconify_mask;
    [theme->a_menu_bullet_normal texture][0].data.mask.mask = 
    [theme->a_menu_bullet_selected texture][0].data.mask.mask = 
        theme->menu_bullet_mask;
    [theme->a_disabled_focused_max texture][0].data.mask.color = 
        [theme->a_disabled_focused_close texture][0].data.mask.color = 
        [theme->a_disabled_focused_broken_close texture][0].data.mask.color = 
        [theme->a_disabled_focused_desk texture][0].data.mask.color = 
        [theme->a_disabled_focused_shade texture][0].data.mask.color = 
        [theme->a_disabled_focused_iconify texture][0].data.mask.color = 
        theme->titlebut_disabled_focused_color;
    [theme->a_disabled_unfocused_max texture][0].data.mask.color = 
        [theme->a_disabled_unfocused_close texture][0].data.mask.color = 
        [theme->a_disabled_unfocused_broken_close texture][0].data.mask.color = 
        [theme->a_disabled_unfocused_desk texture][0].data.mask.color = 
        [theme->a_disabled_unfocused_shade texture][0].data.mask.color = 
        [theme->a_disabled_unfocused_iconify texture][0].data.mask.color = 
        theme->titlebut_disabled_unfocused_color;
    [theme->a_hover_focused_max texture][0].data.mask.color = 
        [theme->a_hover_focused_close texture][0].data.mask.color = 
        [theme->a_hover_focused_broken_close texture][0].data.mask.color = 
        [theme->a_hover_focused_desk texture][0].data.mask.color = 
        [theme->a_hover_focused_shade texture][0].data.mask.color = 
        [theme->a_hover_focused_iconify texture][0].data.mask.color = 
        theme->titlebut_hover_focused_color;
    [theme->a_hover_unfocused_max texture][0].data.mask.color = 
        [theme->a_hover_unfocused_close texture][0].data.mask.color = 
        [theme->a_hover_unfocused_broken_close texture][0].data.mask.color = 
        [theme->a_hover_unfocused_desk texture][0].data.mask.color = 
        [theme->a_hover_unfocused_shade texture][0].data.mask.color = 
        [theme->a_hover_unfocused_iconify texture][0].data.mask.color = 
        theme->titlebut_hover_unfocused_color;
    [theme->a_toggled_focused_max texture][0].data.mask.color = 
        [theme->a_toggled_focused_desk texture][0].data.mask.color = 
        [theme->a_toggled_focused_shade texture][0].data.mask.color = 
        theme->titlebut_toggled_focused_color;
    [theme->a_toggled_unfocused_max texture][0].data.mask.color = 
        [theme->a_toggled_unfocused_desk texture][0].data.mask.color = 
        [theme->a_toggled_unfocused_shade texture][0].data.mask.color = 
        theme->titlebut_toggled_unfocused_color;
    [theme->a_focused_unpressed_max texture][0].data.mask.color = 
        [theme->a_focused_unpressed_close texture][0].data.mask.color = 
        [theme->a_focused_unpressed_broken_close texture][0].data.mask.color = 
        [theme->a_focused_unpressed_desk texture][0].data.mask.color = 
        [theme->a_focused_unpressed_shade texture][0].data.mask.color = 
        [theme->a_focused_unpressed_iconify texture][0].data.mask.color = 
        theme->titlebut_focused_unpressed_color;
    [theme->a_focused_pressed_max texture][0].data.mask.color = 
        [theme->a_focused_pressed_close texture][0].data.mask.color = 
        [theme->a_focused_pressed_broken_close texture][0].data.mask.color = 
        [theme->a_focused_pressed_desk texture][0].data.mask.color = 
        [theme->a_focused_pressed_shade texture][0].data.mask.color = 
        [theme->a_focused_pressed_iconify texture][0].data.mask.color =
        theme->titlebut_focused_pressed_color;
    [theme->a_unfocused_unpressed_max texture][0].data.mask.color = 
        [theme->a_unfocused_unpressed_close texture][0].data.mask.color = 
        [theme->a_unfocused_unpressed_broken_close texture][0].data.mask.color = 
        [theme->a_unfocused_unpressed_desk texture][0].data.mask.color = 
        [theme->a_unfocused_unpressed_shade texture][0].data.mask.color = 
        [theme->a_unfocused_unpressed_iconify texture][0].data.mask.color = 
        theme->titlebut_unfocused_unpressed_color;
    [theme->a_unfocused_pressed_max texture][0].data.mask.color = 
        [theme->a_unfocused_pressed_close texture][0].data.mask.color = 
        [theme->a_unfocused_pressed_broken_close texture][0].data.mask.color = 
        [theme->a_unfocused_pressed_desk texture][0].data.mask.color = 
        [theme->a_unfocused_pressed_shade texture][0].data.mask.color = 
        [theme->a_unfocused_pressed_iconify texture][0].data.mask.color =
        theme->titlebut_unfocused_pressed_color;
    [theme->a_menu_bullet_normal texture][0].data.mask.color = 
        theme->menu_color;
    [theme->a_menu_bullet_selected texture][0].data.mask.color = 
        theme->menu_selected_color;

    XrmDestroyDatabase(db);

    {
        int ft, fb, fl, fr, ut, ub, ul, ur;

        [theme->a_focused_label marginsWithLeft: &fl top: &ft right: &fr bottom: &fb];
        [theme->a_unfocused_label marginsWithLeft: &ul top: &ut right: &ur bottom: &ub];
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
    //theme->grip_width = theme->title_height * 1.5;
    theme->grip_width = 25;

    return theme;
}

void RrThemeFree(RrTheme *theme)
{
    if (theme) {
        DESTROY(theme->path);
        DESTROY(theme->name);

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

        free(theme->def_win_icon);

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
        RrPixmapMaskFree(theme->broken_close_mask);
        RrPixmapMaskFree(theme->broken_close_disabled_mask);
        RrPixmapMaskFree(theme->broken_close_hover_mask);
        RrPixmapMaskFree(theme->broken_close_pressed_mask);
        RrPixmapMaskFree(theme->menu_bullet_mask);

        RrFontClose(theme->win_font_focused); 
        RrFontClose(theme->win_font_unfocused);
        RrFontClose(theme->menu_title_font);
        RrFontClose(theme->menu_font);

        DESTROY(theme->a_disabled_focused_max);
        DESTROY(theme->a_disabled_unfocused_max);
        DESTROY(theme->a_hover_focused_max);
        DESTROY(theme->a_hover_unfocused_max);
        DESTROY(theme->a_toggled_focused_max);
        DESTROY(theme->a_toggled_unfocused_max);
        DESTROY(theme->a_focused_unpressed_max);
        DESTROY(theme->a_focused_pressed_max);
        DESTROY(theme->a_unfocused_unpressed_max);
        DESTROY(theme->a_unfocused_pressed_max);
        DESTROY(theme->a_disabled_focused_close);
        DESTROY(theme->a_disabled_unfocused_close);
        DESTROY(theme->a_hover_focused_close);
        DESTROY(theme->a_hover_unfocused_close);
        DESTROY(theme->a_focused_unpressed_close);
        DESTROY(theme->a_focused_pressed_close);
        DESTROY(theme->a_unfocused_unpressed_close);
        DESTROY(theme->a_unfocused_pressed_close);
        DESTROY(theme->a_disabled_focused_broken_close);
        DESTROY(theme->a_disabled_unfocused_broken_close);
        DESTROY(theme->a_hover_focused_broken_close);
        DESTROY(theme->a_hover_unfocused_broken_close);
        DESTROY(theme->a_focused_unpressed_broken_close);
        DESTROY(theme->a_focused_pressed_broken_close);
        DESTROY(theme->a_unfocused_unpressed_broken_close);
        DESTROY(theme->a_unfocused_pressed_broken_close);
        DESTROY(theme->a_disabled_focused_desk);
        DESTROY(theme->a_disabled_unfocused_desk);
        DESTROY(theme->a_hover_focused_desk);
        DESTROY(theme->a_hover_unfocused_desk);
        DESTROY(theme->a_toggled_focused_desk);
        DESTROY(theme->a_toggled_unfocused_desk);
        DESTROY(theme->a_focused_unpressed_desk);
        DESTROY(theme->a_focused_pressed_desk);
        DESTROY(theme->a_unfocused_unpressed_desk);
        DESTROY(theme->a_unfocused_pressed_desk);
        DESTROY(theme->a_disabled_focused_shade);
        DESTROY(theme->a_disabled_unfocused_shade);
        DESTROY(theme->a_hover_focused_shade);
        DESTROY(theme->a_hover_unfocused_shade);
        DESTROY(theme->a_toggled_focused_shade);
        DESTROY(theme->a_toggled_unfocused_shade);
        DESTROY(theme->a_focused_unpressed_shade);
        DESTROY(theme->a_focused_pressed_shade);
        DESTROY(theme->a_unfocused_unpressed_shade);
        DESTROY(theme->a_unfocused_pressed_shade);
        DESTROY(theme->a_disabled_focused_iconify);
        DESTROY(theme->a_disabled_unfocused_iconify);
        DESTROY(theme->a_hover_focused_iconify);
        DESTROY(theme->a_hover_unfocused_iconify);
        DESTROY(theme->a_focused_unpressed_iconify);
        DESTROY(theme->a_focused_pressed_iconify);
        DESTROY(theme->a_unfocused_unpressed_iconify);
        DESTROY(theme->a_unfocused_pressed_iconify);
        DESTROY(theme->a_focused_grip);
        DESTROY(theme->a_unfocused_grip);
        DESTROY(theme->a_focused_title);
        DESTROY(theme->a_unfocused_title);
        DESTROY(theme->a_focused_label);
        DESTROY(theme->a_unfocused_label);
        DESTROY(theme->a_icon);
        DESTROY(theme->a_focused_handle);
        DESTROY(theme->a_unfocused_handle);
        DESTROY(theme->a_menu);
        DESTROY(theme->a_menu_title);
        DESTROY(theme->a_menu_normal);
        DESTROY(theme->a_menu_disabled);
        DESTROY(theme->a_menu_selected);
        DESTROY(theme->a_menu_text_normal);
        DESTROY(theme->a_menu_text_disabled);
        DESTROY(theme->a_menu_text_selected);
        DESTROY(theme->a_menu_bullet_normal);
        DESTROY(theme->a_menu_bullet_selected);
        DESTROY(theme->a_clear);
        DESTROY(theme->a_clear_tex);
        DESTROY(theme->app_hilite_bg);
        DESTROY(theme->app_hilite_fg);
        DESTROY(theme->app_unhilite_fg);
        DESTROY(theme->app_hilite_label);

        free(theme);
    }
}

static XrmDatabase loaddb(RrTheme *theme, NSString *name)
{
    XrmDatabase db = NULL;
    NSString *s;

    if ([name isAbsolutePath]) {
	s = [NSString pathWithComponents: [NSArray arrayWithObjects: name, @"openbox-3", @"themerc", nil]];
        if ((db = XrmGetFileDatabase((char*)[s fileSystemRepresentation])))
            ASSIGN(theme->path, [s stringByDeletingLastPathComponent]);
    } else {
	int i, count = [parse_xdg_data_dir_paths() count];
	for (i = 0; (db == NULL) && (i < count); i++) 
        {
	    NSString *p = [parse_xdg_data_dir_paths() objectAtIndex: i];
	    s = [NSString pathWithComponents: [NSArray arrayWithObjects: p, @"themes", name, @"openbox-3", @"themerc", nil]];
            if ((db = XrmGetFileDatabase((char*)[s fileSystemRepresentation])))
                ASSIGN(theme->path, [s stringByDeletingLastPathComponent]);
        }
    }

    if (db == NULL) {
	s = [NSString pathWithComponents: [NSArray arrayWithObjects: name, @"themerc", nil]];
        if ((db = XrmGetFileDatabase((char*)[s fileSystemRepresentation])))
           ASSIGN(theme->path, [s stringByDeletingLastPathComponent]);
    }

    return db;
}

static char *create_class_name(char *rname)
{
    char *rclass = strdup(rname);
    char *p = rclass;

    while (YES) {
        *p = toupper(*p);
        p = strchr(p+1, '.');
        if (p == NULL) break;
        ++p;
        if (*p == '\0') break;
    }
    return rclass;
}

/*
static BOOL read_bool(XrmDatabase db, char *rname, BOOL *value)
{
    BOOL ret = NO;
    char *rclass = create_class_name(rname);
    char *rettype;
    XrmValue retvalue;
  
    if (XrmGetResource(db, rname, rclass, &rettype, &retvalue) &&
        retvalue.addr != NULL) {
        if (!strcasecmp(retvalue.addr, "true")) {
            *value = YES;
            ret = YES;
        } else if (!strcasecmp(retvalue.addr, "false")) {
            *value = NO;
            ret = YES;
        }
    }
    free(rclass);
    return ret;
}
*/

static BOOL read_int(XrmDatabase db, char *rname, int *value)
{
    BOOL ret = NO;
    char *rclass = create_class_name(rname);
    char *rettype, *end;
    XrmValue retvalue;
  
    if (XrmGetResource(db, rname, rclass, &rettype, &retvalue) &&
        retvalue.addr != NULL) {
        *value = (int)strtol(retvalue.addr, &end, 10);
        if (end != retvalue.addr)
            ret = YES;
    }

    free(rclass);
    return ret;
}

static BOOL read_string(XrmDatabase db, char *rname, char **value)
{
    BOOL ret = NO;
    char *rclass = create_class_name(rname);
    char *rettype;
    XrmValue retvalue;
  
    if (XrmGetResource(db, rname, rclass, &rettype, &retvalue) &&
        retvalue.addr != NULL) {
        *value = retvalue.addr;
        ret = YES;
    }

    free(rclass);
    return ret;
}

static BOOL read_color(XrmDatabase db, const AZInstance *inst,
                           char *rname, RrColor **value)
{
    BOOL ret = NO;
    char *rclass = create_class_name(rname);
    char *rettype;
    XrmValue retvalue;
  
    if (XrmGetResource(db, rname, rclass, &rettype, &retvalue) &&
        retvalue.addr != NULL) {
        RrColor *c = RrColorParse(inst, retvalue.addr);
        if (c != NULL) {
            *value = c;
            ret = YES;
        }
    }

    free(rclass);
    return ret;
}

static BOOL read_mask(const AZInstance *inst,
                          char *maskname, RrTheme *theme,
                          RrPixmapMask **value)
{
    BOOL ret = NO;
    NSString *s;
    int hx, hy; /* ignored */
    unsigned int w, h;
    unsigned char *b;

    s = [NSString pathWithComponents: [NSArray arrayWithObjects: theme->path, [NSString stringWithCString: maskname], nil]];
    if (XReadBitmapFileData((char*)[s fileSystemRepresentation], &w, &h, &b, &hx, &hy) == BitmapSuccess) {
        ret = YES;
        *value = RrPixmapMaskNew(inst, w, h, (char*)b);
        XFree(b);
    }

    return ret;
}

static void parse_appearance(char *tex, RrSurfaceColorType *grad,
                             RrReliefType *relief, RrBevelType *bevel,
                             BOOL *interlaced, BOOL *border,
                             BOOL allow_trans)
{
    char *t;

    /* convert to all lowercase */
    t = (char*)[[[NSString stringWithCString: tex] lowercaseString] cString];
#if 0
    for (t = tex; *t != '\0'; ++t)
        *t = g_ascii_tolower(*t);
#endif

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


static BOOL read_appearance(XrmDatabase db, const AZInstance *inst,
                                char *rname, AZAppearance *value,
                                BOOL allow_trans)
{
    BOOL ret = NO;
    char *rclass = create_class_name(rname);
    char *cname, *ctoname, *bcname, *icname;
    char *rettype;
    XrmValue retvalue;

    cname = (char*)[[NSString stringWithFormat: @"%s.color", rname] cString];
    ctoname = (char*)[[NSString stringWithFormat: @"%s.colorTo", rname] cString];
    bcname = (char*)[[NSString stringWithFormat: @"%s.border.color", rname] cString];
    icname = (char*)[[NSString stringWithFormat: @"%s.interlace.color", rname] cString];
#if 0
    cname = g_strconcat(rname, ".color", NULL);
    ctoname = g_strconcat(rname, ".colorTo", NULL);
    bcname = g_strconcat(rname, ".border.color", NULL);
    icname = g_strconcat(rname, ".interlace.color", NULL);
#endif

    if (XrmGetResource(db, rname, rclass, &rettype, &retvalue) &&
        retvalue.addr != NULL) {
        parse_appearance(retvalue.addr,
                         &([value surfacePointer]->grad),
                         &([value surfacePointer]->relief),
                         &([value surfacePointer]->bevel),
                         &([value surfacePointer]->interlaced),
                         &([value surfacePointer]->border),
                         allow_trans);
        if (!read_color(db, inst, cname, &([value surfacePointer]->primary)))
            [value surfacePointer]->primary = RrColorNew(inst, 0, 0, 0);
        if (!read_color(db, inst, ctoname, &([value surfacePointer]->secondary)))
            [value surfacePointer]->secondary = RrColorNew(inst, 0, 0, 0);
        if ([value surface].border)
            if (!read_color(db, inst, bcname,
                            &([value surfacePointer]->border_color)))
                [value surfacePointer]->border_color = RrColorNew(inst, 0, 0, 0);
        if ([value surface].interlaced)
            if (!read_color(db, inst, icname,
                            &([value surfacePointer]->interlace_color)))
                [value surfacePointer]->interlace_color = RrColorNew(inst, 0, 0, 0);
        ret = YES;
    }

#if 0
    free(icname);
    free(bcname);
    free(ctoname);
    free(cname);
#endif
    free(rclass);
    return ret;
}

static void set_default_appearance(AZAppearance *a)
{
    [a surfacePointer]->grad = RR_SURFACE_SOLID;
    [a surfacePointer]->relief = RR_RELIEF_FLAT;
    [a surfacePointer]->bevel = RR_BEVEL_1;
    [a surfacePointer]->interlaced = NO;
    [a surfacePointer]->border = NO;
    [a surfacePointer]->primary = RrColorNew([a inst], 0, 0, 0);
    [a surfacePointer]->secondary = RrColorNew([a inst], 0, 0, 0);
}

/* Reads the output from gimp's C-Source file format into valid RGBA data for
   an RrTextureRGBA. */
static RrPixel32* read_c_image(int width, int height, const unsigned char *data)
{
    RrPixel32 *im, *p;
    int i;

    RrPixel32 *_temp = calloc(sizeof(RrPixel32), width*height);
    memcpy(_temp, data, width*height*sizeof(RrPixel32));
    p = im = _temp;
//    p = im = g_memdup(data, width * height * sizeof(RrPixel32));

    for (i = 0; i < width * height; ++i) {
        unsigned char a = ((*p >> 24) & 0xff);
        unsigned char b = ((*p >> 16) & 0xff);
        unsigned char g = ((*p >>  8) & 0xff);
        unsigned char r = ((*p >>  0) & 0xff);

        *p = ((r << RrDefaultRedOffset) +
              (g << RrDefaultGreenOffset) +
              (b << RrDefaultBlueOffset) +
              (a << RrDefaultAlphaOffset));
        p++;
    }

    return im;
}
