// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   popup.c for the Openbox window manager
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

#import "AZPopUp.h"
#import "AZClient.h"
#import "AZScreen.h"
#import "AZStacking.h"
#import "openbox.h"

@implementation AZPopUp
- (void) positionWithGravity: (int) _gravity x: (int) _x y: (int) _y
{
  gravity = _gravity;
  x = _x;
  y = _y;
}

- (void) sizeWithWidth: (int) _w height: (int) _h
{
  w = _w;
  h = _h;
}

- (void) sizeToString: (gchar *) _text
{
  int textw, texth;
  int iconw;

  a_text->texture[0].data.text.string = _text;
  RrMinsize(a_text, &textw, &texth);
  /*XXX textw += ob_rr_theme->bevel * 2;*/
  texth += ob_rr_theme->padding * 2;

  h = texth + ob_rr_theme->padding * 2;
  iconw = (hasicon ? texth : 0);
  w = textw + iconw + ob_rr_theme->padding * (hasicon ? 3 : 2);
}

- (void) setTextAlign: (RrJustify) align
{
  a_text->texture[0].data.text.justify = align;
}

- (void) showText: (gchar *) _text
{
    int l, t, r, b;
    int _x, _y, _w, _h;
    int textw, texth;
    int iconw;
    Rect *area; /* won't go outside this */


    area = [[AZScreen defaultScreen] physicalArea];          
                                               /* XXX this should work quite
                                               good, someone with xinerama,
                                               and different resolutions on
                                               screens? */

    RrMargins(a_bg, &l, &t, &r, &b);

    XSetWindowBorderWidth(ob_display, bg, ob_rr_theme->bwidth);
    XSetWindowBorder(ob_display, bg, ob_rr_theme->b_color->pixel);

    /* set up the textures */
    a_text->texture[0].data.text.string = _text;

    /* measure the shit out */
    RrMinsize(a_text, &textw, &texth);
    /*XXX textw += ob_rr_theme->padding * 2;*/
    texth += ob_rr_theme->padding * 2;

    /* set the sizes up and reget the text sizes from the calculated
       outer sizes */
    if (h) {
        _h = h;
        texth = _h - (t+b + ob_rr_theme->padding * 2);
    } else
        _h = t+b + texth + ob_rr_theme->padding * 2;
    iconw = (hasicon ? texth : 0);
    if (w) {
        _w = w;
        textw = _w - (l+r + iconw + ob_rr_theme->padding *
                     (hasicon ? 3 : 2));
    } else
        _w = l+r + textw + iconw + ob_rr_theme->padding *
            (hasicon ? 3 : 2);
    /* sanity checks to avoid crashes! */
    if (_w < 1) _w = 1;
    if (_h < 1) _h = 1;
    if (textw < 1) textw = 1;
    if (texth < 1) texth = 1;

    /* set up the x coord */
    _x = x;
    switch (gravity) {
    case NorthGravity:
    case CenterGravity:
    case SouthGravity:
        _x -= _w / 2;
        break;
    case NorthEastGravity:
    case EastGravity:
    case SouthEastGravity:
        _x -= _w;
        break;
    }

    /* set up the y coord */
    _y = y;
    switch (gravity) {
    case WestGravity:
    case CenterGravity:
    case EastGravity:
        _y -= _h / 2;
        break;
    case SouthWestGravity:
    case SouthGravity:
    case SouthEastGravity:
        _y -= _h;
        break;
    }

    _x=MAX(MIN(_x, area->width-_w),0);
    _y=MAX(MIN(_y, area->height-_h),0);

    /* set the windows/appearances up */
    XMoveResizeWindow(ob_display, bg, _x, _y, _w, _h);

    a_text->surface.parent = a_bg;
    a_text->surface.parentx = l + iconw +
        ob_rr_theme->padding * (hasicon ? 2 : 1);
    a_text->surface.parenty = t + ob_rr_theme->padding;
    XMoveResizeWindow(ob_display, text,
                      l + iconw + ob_rr_theme->padding *
                      (hasicon ? 2 : 1),
                      t + ob_rr_theme->padding, textw, texth);

    RrPaint(a_bg, bg, _w, _h);
    RrPaint(a_text, text, textw, texth);

    if (hasicon) {
        if (iconw < 1) iconw = 1; /* sanity check for crashes */
	/* draw icon */
	[self drawIconAtX: l + ob_rr_theme->padding
		        y: t + ob_rr_theme->padding
		    width: iconw height: texth];
    }

    if (!mapped) {
        XMapWindow(ob_display, bg);
	[[AZStacking stacking] raiseWindow: self group: NO];
        mapped = TRUE;
    }
}

- (void) hide
{
  if (mapped) {
    XUnmapWindow(ob_display, bg);
    mapped = FALSE;
  }
}

- (id) initWithIcon: (BOOL) hasIcon;
{
  self = [super init];

  XSetWindowAttributes attrib;
  hasicon = hasIcon;
  gravity = NorthWestGravity;
  x = y = w = h = 0;
  a_bg = RrAppearanceCopy(ob_rr_theme->app_hilite_bg);
  a_text = RrAppearanceCopy(ob_rr_theme->app_hilite_label);

  attrib.override_redirect = True;
  bg = XCreateWindow(ob_display, RootWindow(ob_display, ob_screen),
                     0, 0, 1, 1, 0, RrDepth(ob_rr_inst),
                     InputOutput, RrVisual(ob_rr_inst),
                     CWOverrideRedirect, &attrib);

  text = XCreateWindow(ob_display, bg,
                       0, 0, 1, 1, 0, RrDepth(ob_rr_inst),
                       InputOutput, RrVisual(ob_rr_inst), 0, NULL);

  XMapWindow(ob_display, text);

  [[AZStacking stacking] addWindow: self];

  return self;
}

- (void) dealloc
{
  XDestroyWindow(ob_display, bg);
  XDestroyWindow(ob_display, text);
  RrAppearanceFree(a_bg);
  RrAppearanceFree(a_text);
  [[AZStacking stacking] removeWindow: self];
  [super dealloc];
}

- (void) drawIconAtX: (int) x y: (int) y width: (int) w height: (int) h
{
  // subclass responsibility
}

/* AZWindow protocol */
- (Window_InternalType) windowType { return Window_Internal; }
- (int) windowLayer { OB_STACKING_LAYER_INTERNAL; }
- (Window) windowTop { return bg; }

@end

@implementation AZIconPopUp

- (void) drawIconAtX: (int) px y: (int) py width: (int) pw height: (int) ph
{
  a_icon->surface.parent = a_bg;
  a_icon->surface.parentx = px;
  a_icon->surface.parenty = py;
  XMoveResizeWindow(ob_display, icon, px, py, pw, ph);
  RrPaint(a_icon, icon, pw, ph);
}

- (void) showText: (gchar *) _text icon: (AZClientIcon *) _icon
{
  if (_icon) {
    a_icon->texture[0].type = RR_TEXTURE_RGBA;
    a_icon->texture[0].data.rgba.width = [_icon width];
    a_icon->texture[0].data.rgba.height = [_icon height];
    a_icon->texture[0].data.rgba.data = [_icon data];
  } else {
    a_icon->texture[0].type = RR_TEXTURE_NONE;
  }
  [super showText: _text];
}

- (id) initWithIcon: (BOOL) hasIcon;
{
  self = [super initWithIcon: hasIcon];
  a_icon = RrAppearanceCopy(ob_rr_theme->a_clear_tex);
  icon = XCreateWindow(ob_display, bg, 0, 0, 1, 1, 0,
                       RrDepth(ob_rr_inst), InputOutput,
                       RrVisual(ob_rr_inst), 0, NULL);
  XMapWindow(ob_display, icon);
  return self;
}

- (void) dealloc
{
  XDestroyWindow(ob_display, icon);
  RrAppearanceFree(a_icon);
  [super dealloc];
}

@end

@implementation AZPagerPopUp

- (void) drawIconAtX: (int) px y: (int) py width: (int) pw height: (int) ph
{
    int _x, _y;
    unsigned int rown, n;
    unsigned int horz_inc;
    unsigned int vert_inc;
    unsigned int r, c;
    int eachw, eachh;
    AZScreen *screen = [AZScreen defaultScreen];
    DesktopLayout desktop_layout = [screen desktopLayout];

    eachw = (pw - ob_rr_theme->bwidth -
             (desktop_layout.columns * ob_rr_theme->bwidth))
        / desktop_layout.columns;
    eachh = (ph - ob_rr_theme->bwidth -
             (desktop_layout.rows * ob_rr_theme->bwidth))
        / desktop_layout.rows;
    /* make them squares */
    eachw = eachh = MIN(eachw, eachh);

    /* center */
    px += (pw - (desktop_layout.columns * (eachw + ob_rr_theme->bwidth) +
                ob_rr_theme->bwidth)) / 2;
    py += (ph - (desktop_layout.rows * (eachh + ob_rr_theme->bwidth) +
                ob_rr_theme->bwidth)) / 2;

    if (eachw <= 0 || eachh <= 0)
        return;

    switch (desktop_layout.orientation) {
    case OB_ORIENTATION_HORZ:
        switch (desktop_layout.start_corner) {
        case OB_CORNER_TOPLEFT:
            n = 0;
            horz_inc = 1;
            vert_inc = desktop_layout.columns;
            break;
        case OB_CORNER_TOPRIGHT:
            n = desktop_layout.columns - 1;
            horz_inc = -1;
            vert_inc = desktop_layout.columns;
            break;
        case OB_CORNER_BOTTOMRIGHT:
            n = desktop_layout.rows * desktop_layout.columns - 1;
            horz_inc = -1;
            vert_inc = -desktop_layout.columns;
            break;
        case OB_CORNER_BOTTOMLEFT:
            n = (desktop_layout.rows - 1) * desktop_layout.columns;
            horz_inc = 1;
            vert_inc = -desktop_layout.columns;
            break;
        default:
            g_assert_not_reached();
        }
        break;
    case OB_ORIENTATION_VERT:
        switch (desktop_layout.start_corner) {
        case OB_CORNER_TOPLEFT:
            n = 0;
            horz_inc = desktop_layout.rows;
            vert_inc = 1;
            break;
        case OB_CORNER_TOPRIGHT:
            n = desktop_layout.rows * (desktop_layout.columns - 1);
            horz_inc = -desktop_layout.rows;
            vert_inc = 1;
            break;
        case OB_CORNER_BOTTOMRIGHT:
            n = desktop_layout.rows * desktop_layout.columns - 1;
            horz_inc = -desktop_layout.rows;
            vert_inc = -1;
            break;
        case OB_CORNER_BOTTOMLEFT:
            n = desktop_layout.rows - 1;
            horz_inc = desktop_layout.rows;
            vert_inc = -1;
            break;
        default:
            g_assert_not_reached();
        }
        break;
    default:
        g_assert_not_reached();
    }

    rown = n;
    for (r = 0, _y = 0; r < desktop_layout.rows;
         ++r, _y += eachh + ob_rr_theme->bwidth)
    {
        for (c = 0, _x = 0; c < desktop_layout.columns;
             ++c, _x += eachw + ob_rr_theme->bwidth)
        {
            RrAppearance *a;

            if (n < desks) {
                a = (n == curdesk ? hilight : unhilight);

                a->surface.parent = a_bg;
                a->surface.parentx = _x + px;
                a->surface.parenty = _y + py;
                XMoveResizeWindow(ob_display, wins[n],
                                  _x + px, _y + py, eachw, eachh);
                RrPaint(a, wins[n], eachw, eachh);
            }
            n += horz_inc;
        }
        n = rown += vert_inc;
    }
}

- (void) showText: (gchar *) _text desktop: (unsigned int) desk
{
    unsigned int i;
    unsigned int num_desktops = [[AZScreen defaultScreen] numberOfDesktops];

    if (num_desktops < desks)
        for (i = num_desktops; i < desks; ++i)
            XDestroyWindow(ob_display, wins[i]);

    if (num_desktops != desks)
        wins = g_renew(Window, wins, num_desktops);

    if (num_desktops > desks)
        for (i = desks; i < num_desktops; ++i) {
            XSetWindowAttributes attr;

            attr.border_pixel = RrColorPixel(ob_rr_theme->b_color);
            wins[i] = XCreateWindow(ob_display, bg,
                                          0, 0, 1, 1, ob_rr_theme->bwidth,
                                          RrDepth(ob_rr_inst), InputOutput,
                                          RrVisual(ob_rr_inst), CWBorderPixel,
                                          &attr);
            XMapWindow(ob_display, wins[i]);
        }

    desks = num_desktops;
    curdesk = desk;

    [super showText: _text];
}

- (id) initWithIcon: (BOOL) hasIcon;
{
  self = [super initWithIcon: hasIcon];

  desks = 0;
  wins = g_new(Window, desks);
  hilight = RrAppearanceCopy(ob_rr_theme->app_hilite_fg);
  unhilight = RrAppearanceCopy(ob_rr_theme->app_unhilite_fg);

  return self;
}

- (void) dealloc
{
  unsigned int i;

  for (i = 0; i < desks; ++i)
    XDestroyWindow(ob_display, wins[i]);
  g_free(wins);
  RrAppearanceFree(hilight);
  RrAppearanceFree(unhilight);
  [super dealloc];
}

@end

