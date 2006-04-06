// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   menuframe.h for the Openbox window manager
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

#import "menuframe.h"
#import "menu.h"
#import <Foundation/Foundation.h>

@interface AZMenuEntryFrame: NSObject
{
    struct _ObMenuEntry *entry;
    ObMenuFrame *frame;

    Rect area;

    Window window;
    Window icon;
    Window text;
    Window bullet;

    RrAppearance *a_normal;
    RrAppearance *a_disabled;
    RrAppearance *a_selected;

    RrAppearance *a_icon;
    RrAppearance *a_mask;
    RrAppearance *a_bullet_normal;
    RrAppearance *a_bullet_selected;
    RrAppearance *a_separator;
    RrAppearance *a_text_normal;
    RrAppearance *a_text_disabled;
    RrAppearance *a_text_selected;
}

- (id) initWithMenuEntry: (ObMenuEntry *) entry 
               menuFrame: (ObMenuFrame *) frame;
- (void) render;
- (void) showSubmenu;
- (void) execute: (unsigned int) state;

/* accessories */
- (Rect) area;
- (void) set_area: (Rect) area;
- (RrAppearance *) a_text_normal;
- (RrAppearance *) a_text_disabled;
- (RrAppearance *) a_text_selected;
- (RrAppearance *) a_normal;
- (RrAppearance *) a_selected;
- (RrAppearance *) a_disabled;
- (Window) window;
- (struct _ObMenuEntry *) entry;
- (void) set_entry: (struct _ObMenuEntry *) entry;

@end

AZMenuEntryFrame* AZMenuEntryFrameUnder(int x, int y);

