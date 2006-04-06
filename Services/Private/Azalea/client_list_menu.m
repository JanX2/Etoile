/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   client_list_menu.c for the Openbox window manager
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
#import "AZFocusManager.h"
#import "AZMenuFrame.h"
#import "openbox.h"
#import "menu.h"
#import "action.h"
#import "config.h"

#include <glib.h>

#define MENU_NAME "client-list-menu"

static GSList *desktop_menus;

typedef struct
{
    guint desktop;
} DesktopData;

static void desk_menu_update(AZMenuFrame *frame, gpointer data)
{
    ObMenu *menu = [frame menu];
    DesktopData *d = data;
    GList *it;
    gint i;
    gboolean icons = FALSE;
    gboolean empty = TRUE;

    menu_clear_entries(menu);

    AZFocusManager *fManager = [AZFocusManager defaultManager];
    for (it = [fManager focus_order][d->desktop], i = 0; it; it = g_list_next(it), ++i) {
        AZClient *c = ((AZClient*)(it->data));
        if ([c normal] && ![c skip_taskbar]) {
            GSList *acts = NULL;
            ObAction* act;
            ObMenuEntry *e;
            AZClientIcon *icon;

            empty = FALSE;

            if (!icons && [c iconic]) {
                icons = TRUE;
                menu_add_separator(menu, -1);
            }

            act = action_from_string("Activate",
                                     OB_USER_ACTION_MENU_SELECTION);
            act->data.activate.any.c = c;
            acts = g_slist_append(acts, act);
            act = action_from_string("Desktop",
                                     OB_USER_ACTION_MENU_SELECTION);
            act->data.desktop.desk = d->desktop;
            acts = g_slist_append(acts, act);
            e = menu_add_normal(menu, i,
                                ([c iconic] ? [c icon_title] : [c title]), acts);

            if (config_menu_client_list_icons && 
		(icon = [c iconWithWidth: 32 height: 32])) {
                e->data.normal.icon_width = [icon width];
                e->data.normal.icon_height = [icon height];
                e->data.normal.icon_data = [icon data];
            }
        }
    }

    if (empty) {
        /* no entries */

        GSList *acts = NULL;
        ObAction* act;
        ObMenuEntry *e;

        act = action_from_string("Desktop", OB_USER_ACTION_MENU_SELECTION);
        act->data.desktop.desk = d->desktop;
        acts = g_slist_append(acts, act);
        e = menu_add_normal(menu, 0, ("Go there..."), acts);
        if (d->desktop == [[AZScreen defaultScreen] desktop])
            e->data.normal.enabled = FALSE;
    }
}

/* executes it using the client in the actions, since we set that
   when we make the actions! */
static void desk_menu_execute(ObMenuEntry *self, guint state, gpointer data)
{
    ObAction *a;

    if (self->data.normal.actions) {
        a = self->data.normal.actions->data;
        action_run(self->data.normal.actions, a->data.any.c, state);
    }
}

static void desk_menu_destroy(ObMenu *menu, gpointer data)
{
    DesktopData *d = data;

    g_free(d);

    desktop_menus = g_slist_remove(desktop_menus, menu);
}

static void self_update(AZMenuFrame *frame, gpointer data)
{
    ObMenu *menu = [frame menu];
    guint i;
    GSList *it, *next;
    
    it = desktop_menus;
    AZScreen *screen = [AZScreen defaultScreen];
    for (i = 0; i < [screen numberOfDesktops]; ++i) {
        if (!it) {
            ObMenu *submenu;
            gchar *name = g_strdup_printf("%s-%u", MENU_NAME, i);
            DesktopData *data = g_new(DesktopData, 1);

            data->desktop = i;
            submenu = menu_new(name, [screen nameOfDesktopAtIndex: i], data);
            menu_set_update_func(submenu, desk_menu_update);
            menu_set_execute_func(submenu, desk_menu_execute);
            menu_set_destroy_func(submenu, desk_menu_destroy);

            menu_add_submenu(menu, i, name);

            g_free(name);

            desktop_menus = g_slist_append(desktop_menus, submenu);
        } else
            it = g_slist_next(it);
    }
    for (; it; it = next, ++i) {
        next = g_slist_next(it);
        menu_free(it->data);
        desktop_menus = g_slist_delete_link(desktop_menus, it);
        menu_entry_remove(menu_find_entry_id(menu, i));
    }
}

void client_list_menu_startup()
{
    ObMenu *menu;

    menu = menu_new(MENU_NAME, ("Desktops"), NULL);
    menu_set_update_func(menu, self_update);
}
