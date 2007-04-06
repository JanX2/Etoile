/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZMenuFrame.h for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

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

#import "window.h"
#import <Foundation/Foundation.h>
#import "geom.h"
#import "render/render.h"

@class AZMenu;
@class AZMenuEntry;
@class AZMenuEntryFrame;
@class AZClient;

@interface AZMenuFrame: NSObject <AZWindow>
{    
  Window window;

  AZMenu *menu;

  /* The client that the visual instance of the menu is associated with for
     its actions */
  AZClient *client;

  AZMenuFrame *parent;
  AZMenuEntryFrame *parent_entry;
  AZMenuFrame *child;

  NSMutableArray *entries;
  AZMenuEntryFrame *selected;

  /* If the submenus are being drawn to the right or the left */
  BOOL direction_right;

  /* If a titlebar is displayed for the menu or not (for top-level menus) */
  BOOL show_title;

  /* On-screen area (including borders!) */
  Rect area;
  Strut item_margin;
  int inner_w; /* inside the borders */
  int title_h; /* includes the bwidth below it */
  int item_h;  /* height of all normal items */
  int text_x;  /* offset at which the text appears in the items */
  int text_w;  /* width of the text area in the items */

  int monitor; /* monitor on which to show the menu in xinerama */

  Window title;
  Window items;

  AZAppearance *a_title;
  AZAppearance *a_items;
}

+ (NSMutableArray *) visibleFrames;

- (void) moveToX: (int) x y: (int) y;
- (void) moveOnScreenToX: (int *) x y: (int *) y;
- (void) placeTopMenuAtX: (int) x y: (int) y;
- (void) placeSubmenu;
- (BOOL) showTopMenuAtX: (int) x y: (int) y;
- (BOOL) showSubmenuWithParent: (AZMenuFrame *) parent 
                         entry: (AZMenuEntryFrame *) parent_entry;
- (void) hide;
- (void) selectMenuEntryFrame: (AZMenuEntryFrame *) entry;
- (void) selectPrevious;
- (void) selectNext;

/* Accessories */
- (Rect) area;
- (AZMenuFrame *) parent;
- (AZMenuFrame *) child;
- (AZMenuEntryFrame *) selected;
- (int) monitor;
- (AZMenu *) menu;
- (AZClient *) client;
- (void) set_child: (AZMenuFrame *) child;
- (void) set_parent: (AZMenuFrame *) parent;
- (void) set_monitor: (int) monitor;

- (Window) items;
- (Window) window;
- (int) item_h;
- (int) title_h;
- (int) inner_w;
- (AZAppearance *) a_items;
- (int) text_x;
- (int) text_w;
- (Strut) item_margin;
- (NSArray *) entries;
- (void) set_show_title: (BOOL) show_title;

- (void) set_direction_right: (BOOL) direction_right;
- (BOOL) direction_right;

- (id) initWithMenu: (AZMenu *) menu client: (AZClient *) client;

/* Private */
- (void) render;
- (void) update;

@end

@interface AZMenuEntryFrame: NSObject
{
    AZMenuEntry *entry;
    AZMenuFrame *frame;

    Rect area;

    Window window;
    Window icon;
    Window text;
    Window bullet;

    AZAppearance *a_normal;
    AZAppearance *a_disabled;
    AZAppearance *a_selected;

    AZAppearance *a_icon;
    AZAppearance *a_mask;
    AZAppearance *a_bullet_normal;
    AZAppearance *a_bullet_selected;
    AZAppearance *a_separator;
    AZAppearance *a_text_normal;
    AZAppearance *a_text_disabled;
    AZAppearance *a_text_selected;
}

- (id) initWithMenuEntry: (AZMenuEntry *) entry 
               menuFrame: (AZMenuFrame *) frame;
- (void) render;
- (void) showSubmenu;
- (void) execute: (unsigned int) state time: (Time) time;

/* accessories */
- (Rect) area;
- (void) set_area: (Rect) area;
- (AZAppearance *) a_text_normal;
- (AZAppearance *) a_text_disabled;
- (AZAppearance *) a_text_selected;
- (AZAppearance *) a_normal;
- (AZAppearance *) a_selected;
- (AZAppearance *) a_disabled;
- (Window) window;
- (AZMenuEntry *) entry;
- (void) set_entry: (AZMenuEntry *) entry;

@end

void AZMenuFrameHideAllClient(AZClient *client);
void AZMenuFrameHideAll();
AZMenuFrame *AZMenuFrameUnder(int x, int y);
AZMenuEntryFrame* AZMenuEntryFrameUnder(int x, int y);

