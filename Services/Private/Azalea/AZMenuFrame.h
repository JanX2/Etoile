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

#import "menu.h"
#import "window.h"
#import <Foundation/Foundation.h>

struct _ObMenuEntry;
@class AZMenuEntryFrame;
@class AZClient;

extern GList *menu_frame_visible;

@interface AZMenuFrame: NSObject <AZWindow>
{    
  Window window;

  struct _ObMenu *menu;

  /* The client that the visual instance of the menu is associated with for
     its actions */
  AZClient *client;

  AZMenuFrame *parent;
  AZMenuFrame *child;

  GList *entries;
  AZMenuEntryFrame *selected;

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

  RrAppearance *a_title;
  RrAppearance *a_items;
}

- (void) moveToX: (int) x y: (int) y;
- (void) moveOnScreen;
- (BOOL) showWithParent: (AZMenuFrame *) parent;
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
- (struct _ObMenu *) menu;
- (AZClient *) client;
- (void) set_child: (AZMenuFrame *) child;
- (void) set_parent: (AZMenuFrame *) parent;
- (void) set_monitor: (int) monitor;

- (Window) items;
- (Window) window;
- (int) item_h;
- (int) title_h;
- (int) inner_w;
- (RrAppearance *) a_items;
- (int) text_x;
- (int) text_w;
- (Strut) item_margin;
- (GList *) entries;
- (void) set_show_title: (BOOL) show_title;

- (id) initWithMenu: (struct _ObMenu *) menu client: (AZClient *) client;

/* Private */
- (void) render;
- (void) update;

@end

@interface AZMenuEntryFrame: NSObject
{
    struct _ObMenuEntry *entry;
    AZMenuFrame *frame;

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
               menuFrame: (AZMenuFrame *) frame;
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

void AZMenuFrameHideAllClient(AZClient *client);
void AZMenuFrameHideAll();
AZMenuFrame *AZMenuFrameUnder(int x, int y);
AZMenuEntryFrame* AZMenuEntryFrameUnder(int x, int y);

