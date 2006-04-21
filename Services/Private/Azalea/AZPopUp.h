/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZPopUp.h for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   popup.h for the Openbox window manager
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

#import <Foundation/Foundation.h>
#import "render/render.h"
#import "window.h"

#define POPUP_WIDTH 320
#define POPUP_HEIGHT 48

@interface AZPopUp: NSObject <AZWindow>
{
  Window bg;

  Window text;

  BOOL hasicon;
  AZAppearance *a_bg;
  AZAppearance *a_text;
  int gravity;
  int x;
  int y;
  int w;
  int h;
  BOOL mapped;
}
- (id) initWithIcon: (BOOL) hasIcon;
/*! Position the popup. The gravity rules are not the same X uses for windows,
    instead of the position being the top-left of the window, the gravity
    specifies which corner of the popup will be placed at the given coords.
    Static and Forget gravity are equivilent to NorthWest.
 */
- (void) positionWithGravity: (int) gravity x: (int) x y: (int) y;

/*! Set the sizes for the popup. When set to 0, the size will be based on
    the text size. */
- (void) sizeWithWidth: (int) w height: (int) h;
- (void) sizeToString: (NSString *) text;
- (void) setTextAlign: (RrJustify) align;
- (void) showText: (NSString *) text;
- (void) hide;

/* Subclass to implement this one to draw their own icon */
- (void) drawIconAtX: (int) x y: (int) y width: (int) w height: (int) h;

@end

@class AZClientIcon;

@interface AZIconPopUp: AZPopUp
{
  Window icon;
  AZAppearance *a_icon;
}

- (void) showText: (NSString *) text icon: (AZClientIcon *) icon;
@end

@interface AZPagerPopUp: AZPopUp
{
  unsigned int desks;
  unsigned int curdesk;
  Window *wins;
  AZAppearance *hilight;
  AZAppearance *unhilight;
};

- (void) showText: (NSString *) text desktop: (unsigned int) desk;

@end

