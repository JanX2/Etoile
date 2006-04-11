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
#import "menu.h"
#import "openbox.h"

#include <glib.h>

#define CLIENT_MENU_NAME  "client-menu"
#define SEND_TO_MENU_NAME "client-send-to-menu"
#define LAYER_MENU_NAME   "client-layer-menu"

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

static void client_update(AZMenuFrame *frame, gpointer data)
{
    ObMenu *menu = [frame menu];
    AZMenuEntry *e;
    int i, count;


    [frame set_show_title: NO];

    count = [menu->entries count];
    for (i = 0; i < count; i++) {
	e = [menu->entries objectAtIndex: i];
        if ([e type] == OB_MENU_ENTRY_TYPE_NORMAL)
            [(AZNormalMenuEntry*)e set_enabled: !![frame client]];
    }

    if (![frame client])
        return;

    e = menu_find_entry_id(menu, CLIENT_ICONIFY);
    [(AZNormalMenuEntry *)e set_enabled: [[frame client] functions] & OB_CLIENT_FUNC_ICONIFY];

    e = menu_find_entry_id(menu, CLIENT_MAXIMIZE);
    g_free([(AZNormalMenuEntry *)e label]);
    [(AZNormalMenuEntry *)e set_label: 
        g_strdup([[frame client] max_vert] || [[frame client] max_horz] ?
                 ("Restore") : ("Maximize"))];
    [(AZNormalMenuEntry *)e set_enabled: [[frame client] functions] & OB_CLIENT_FUNC_MAXIMIZE];

    e = menu_find_entry_id(menu, CLIENT_SHADE);
    g_free([(AZNormalMenuEntry *)e label]);
    [(AZNormalMenuEntry *)e set_label: g_strdup([[frame client] shaded] ?
                                    ("Roll down") : ("Roll up"))];
    [(AZNormalMenuEntry *)e set_enabled: [[frame client] functions] & OB_CLIENT_FUNC_SHADE];

    e = menu_find_entry_id(menu, CLIENT_MOVE);
    [(AZNormalMenuEntry *)e set_enabled: [[frame client] functions] & OB_CLIENT_FUNC_MOVE];

    e = menu_find_entry_id(menu, CLIENT_RESIZE);
    [(AZNormalMenuEntry *)e set_enabled: [[frame client] functions] & OB_CLIENT_FUNC_RESIZE];

    e = menu_find_entry_id(menu, CLIENT_CLOSE);
    [(AZNormalMenuEntry *)e set_enabled: [[frame client] functions] & OB_CLIENT_FUNC_CLOSE];

    e = menu_find_entry_id(menu, CLIENT_DECORATE);
    [(AZNormalMenuEntry *)e set_enabled: [[frame client] normal]];
}

static void layer_update(AZMenuFrame *frame, gpointer data)
{
    ObMenu *menu = [frame menu];
    AZMenuEntry *e;
    int i, count;

    count = [menu->entries count];
    for (i = 0; i < count; i++) {
	e = [menu->entries objectAtIndex: i];
        if ([e type] == OB_MENU_ENTRY_TYPE_NORMAL)
            [(AZNormalMenuEntry *)e set_enabled: !![frame client]];
    }

    if (![frame client])
        return;

    e = menu_find_entry_id(menu, LAYER_TOP);
    [(AZNormalMenuEntry *)e set_enabled: ![[frame client] above]];

    e = menu_find_entry_id(menu, LAYER_NORMAL);
    [(AZNormalMenuEntry *)e set_enabled: ([[frame client] above] || [[frame client] below])];

    e = menu_find_entry_id(menu, LAYER_BOTTOM);
    [(AZNormalMenuEntry *)e set_enabled: ![[frame client] below]];
}

static void send_to_update(AZMenuFrame *frame, gpointer data)
{
    ObMenu *menu = [frame menu];
    guint i;
    GSList *acts;
    ObAction *act;
    AZNormalMenuEntry *e;;

    menu_clear_entries(menu);

    if (![frame client])
        return;

    AZScreen *screen = [AZScreen defaultScreen];
    unsigned int num_desktops = [screen numberOfDesktops];
    for (i = 0; i <= num_desktops; ++i) {
        gchar *name;
        guint desk;

        if (i >= num_desktops) {
            menu_add_separator(menu, -1);

            desk = DESKTOP_ALL;
            name = ("All desktops");
        } else {
            desk = i;
            name = [screen nameOfDesktopAtIndex: i];
        }

        act = action_from_string("SendToDesktop",
                                 OB_USER_ACTION_MENU_SELECTION);
        act->data.sendto.desk = desk;
        act->data.sendto.follow = FALSE;
        acts = g_slist_prepend(NULL, act);
        e = menu_add_normal(menu, desk, name, acts);

        if ([[frame client] desktop] == desk)
            [e set_enabled: NO];
    }
}

void client_menu_startup()
{
    GSList *acts;
    ObMenu *menu;
    AZMenuEntry *e;

    menu = menu_new(LAYER_MENU_NAME, ("Layer"), NULL);
    menu_set_update_func(menu, layer_update);

    acts = g_slist_prepend(NULL, action_from_string
                           ("SendToTopLayer", OB_USER_ACTION_MENU_SELECTION));
    menu_add_normal(menu, LAYER_TOP, ("Always on top"), acts);

    acts = g_slist_prepend(NULL, action_from_string
                           ("SendToNormalLayer",
                            OB_USER_ACTION_MENU_SELECTION));
    menu_add_normal(menu, LAYER_NORMAL, ("Normal"), acts);

    acts = g_slist_prepend(NULL, action_from_string
                           ("SendToBottomLayer",
                            OB_USER_ACTION_MENU_SELECTION));
    menu_add_normal(menu, LAYER_BOTTOM, ("Always on bottom"),acts);


    menu = menu_new(SEND_TO_MENU_NAME, ("Send to desktop"), NULL);
    menu_set_update_func(menu, send_to_update);


    menu = menu_new(CLIENT_MENU_NAME, ("Client menu"), NULL);
    menu_set_update_func(menu, client_update);

    e = menu_add_submenu(menu, CLIENT_SEND_TO, SEND_TO_MENU_NAME);
    [(AZSubmenuMenuEntry*)e set_mask: ob_rr_theme->desk_mask];
    [(AZSubmenuMenuEntry*)e set_mask_normal_color: ob_rr_theme->menu_color];
    [(AZSubmenuMenuEntry*)e set_mask_disabled_color: ob_rr_theme->menu_disabled_color];
    [(AZSubmenuMenuEntry*)e set_mask_selected_color: ob_rr_theme->menu_selected_color];

    menu_add_submenu(menu, CLIENT_LAYER, LAYER_MENU_NAME);

    acts = g_slist_prepend(NULL, action_from_string
                           ("Iconify", OB_USER_ACTION_MENU_SELECTION));
    e = menu_add_normal(menu, CLIENT_ICONIFY, ("Iconify"), acts);
    [(AZNormalMenuEntry *)e set_mask: ob_rr_theme->iconify_mask];
    [(AZNormalMenuEntry *)e set_mask_normal_color: ob_rr_theme->menu_color];
    [(AZNormalMenuEntry *)e set_mask_disabled_color: ob_rr_theme->menu_disabled_color];
    [(AZNormalMenuEntry *)e set_mask_selected_color: ob_rr_theme->menu_selected_color];

    acts = g_slist_prepend(NULL, action_from_string
                           ("ToggleMaximizeFull",
                            OB_USER_ACTION_MENU_SELECTION));
    e = menu_add_normal(menu, CLIENT_MAXIMIZE, "MAXIMIZE", acts);
    [(AZNormalMenuEntry *)e set_mask: ob_rr_theme->max_mask]; 
    [(AZNormalMenuEntry *)e set_mask_normal_color: ob_rr_theme->menu_color];
    [(AZNormalMenuEntry *)e set_mask_disabled_color: ob_rr_theme->menu_disabled_color];
    [(AZNormalMenuEntry *)e set_mask_selected_color: ob_rr_theme->menu_selected_color];

    acts = g_slist_prepend(NULL, action_from_string
                           ("Raise", OB_USER_ACTION_MENU_SELECTION));
    menu_add_normal(menu, CLIENT_RAISE, ("Raise to top"), acts);

    acts = g_slist_prepend(NULL, action_from_string
                           ("Lower", OB_USER_ACTION_MENU_SELECTION));
    menu_add_normal(menu, CLIENT_LOWER, ("Lower to bottom"),acts);

    acts = g_slist_prepend(NULL, action_from_string
                           ("ToggleShade", OB_USER_ACTION_MENU_SELECTION));
    e = menu_add_normal(menu, CLIENT_SHADE, "SHADE", acts);
    [(AZNormalMenuEntry *)e set_mask: ob_rr_theme->shade_mask];
    [(AZNormalMenuEntry *)e set_mask_normal_color: ob_rr_theme->menu_color];
    [(AZNormalMenuEntry *)e set_mask_disabled_color: ob_rr_theme->menu_disabled_color];
    [(AZNormalMenuEntry *)e set_mask_selected_color: ob_rr_theme->menu_selected_color];

    acts = g_slist_prepend(NULL, action_from_string
                           ("ToggleDecorations",
                            OB_USER_ACTION_MENU_SELECTION));
    menu_add_normal(menu, CLIENT_DECORATE, ("Decorate"), acts);

    menu_add_separator(menu, -1);

    acts = g_slist_prepend(NULL, action_from_string
                           ("Move", OB_USER_ACTION_MENU_SELECTION));
    menu_add_normal(menu, CLIENT_MOVE, ("Move"), acts);

    acts = g_slist_prepend(NULL, action_from_string
                           ("Resize", OB_USER_ACTION_MENU_SELECTION));
    menu_add_normal(menu, CLIENT_RESIZE, ("Resize"), acts);

    menu_add_separator(menu, -1);

    acts = g_slist_prepend(NULL, action_from_string
                           ("Close", OB_USER_ACTION_MENU_SELECTION));
    e = menu_add_normal(menu, CLIENT_CLOSE, ("Close"), acts);
    [(AZNormalMenuEntry *)e set_mask: ob_rr_theme->close_mask];
    [(AZNormalMenuEntry *)e set_mask_normal_color: ob_rr_theme->menu_color];
    [(AZNormalMenuEntry *)e set_mask_disabled_color: ob_rr_theme->menu_disabled_color];
    [(AZNormalMenuEntry *)e set_mask_selected_color: ob_rr_theme->menu_selected_color];
}
