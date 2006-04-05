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

- (void) renderLabel: (RrAppearance *) a;
- (void) renderIcon: (RrAppearance *) a;
- (void) renderMax: (RrAppearance *) a;
- (void) renderIconify: (RrAppearance *) a;
- (void) renderDesk: (RrAppearance *) a;
- (void) renderShade: (RrAppearance *) a;
- (void) renderClose: (RrAppearance *) a;

@end

@implementation AZFrame (AZRender)

- (void) render
{
    {
        gulong px;

        px = ([self focused] ?
              RrColorPixel(ob_rr_theme->cb_focused_color) :
              RrColorPixel(ob_rr_theme->cb_unfocused_color));
        XSetWindowBackground(ob_display, [self plate], px);
        XClearWindow(ob_display, [self plate]);
    }

    if (decorations & OB_FRAME_DECOR_TITLEBAR) {
        RrAppearance *t, *l, *m, *n, *i, *d, *s, *c;
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

        RrPaint(t, [self title], width, ob_rr_theme->title_height);

        ob_rr_theme->a_clear->surface.parent = t;
        ob_rr_theme->a_clear->surface.parentx = 0;
        ob_rr_theme->a_clear->surface.parenty = 0;

        RrPaint(ob_rr_theme->a_clear, [self tlresize],
                ob_rr_theme->grip_width, ob_rr_theme->handle_height);

        ob_rr_theme->a_clear->surface.parentx =
            width - ob_rr_theme->grip_width;

        RrPaint(ob_rr_theme->a_clear, [self trresize],
                ob_rr_theme->grip_width, ob_rr_theme->handle_height);


        /* set parents for any parent relative guys */
        l->surface.parent = t;
        l->surface.parentx = label_x;
        l->surface.parenty = ob_rr_theme->padding;

        m->surface.parent = t;
        m->surface.parentx = max_x;
        m->surface.parenty = ob_rr_theme->padding + 1;

        n->surface.parent = t;
        n->surface.parentx = icon_x;
        n->surface.parenty = ob_rr_theme->padding;

        i->surface.parent = t;
        i->surface.parentx = iconify_x;
        i->surface.parenty = ob_rr_theme->padding + 1;

        d->surface.parent = t;
        d->surface.parentx = desk_x;
        d->surface.parenty = ob_rr_theme->padding + 1;

        s->surface.parent = t;
        s->surface.parentx = shade_x;
        s->surface.parenty = ob_rr_theme->padding + 1;

        c->surface.parent = t;
        c->surface.parentx = close_x;
        c->surface.parenty = ob_rr_theme->padding + 1;

	[self renderLabel: l];
	[self renderMax: m];
	[self renderIcon: n];
	[self renderIconify: i];
	[self renderDesk: d];
	[self renderShade: s];
	[self renderClose: c];
    }

    if (decorations & OB_FRAME_DECOR_HANDLE) {
        RrAppearance *h, *g;

        h = ([self focused] ?
             a_focused_handle : a_unfocused_handle);

        RrPaint(h, [self handle], width, ob_rr_theme->handle_height);

        if (decorations & OB_FRAME_DECOR_GRIPS) {
            g = ([self focused] ?
                 ob_rr_theme->a_focused_grip : ob_rr_theme->a_unfocused_grip);

            if (g->surface.grad == RR_SURFACE_PARENTREL)
                g->surface.parent = h;

            g->surface.parentx = 0;
            g->surface.parenty = 0;

            RrPaint(g, [self lgrip],
                    ob_rr_theme->grip_width, ob_rr_theme->handle_height);

            g->surface.parentx = width - ob_rr_theme->grip_width;
            g->surface.parenty = 0;

            RrPaint(g, [self rgrip],
                    ob_rr_theme->grip_width, ob_rr_theme->handle_height);
        }
    }

    XFlush(ob_display);
}

@end

@implementation AZFrame (AZRenderPrivate)
- (void) renderLabel: (RrAppearance *) a;
{
    if (label_x < 0) return;
    /* set the texture's text! */
    a->texture[0].data.text.string = [[self client] title];
    RrPaint(a, [self label], label_width, ob_rr_theme->label_height);
}

- (void) renderIcon: (RrAppearance *) a;
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
        a->texture[0].type = RR_TEXTURE_RGBA;
        a->texture[0].data.rgba.width = [_icon width] /*_icon->width*/;
        a->texture[0].data.rgba.height = [_icon height] /*_icon->height*/;
        a->texture[0].data.rgba.data = [_icon data] /*_icon->data*/;
    } else
        a->texture[0].type = RR_TEXTURE_NONE;

    RrPaint(a, [self icon],
            ob_rr_theme->button_size + 2, ob_rr_theme->button_size + 2);
}

- (void) renderMax: (RrAppearance *) a;
{
    if (max_x < 0) return;
    RrPaint(a, [self max], ob_rr_theme->button_size, ob_rr_theme->button_size);
}

- (void) renderIconify: (RrAppearance *) a;
{
    if (iconify_x < 0) return;
    RrPaint(a, [self iconify],
            ob_rr_theme->button_size, ob_rr_theme->button_size);
}

- (void) renderDesk: (RrAppearance *) a;
{
    if (desk_x < 0) return;
    RrPaint(a, [self desk], ob_rr_theme->button_size, ob_rr_theme->button_size);
}

- (void) renderShade: (RrAppearance *) a;
{
    if (shade_x < 0) return;
    RrPaint(a, [self shade],
            ob_rr_theme->button_size, ob_rr_theme->button_size);
}

- (void) renderClose: (RrAppearance *) a;
{
    if (close_x < 0) return;
    RrPaint(a, [self close],
            ob_rr_theme->button_size, ob_rr_theme->button_size);
}

@end

