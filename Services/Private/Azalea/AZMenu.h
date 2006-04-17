/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZMenu.h for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

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

@class AZMenu;
@class AZMenuFrame;
@class AZMenuEntry;
@class AZNormalMenuEntry;
@class AZSubmenuMenuEntry;
@class AZSeparatorMenuEntry;

/* Menu */
@interface AZMenu: NSObject
{
    /* Name of the menu. Used in the showmenu action. */
    NSString *name;
    /* Displayed title */
    NSString *title;

    /* Command to execute to rebuild the menu */
    NSString *execute;

    /* ObMenuEntry list */
    NSMutableArray *entries;

    /* Pipe-menu parent, we get destroyed when it is destroyed */
    AZMenu *pipe_creator;
}

- (id) initWithName: (NSString *) name title: (NSString *) title;

/* Repopulate a pipe-menu by running its command */
- (void) pipeExecute;

/* functions for building menus */
- (AZNormalMenuEntry *) addNormalMenuEntry: (int) identifier label: (NSString *) label actions: (NSArray *) actions;
- (AZSubmenuMenuEntry *) addSubmenuMenuEntry: (int) identifer submenu: (NSString *) submenu;
- (AZSeparatorMenuEntry *) addSeparatorMenuEntry: (int) identifier;
- (void) removeEntryWithIdentifier: (int) identifier;
- (void) clearEntries;
- (AZMenuEntry *) entryWithIdentifier: (int) identifier;

//FIXME: should change name. This is confusing.
/* fills in the submenus, for use when a menu is being shown */
- (void) findSubmenus;

- (void) update: (AZMenuFrame *) frame;
- (BOOL) execute: (AZMenuEntry *) entry state: (unsigned int) state;

/* Accessoris */
- (NSString *) name;
- (NSString *) title;
- (NSString *) execute;
- (NSMutableArray *) entries;
- (AZMenu *) pipe_creator;
- (void) set_name: (NSString *) name;
- (void) set_title: (NSString *) title;
- (void) set_execute: (NSString *) execute;
- (void) set_pipe_creator: (AZMenu *) pipe_creator;

@end

/* Menu Entry */

typedef enum
{
    OB_MENU_ENTRY_TYPE_NORMAL,
    OB_MENU_ENTRY_TYPE_SUBMENU,
    OB_MENU_ENTRY_TYPE_SEPARATOR
} ObMenuEntryType;

@interface AZMenuEntry: NSObject
{
    ObMenuEntryType type;
    AZMenu *menu;
    int identifier;
}
- (id) initWithMenu: (AZMenu *) menu identifier: (int) identifier;

/* accessories */
- (ObMenuEntryType) type;
- (AZMenu *) menu;
- (int) identifier;
- (void) set_type: (ObMenuEntryType) type;
- (void) set_menu: (AZMenu *) menu;
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
    NSString *label;

    /* state */
    BOOL enabled;

    /* List of ObActions */
    NSArray *actions;

}

- (id) initWithMenu: (AZMenu *) menu identifier: (int) identifier label: (NSString *) label actions: (NSArray *) actions;
         
/* Accessories */
- (NSString *)label;
- (BOOL) enabled;
- (NSArray *) actions;
- (void) set_label: (NSString *)label;
- (void) set_enabled: (BOOL) enabled;
- (void) set_actions: (NSArray *) actions;
@end

@interface AZSubmenuMenuEntry: AZIconMenuEntry
{
    NSString *name;
    AZMenu *submenu;
}
- (id) initWithMenu: (AZMenu *) menu identifier: (int) identifier
              submenu: (NSString *) submenu;
- (NSString *) name;
- (AZMenu *) submenu;
- (void) set_name: (NSString *) name;
- (void) set_submenu: (AZMenu *) submenu;
@end

@interface AZSeparatorMenuEntry: AZMenuEntry
@end

