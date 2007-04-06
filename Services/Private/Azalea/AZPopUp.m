/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZPopUp.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

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

- (void) sizeToString: (NSString *) _text
{
  int textw, texth;
  int iconw;

  [a_text texture][0].data.text.string = _text;
  [a_text minimalSizeWithWidth: &textw height: &texth];
  /*XXX textw += ob_rr_theme->bevel * 2;*/
  texth += ob_rr_theme->padding * 2;

  h = texth + ob_rr_theme->padding * 2;
  iconw = (hasicon ? texth : 0);
  w = textw + iconw + ob_rr_theme->padding * (hasicon ? 3 : 2);
}

- (void) setTextAlign: (RrJustify) align
{
  [a_text texture][0].data.text.justify = align;
}

- (void) showText: (NSString *) _text
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

    [a_bg marginsWithLeft: &l top: &t right: &r bottom: &b];

    XSetWindowBorderWidth(ob_display, bg, ob_rr_theme->bwidth);
    XSetWindowBorder(ob_display, bg, ob_rr_theme->b_color->pixel);

    /* set up the textures */
    [a_text texture][0].data.text.string = _text;

    /* measure the shit out */
    [a_text minimalSizeWithWidth: &textw height: &texth];
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

    [a_text surfacePointer]->parent = a_bg;
    [a_text surfacePointer]->parentx = l + iconw +
        ob_rr_theme->padding * (hasicon ? 2 : 1);
    [a_text surfacePointer]->parenty = t + ob_rr_theme->padding;
    XMoveResizeWindow(ob_display, text,
                      l + iconw + ob_rr_theme->padding *
                      (hasicon ? 2 : 1),
                      t + ob_rr_theme->padding, textw, texth);

    [a_bg paint: bg width: _w height: _h];
    [a_text paint: text width: textw height: texth];

    if (hasicon) {
        if (iconw < 1) iconw = 1; /* sanity check for crashes */
	/* draw icon */
	[self drawIconAtX: l + ob_rr_theme->padding
		        y: t + ob_rr_theme->padding
		    width: iconw height: texth];
    }

    if (!mapped) {
        XMapWindow(ob_display, bg);
	[[AZStacking stacking] raiseWindow: self];
        mapped = YES;
    }
}

- (void) hide
{
  if (mapped) {
    XUnmapWindow(ob_display, bg);
    mapped = NO;
  }
}

- (id) initWithIcon: (BOOL) hasIcon;
{
  self = [super init];

  XSetWindowAttributes attrib;
  hasicon = hasIcon;
  gravity = NorthWestGravity;
  x = y = w = h = 0;
  a_bg = [ob_rr_theme->app_hilite_bg copy];
  a_text = [ob_rr_theme->app_hilite_label copy];

  attrib.override_redirect = True;
  bg = XCreateWindow(ob_display, RootWindow(ob_display, ob_screen),
                     0, 0, 1, 1, 0, [ob_rr_inst depth],
                     InputOutput, [ob_rr_inst visual],
                     CWOverrideRedirect, &attrib);

  text = XCreateWindow(ob_display, bg,
                       0, 0, 1, 1, 0, [ob_rr_inst depth],
                       InputOutput, [ob_rr_inst visual], 0, NULL);

  XMapWindow(ob_display, text);

  [[AZStacking stacking] addWindow: self];

  return self;
}

- (void) dealloc
{
  XDestroyWindow(ob_display, bg);
  XDestroyWindow(ob_display, text);
  DESTROY(a_bg);
  DESTROY(a_text);
  [[AZStacking stacking] removeWindow: self];
  [super dealloc];
}

- (void) drawIconAtX: (int) x y: (int) y width: (int) w height: (int) h
{
  // subclass responsibility
}

/* AZWindow protocol */
- (Window_InternalType) windowType { return Window_Internal; }
- (int) windowLayer { return OB_STACKING_LAYER_INTERNAL; }
- (Window) windowTop { return bg; }

@end

@implementation AZIconPopUp

- (void) drawIconAtX: (int) px y: (int) py width: (int) pw height: (int) ph
{
  [a_icon surfacePointer]->parent = a_bg;
  [a_icon surfacePointer]->parentx = px;
  [a_icon surfacePointer]->parenty = py;
  XMoveResizeWindow(ob_display, icon, px, py, pw, ph);
  [a_icon paint: icon width: pw height: ph];
}

- (void) showText: (NSString *) _text icon: (AZClientIcon *) _icon
{
  if (_icon) {
    [a_icon texture][0].type = RR_TEXTURE_RGBA;
    [a_icon texture][0].data.rgba.width = [_icon width];
    [a_icon texture][0].data.rgba.height = [_icon height];
    [a_icon texture][0].data.rgba.data = [_icon data];
  } else {
    [a_icon texture][0].type = RR_TEXTURE_NONE;
  }
  [super showText: _text];
}

- (id) initWithIcon: (BOOL) hasIcon;
{
  self = [super initWithIcon: hasIcon];
  a_icon = [ob_rr_theme->a_clear_tex copy];
  icon = XCreateWindow(ob_display, bg, 0, 0, 1, 1, 0,
                       [ob_rr_inst depth], InputOutput,
                       [ob_rr_inst visual], 0, NULL);
  XMapWindow(ob_display, icon);
  return self;
}

- (void) dealloc
{
  XDestroyWindow(ob_display, icon);
  DESTROY(a_icon);
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
	    NSAssert(0, @"Should not reach here");
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
	    NSAssert(0, @"Should not reach here");
        }
        break;
    default:
	NSAssert(0, @"Should not reach here");
    }

    rown = n;
    for (r = 0, _y = 0; r < desktop_layout.rows;
         ++r, _y += eachh + ob_rr_theme->bwidth)
    {
        for (c = 0, _x = 0; c < desktop_layout.columns;
             ++c, _x += eachw + ob_rr_theme->bwidth)
        {
            AZAppearance *a;

            if (n < desks) {
                a = (n == curdesk ? hilight : unhilight);

                [a surfacePointer]->parent = a_bg;
                [a surfacePointer]->parentx = _x + px;
                [a surfacePointer]->parenty = _y + py;
                XMoveResizeWindow(ob_display, 
				  [[wins objectAtIndex: n] intValue],
                                  _x + px, _y + py, eachw, eachh);
                [a paint: [[wins objectAtIndex: n] intValue]
			width: eachw height: eachh];
            }
            n += horz_inc;
        }
        n = rown += vert_inc;
    }
}

- (void) showText: (NSString *) _text desktop: (unsigned int) desk
{
    unsigned int i;
    unsigned int num_desktops = [[AZScreen defaultScreen] numberOfDesktops];

    if (num_desktops < desks) {
        for (i = desks-1; i >= num_desktops; i--) {
            XDestroyWindow(ob_display, [[wins objectAtIndex: i] intValue]);
	    [wins removeObjectAtIndex: i];
	}
    }

    if (num_desktops > desks)
        for (i = desks; i < num_desktops; ++i) {
            XSetWindowAttributes attr;

            attr.border_pixel = RrColorPixel(ob_rr_theme->b_color);
            [wins addObject: [NSNumber numberWithInt:XCreateWindow(ob_display, bg,
                                          0, 0, 1, 1, ob_rr_theme->bwidth,
                                          [ob_rr_inst depth], InputOutput,
                                          [ob_rr_inst visual], CWBorderPixel,
                                          &attr)]];
            XMapWindow(ob_display, [[wins objectAtIndex: i] intValue]);
        }

    desks = num_desktops;
    curdesk = desk;

    [super showText: _text];
}

- (id) initWithIcon: (BOOL) hasIcon;
{
  self = [super initWithIcon: hasIcon];

  desks = 0;
  wins = [[NSMutableArray alloc] init];
  hilight = [ob_rr_theme->app_hilite_fg copy];
  unhilight = [ob_rr_theme->app_unhilite_fg copy];

  return self;
}

- (void) dealloc
{
  unsigned int i;

  for (i = 0; i < desks; ++i)
    XDestroyWindow(ob_display, [[wins objectAtIndex: i] intValue]);
  DESTROY(wins);
  DESTROY(hilight);
  DESTROY(unhilight);
  [super dealloc];
}

@end

