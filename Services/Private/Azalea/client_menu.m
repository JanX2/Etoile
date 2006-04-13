// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   client_menu.c for the Openbox window manager
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

#import "AZScreen.h"
#import "AZClient.h"
#import "AZMenuFrame.h"
#import "AZMenu.h"
#import "AZMenuManager.h"
#import "openbox.h"
#import "action.h"

#include <glib.h>

#define CLIENT_MENU_NAME  @"client-menu"
#define SEND_TO_MENU_NAME @"client-send-to-menu"
#define LAYER_MENU_NAME   @"client-layer-menu"

enum {
    LAYER_TOP,
    LAYER_NORMAL,
    LAYER_BOTTOM
};

enum {
    CLIENT_SEND_TO,
    CLIENT_LAYER,
    CLIENT_ICONIFY,
    CLIENT_MAXIMIZE,
    CLIENT_RAISE,
    CLIENT_LOWER,
    CLIENT_SHADE,
    CLIENT_DECORATE,
    CLIENT_MOVE,
    CLIENT_RESIZE,
    CLIENT_CLOSE
};

@interface AZClientMenu: AZMenu
@end

@implementation AZClientMenu

- (void) update: (AZMenuFrame *) frame 
{
    AZMenu *menu = [frame menu];
    AZMenuEntry *e;
    int i, count;


    [frame set_show_title: NO];

    count = [[menu entries] count];
    for (i = 0; i < count; i++) {
	e = [[menu entries] objectAtIndex: i];
        if ([e type] == OB_MENU_ENTRY_TYPE_NORMAL)
            [(AZNormalMenuEntry*)e set_enabled: !![frame client]];
    }

    if (![frame client])
        return;

    e = [menu entryWithIdentifier: CLIENT_ICONIFY];
    [(AZNormalMenuEntry *)e set_enabled: [[frame client] functions] & OB_CLIENT_FUNC_ICONIFY];

    e = [menu entryWithIdentifier: CLIENT_MAXIMIZE];
    [(AZNormalMenuEntry *)e set_label: 
        ([[frame client] max_vert] || [[frame client] max_horz] ?  @"Restore" : @"Maximize")];
    [(AZNormalMenuEntry *)e set_enabled: [[frame client] functions] & OB_CLIENT_FUNC_MAXIMIZE];

    e = [menu entryWithIdentifier: CLIENT_SHADE];
    [(AZNormalMenuEntry *)e set_label: ([[frame client] shaded] ?  @"Roll down" : @"Roll up")];
    [(AZNormalMenuEntry *)e set_enabled: [[frame client] functions] & OB_CLIENT_FUNC_SHADE];

    e = [menu entryWithIdentifier: CLIENT_MOVE];
    [(AZNormalMenuEntry *)e set_enabled: [[frame client] functions] & OB_CLIENT_FUNC_MOVE];

    e = [menu entryWithIdentifier: CLIENT_RESIZE];
    [(AZNormalMenuEntry *)e set_enabled: [[frame client] functions] & OB_CLIENT_FUNC_RESIZE];

    e = [menu entryWithIdentifier: CLIENT_CLOSE];
    [(AZNormalMenuEntry *)e set_enabled: [[frame client] functions] & OB_CLIENT_FUNC_CLOSE];

    e = [menu entryWithIdentifier: CLIENT_DECORATE];
    [(AZNormalMenuEntry *)e set_enabled: [[frame client] normal]];
}
@end

@interface AZLayerMenu: AZMenu
@end

@implementation AZLayerMenu
- (void) update: (AZMenuFrame *) frame 
{
    AZMenu *menu = [frame menu];
    AZMenuEntry *e;
    int i, count;

    count = [[menu entries] count];
    for (i = 0; i < count; i++) {
	e = [[menu entries] objectAtIndex: i];
        if ([e type] == OB_MENU_ENTRY_TYPE_NORMAL)
            [(AZNormalMenuEntry *)e set_enabled: !![frame client]];
    }

    if (![frame client])
        return;

    e = [menu entryWithIdentifier: LAYER_TOP];
    [(AZNormalMenuEntry *)e set_enabled: ![[frame client] above]];

    e = [menu entryWithIdentifier: LAYER_NORMAL];
    [(AZNormalMenuEntry *)e set_enabled: ([[frame client] above] || [[frame client] below])];

    e = [menu entryWithIdentifier: LAYER_BOTTOM];
    [(AZNormalMenuEntry *)e set_enabled: ![[frame client] below]];
}
@end

@interface AZSendMenu: AZMenu
@end

@implementation  AZSendMenu
- (void) update: (AZMenuFrame *) frame 
{
    AZMenu *menu = [frame menu];
    guint i;
    GSList *acts;
    ObAction *act;
    AZNormalMenuEntry *e;;

    [menu clearEntries];

    if (![frame client])
        return;

    AZScreen *screen = [AZScreen defaultScreen];
    unsigned int num_desktops = [screen numberOfDesktops];
    for (i = 0; i <= num_desktops; ++i) {
        gchar *n;
        guint desk;

        if (i >= num_desktops) {
            [menu addSeparatorMenuEntry: -1];

            desk = DESKTOP_ALL;
            n = ("All desktops");
        } else {
            desk = i;
            n = [screen nameOfDesktopAtIndex: i];
        }

        act = action_from_string("SendToDesktop",
                                 OB_USER_ACTION_MENU_SELECTION);
        act->data.sendto.desk = desk;
        act->data.sendto.follow = FALSE;
        acts = g_slist_prepend(NULL, act);
	e = [menu addNormalMenuEntry: desk label: [NSString stringWithCString: n] actions: acts];

        if ([[frame client] desktop] == desk)
            [e set_enabled: NO];
    }
}
@end

void client_menu_startup()
{
    GSList *acts;
    AZMenuEntry *e;

    /* Layer */
    AZLayerMenu *layer_menu = [[AZLayerMenu alloc] initWithName: LAYER_MENU_NAME title: @"Layer"];

    acts = g_slist_prepend(NULL, action_from_string
                           ("SendToTopLayer", OB_USER_ACTION_MENU_SELECTION));
    [layer_menu addNormalMenuEntry: LAYER_TOP label: @"Always on top" actions: acts];

    acts = g_slist_prepend(NULL, action_from_string
                           ("SendToNormalLayer",
                            OB_USER_ACTION_MENU_SELECTION));
    [layer_menu addNormalMenuEntry: LAYER_NORMAL label: @"Normal" actions: acts];

    acts = g_slist_prepend(NULL, action_from_string
                           ("SendToBottomLayer",
                            OB_USER_ACTION_MENU_SELECTION));
    [layer_menu addNormalMenuEntry: LAYER_BOTTOM label: @"Always on bottom" actions: acts];

    [[AZMenuManager defaultManager] registerMenu: layer_menu];
    DESTROY(layer_menu);

    /* Send Menu */
    AZSendMenu *send_menu = [[AZSendMenu alloc] initWithName: SEND_TO_MENU_NAME title: @"Send to desktop"];
    [[AZMenuManager defaultManager] registerMenu: send_menu];
    DESTROY(send_menu);

    /* Client menu */
    AZClientMenu *menu = [[AZClientMenu alloc] initWithName: CLIENT_MENU_NAME title: @"Client menu"];

    e = [menu addSubmenuMenuEntry: CLIENT_SEND_TO submenu: SEND_TO_MENU_NAME];
    [(AZSubmenuMenuEntry*)e set_mask: ob_rr_theme->desk_mask];
    [(AZSubmenuMenuEntry*)e set_mask_normal_color: ob_rr_theme->menu_color];
    [(AZSubmenuMenuEntry*)e set_mask_disabled_color: ob_rr_theme->menu_disabled_color];
    [(AZSubmenuMenuEntry*)e set_mask_selected_color: ob_rr_theme->menu_selected_color];

    [menu addSubmenuMenuEntry: CLIENT_LAYER submenu: LAYER_MENU_NAME];

    acts = g_slist_prepend(NULL, action_from_string
                           ("Iconify", OB_USER_ACTION_MENU_SELECTION));
    e = [menu addNormalMenuEntry: CLIENT_ICONIFY label: @"Iconify" actions: acts];
    [(AZNormalMenuEntry *)e set_mask: ob_rr_theme->iconify_mask];
    [(AZNormalMenuEntry *)e set_mask_normal_color: ob_rr_theme->menu_color];
    [(AZNormalMenuEntry *)e set_mask_disabled_color: ob_rr_theme->menu_disabled_color];
    [(AZNormalMenuEntry *)e set_mask_selected_color: ob_rr_theme->menu_selected_color];

    acts = g_slist_prepend(NULL, action_from_string
                           ("ToggleMaximizeFull",
                            OB_USER_ACTION_MENU_SELECTION));
    e = [menu addNormalMenuEntry: CLIENT_MAXIMIZE label: @"MAXIMIZE" actions: acts];
    [(AZNormalMenuEntry *)e set_mask: ob_rr_theme->max_mask]; 
    [(AZNormalMenuEntry *)e set_mask_normal_color: ob_rr_theme->menu_color];
    [(AZNormalMenuEntry *)e set_mask_disabled_color: ob_rr_theme->menu_disabled_color];
    [(AZNormalMenuEntry *)e set_mask_selected_color: ob_rr_theme->menu_selected_color];

    acts = g_slist_prepend(NULL, action_from_string
                           ("Raise", OB_USER_ACTION_MENU_SELECTION));
    [menu addNormalMenuEntry: CLIENT_RAISE label: @"Raise to top" actions: acts];

    acts = g_slist_prepend(NULL, action_from_string
                           ("Lower", OB_USER_ACTION_MENU_SELECTION));
    [menu addNormalMenuEntry: CLIENT_LOWER label: @"Lower to bottom" actions: acts];

    acts = g_slist_prepend(NULL, action_from_string
                           ("ToggleShade", OB_USER_ACTION_MENU_SELECTION));
    e = [menu addNormalMenuEntry: CLIENT_SHADE label: @"SHADE" actions: acts];
    [(AZNormalMenuEntry *)e set_mask: ob_rr_theme->shade_mask];
    [(AZNormalMenuEntry *)e set_mask_normal_color: ob_rr_theme->menu_color];
    [(AZNormalMenuEntry *)e set_mask_disabled_color: ob_rr_theme->menu_disabled_color];
    [(AZNormalMenuEntry *)e set_mask_selected_color: ob_rr_theme->menu_selected_color];

    acts = g_slist_prepend(NULL, action_from_string
                           ("ToggleDecorations",
                            OB_USER_ACTION_MENU_SELECTION));
    [menu addNormalMenuEntry: CLIENT_DECORATE label: @"Decorate" actions: acts];

    [menu addSeparatorMenuEntry: -1];

    acts = g_slist_prepend(NULL, action_from_string
                           ("Move", OB_USER_ACTION_MENU_SELECTION));
    [menu addNormalMenuEntry: CLIENT_MOVE label: @"Move" actions: acts];

    acts = g_slist_prepend(NULL, action_from_string
                           ("Resize", OB_USER_ACTION_MENU_SELECTION));
    [menu addNormalMenuEntry: CLIENT_RESIZE label: @"Resize" actions: acts];

    [menu addSeparatorMenuEntry: -1];

    acts = g_slist_prepend(NULL, action_from_string
                           ("Close", OB_USER_ACTION_MENU_SELECTION));
    e = [menu addNormalMenuEntry: CLIENT_CLOSE label: @"Close" actions: acts];
    [(AZNormalMenuEntry *)e set_mask: ob_rr_theme->close_mask];
    [(AZNormalMenuEntry *)e set_mask_normal_color: ob_rr_theme->menu_color];
    [(AZNormalMenuEntry *)e set_mask_disabled_color: ob_rr_theme->menu_disabled_color];
    [(AZNormalMenuEntry *)e set_mask_selected_color: ob_rr_theme->menu_selected_color];
    [[AZMenuManager defaultManager] registerMenu: menu];
    DESTROY(menu);
}
