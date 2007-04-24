// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   framerender.c for the Openbox window manager
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

#import "AZFrame+Render.h"
#import "AZScreen.h"
#import "openbox.h"
#import "AZClient.h"
#import "render/theme.h"

@interface AZFrame (AZRenderPrivate)

- (void) renderLabel: (AZAppearance *) a;
- (void) renderIcon: (AZAppearance *) a;
- (void) renderMax: (AZAppearance *) a;
- (void) renderIconify: (AZAppearance *) a;
- (void) renderDesk: (AZAppearance *) a;
- (void) renderShade: (AZAppearance *) a;
- (void) renderClose: (AZAppearance *) a;

@end

@implementation AZFrame (AZRender)

- (void) render
{
    {
        unsigned long px;

        px = ([self focused] ?
              RrColorPixel(ob_rr_theme->cb_focused_color) :
              RrColorPixel(ob_rr_theme->cb_unfocused_color));
        XSetWindowBackground(ob_display, [self inner], px);
        XClearWindow(ob_display, [self inner]);
    }

    if (decorations & OB_FRAME_DECOR_TITLEBAR) {
        AZAppearance *t, *l, *m, *n, *i, *d, *s, *c;
        if ([self focused]) {

          t = a_focused_title;
          l = a_focused_label;
          m = (!(decorations & OB_FRAME_DECOR_MAXIMIZE) ?
              ob_rr_theme->a_disabled_focused_max :
              ([[self client] max_vert] || [[self client] max_horz] ?
               ob_rr_theme->a_toggled_focused_max :
               ([self max_press] ?
                ob_rr_theme->a_focused_pressed_max :
                ([self max_hover] ?
                 ob_rr_theme->a_hover_focused_max : 
                 ob_rr_theme->a_focused_unpressed_max))));
          n = a_icon;
          i = (!(decorations & OB_FRAME_DECOR_ICONIFY) ?
              ob_rr_theme->a_disabled_focused_iconify :
              ([self iconify_press] ?
               ob_rr_theme->a_focused_pressed_iconify :
               ([self iconify_hover] ?
                ob_rr_theme->a_hover_focused_iconify : 
                ob_rr_theme->a_focused_unpressed_iconify)));
          d = (!(decorations & OB_FRAME_DECOR_ALLDESKTOPS) ?
              ob_rr_theme->a_disabled_focused_desk :
              ([[self client] desktop] == DESKTOP_ALL ?
               ob_rr_theme->a_toggled_focused_desk :
               ([self desk_press] ?
                ob_rr_theme->a_focused_pressed_desk :
                ([self desk_hover] ?
                 ob_rr_theme->a_hover_focused_desk : 
                 ob_rr_theme->a_focused_unpressed_desk))));
          s = (!(decorations & OB_FRAME_DECOR_SHADE) ?
              ob_rr_theme->a_disabled_focused_shade :
              ([[self client] shaded] ?
               ob_rr_theme->a_toggled_focused_shade :
               ([self shade_press] ?
                ob_rr_theme->a_focused_pressed_shade :
                ([self shade_hover] ?
                 ob_rr_theme->a_hover_focused_shade : 
                 ob_rr_theme->a_focused_unpressed_shade))));
          c = (!(decorations & OB_FRAME_DECOR_CLOSE) ?
              ob_rr_theme->a_disabled_focused_close :
              ([self close_press] ?
               ob_rr_theme->a_focused_pressed_close :
               ([self close_hover] ?
                ob_rr_theme->a_hover_focused_close : 
                ob_rr_theme->a_focused_unpressed_close)));
        } else {

          t = a_unfocused_title;
          l = a_unfocused_label;
          m = (!(decorations & OB_FRAME_DECOR_MAXIMIZE) ?
              ob_rr_theme->a_disabled_unfocused_max :
              ([[self client] max_vert] || [[self client] max_horz] ?
               ob_rr_theme->a_toggled_unfocused_max :
               ([self max_press] ?
                ob_rr_theme->a_unfocused_pressed_max :
                ([self max_hover] ?
                 ob_rr_theme->a_hover_unfocused_max : 
                 ob_rr_theme->a_unfocused_unpressed_max))));
          n = a_icon;
          i = (!(decorations & OB_FRAME_DECOR_ICONIFY) ?
              ob_rr_theme->a_disabled_unfocused_iconify :
              ([self iconify_press] ?
               ob_rr_theme->a_unfocused_pressed_iconify :
               ([self iconify_hover] ?
                ob_rr_theme->a_hover_unfocused_iconify : 
                ob_rr_theme->a_unfocused_unpressed_iconify)));
          d = (!(decorations & OB_FRAME_DECOR_ALLDESKTOPS) ?
              ob_rr_theme->a_disabled_unfocused_desk :
              ([[self client] desktop] == DESKTOP_ALL ?
               ob_rr_theme->a_toggled_unfocused_desk :
               ([self desk_press] ?
                ob_rr_theme->a_unfocused_pressed_desk :
                ([self desk_hover] ?
                 ob_rr_theme->a_hover_unfocused_desk : 
                 ob_rr_theme->a_unfocused_unpressed_desk))));
          s = (!(decorations & OB_FRAME_DECOR_SHADE) ?
              ob_rr_theme->a_disabled_unfocused_shade :
              ([[self client] shaded] ?
               ob_rr_theme->a_toggled_unfocused_shade :
               ([self shade_press] ?
                ob_rr_theme->a_unfocused_pressed_shade :
                ([self shade_hover] ?
                 ob_rr_theme->a_hover_unfocused_shade : 
                 ob_rr_theme->a_unfocused_unpressed_shade))));
          c = (!(decorations & OB_FRAME_DECOR_CLOSE) ?
              ob_rr_theme->a_disabled_unfocused_close :
              ([self close_press] ?
               ob_rr_theme->a_unfocused_pressed_close :
               ([self close_hover] ?
                ob_rr_theme->a_hover_unfocused_close : 
                ob_rr_theme->a_unfocused_unpressed_close)));
        }

        [t paint: [self title] width: width height: ob_rr_theme->title_height];

        [ob_rr_theme->a_clear surfacePointer]->parent = t;
        [ob_rr_theme->a_clear surfacePointer]->parentx = 0;
        [ob_rr_theme->a_clear surfacePointer]->parenty = 0;

        [ob_rr_theme->a_clear paint: [self tlresize]
                width: ob_rr_theme->grip_width height: ob_rr_theme->handle_height];

        [ob_rr_theme->a_clear surfacePointer]->parentx =
            width - ob_rr_theme->grip_width;

        [ob_rr_theme->a_clear paint: [self trresize]
                width: ob_rr_theme->grip_width 
		height: ob_rr_theme->handle_height];


        /* set parents for any parent relative guys */
        [l surfacePointer]->parent = t;
        [l surfacePointer]->parentx = label_x;
        [l surfacePointer]->parenty = ob_rr_theme->padding;

        [m surfacePointer]->parent = t;
        [m surfacePointer]->parentx = max_x;
        [m surfacePointer]->parenty = ob_rr_theme->padding + 1;

        [n surfacePointer]->parent = t;
        [n surfacePointer]->parentx = icon_x;
        [n surfacePointer]->parenty = ob_rr_theme->padding;

        [i surfacePointer]->parent = t;
        [i surfacePointer]->parentx = iconify_x;
        [i surfacePointer]->parenty = ob_rr_theme->padding + 1;

        [d surfacePointer]->parent = t;
        [d surfacePointer]->parentx = desk_x;
        [d surfacePointer]->parenty = ob_rr_theme->padding + 1;

        [s surfacePointer]->parent = t;
        [s surfacePointer]->parentx = shade_x;
        [s surfacePointer]->parenty = ob_rr_theme->padding + 1;

        [c surfacePointer]->parent = t;
        [c surfacePointer]->parentx = close_x;
        [c surfacePointer]->parenty = ob_rr_theme->padding + 1;

	[self renderLabel: l];
	[self renderMax: m];
	[self renderIcon: n];
	[self renderIconify: i];
	[self renderDesk: d];
	[self renderShade: s];
	[self renderClose: c];
    }

    if (decorations & OB_FRAME_DECOR_HANDLE) {
        AZAppearance *h, *g;

        h = ([self focused] ?
             a_focused_handle : a_unfocused_handle);

        [h paint: [self handle] width: width height: ob_rr_theme->handle_height];

        if (decorations & OB_FRAME_DECOR_GRIPS) {
            g = ([self focused] ?
                 ob_rr_theme->a_focused_grip : ob_rr_theme->a_unfocused_grip);

            if ([g surface].grad == RR_SURFACE_PARENTREL)
                [g surfacePointer]->parent = h;

            [g surfacePointer]->parentx = 0;
            [g surfacePointer]->parenty = 0;

            [g paint: [self lgrip]
                    width: ob_rr_theme->grip_width
		    height: ob_rr_theme->handle_height];

            [g surfacePointer]->parentx = width - ob_rr_theme->grip_width;
            [g surfacePointer]->parenty = 0;

            [g paint: [self rgrip]
                    width: ob_rr_theme->grip_width
		    height: ob_rr_theme->handle_height];
        }
    }

    XFlush(ob_display);
}

@end

@implementation AZFrame (AZRenderPrivate)
- (void) renderLabel: (AZAppearance *) a;
{
    if (label_x < 0) return;
    /* set the texture's text! */
    [a texture][0].data.text.string = [[self client] title];
    [a paint: [self label] width: label_width height: ob_rr_theme->label_height];
}

- (void) renderIcon: (AZAppearance *) a;
{
    AZClientIcon *_icon;

    if (icon_x < 0) return;

    _icon = [([self client]) iconWithWidth: ob_rr_theme->button_size + 2
	                          height: ob_rr_theme->button_size + 2];
#if 0
    _icon = client_icon([self client],
                       ob_rr_theme->button_size + 2,
                       ob_rr_theme->button_size + 2);
#endif
    if (_icon) {
        [a texture][0].type = RR_TEXTURE_RGBA;
        [a texture][0].data.rgba.width = [_icon width] /*_icon->width*/;
        [a texture][0].data.rgba.height = [_icon height] /*_icon->height*/;
        [a texture][0].data.rgba.data = [_icon data] /*_icon->data*/;
    } else
        [a texture][0].type = RR_TEXTURE_NONE;

    [a paint: [self icon]
            width: ob_rr_theme->button_size + 2
	    height: ob_rr_theme->button_size + 2];
}

- (void) renderMax: (AZAppearance *) a;
{
    if (max_x < 0) return;
    [a paint: [self max]
	    width: ob_rr_theme->button_size
	    height: ob_rr_theme->button_size];
}

- (void) renderIconify: (AZAppearance *) a;
{
    if (iconify_x < 0) return;
    [a paint: [self iconify]
            width: ob_rr_theme->button_size
	    height: ob_rr_theme->button_size];
}

- (void) renderDesk: (AZAppearance *) a;
{
    if (desk_x < 0) return;
    [a paint: [self desk]
	    width: ob_rr_theme->button_size
	    height: ob_rr_theme->button_size];
}

- (void) renderShade: (AZAppearance *) a;
{
    if (shade_x < 0) return;
    [a paint: [self shade]
            width: ob_rr_theme->button_size
	    height: ob_rr_theme->button_size];
}

- (void) renderClose: (AZAppearance *) a;
{
    if (close_x < 0) return;
    [a paint: [self close]
            width: ob_rr_theme->button_size
	    height: ob_rr_theme->button_size];
}

@end

