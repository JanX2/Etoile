// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   menu.h for the Openbox window manager
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

struct _ObMenu;

typedef enum
{
    OB_MENU_ENTRY_TYPE_NORMAL,
    OB_MENU_ENTRY_TYPE_SUBMENU,
    OB_MENU_ENTRY_TYPE_SEPARATOR
} ObMenuEntryType;

@interface AZMenuEntry: NSObject
{
    ObMenuEntryType type;
    struct _ObMenu *menu;
    int identifier;
}
- (id) initWithMenu: (struct _ObMenu *) menu identifier: (int) identifier;

/* accessories */
- (ObMenuEntryType) type;
- (struct _ObMenu *) menu;
- (int) identifier;
- (void) set_type: (ObMenuEntryType) type;
- (void) set_menu: (struct _ObMenu *) menu;
- (void) set_identifier: (int) identifier;

@end

@interface AZIconMenuEntry: AZMenuEntry
{
    /* Icon shit */
    int icon_width;
    int icon_height;
    RrPixel32 *icon_data;

    /* Mask icon */
    RrPixmapMask *mask;
    RrColor *mask_normal_color;
    RrColor *mask_disabled_color;
    RrColor *mask_selected_color;
}
- (int) icon_width;
- (int) icon_height;
- (RrPixel32 *) icon_data;
- (RrPixmapMask *) mask;
- (RrColor *) mask_normal_color;
- (RrColor *) mask_disabled_color;
- (RrColor *) mask_selected_color;
- (void) set_icon_width: (int) icon_width;
- (void) set_icon_height: (int) icon_height;
- (void) set_icon_data: (RrPixel32 *) icon_data;
- (void) set_mask: (RrPixmapMask *) mask;
- (void) set_mask_normal_color: (RrColor *) mask_normal_color;
- (void) set_mask_disabled_color: (RrColor *) mask_disabled_color;
- (void) set_mask_selected_color: (RrColor *) mask_selected_color;

@end

@interface AZNormalMenuEntry: AZIconMenuEntry
{
    gchar *label;

    /* state */
    BOOL enabled;

    /* List of ObActions */
    GSList *actions;

}

- (id) initWithMenu: (struct _ObMenu *) menu identifier: (int) identifier label: (gchar *) label actions: (GSList *) actions;
         
/* Accessories */
- (gchar *)label;
- (BOOL) enabled;
- (GSList *) actions;
- (void) set_label: (gchar *)label;
- (void) set_enabled: (BOOL) enabled;
- (void) set_actions: (GSList *) actions;
@end

@interface AZSubmenuMenuEntry: AZIconMenuEntry
{
    gchar *name;
    struct _ObMenu *submenu;
}
- (id) initWithMenu: (struct _ObMenu *) menu identifier: (int) identifier
              submenu: (gchar *) submenu;
- (gchar *) name;
- (struct _ObMenu *) submenu;
- (void) set_name: (gchar *) name;
- (void) set_submenu: (struct _ObMenu *) submenu;
@end

@interface AZSeparatorMenuEntry: AZMenuEntry
@end

