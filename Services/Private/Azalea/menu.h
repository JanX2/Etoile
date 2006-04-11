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

#ifndef __menu_h
#define __menu_h

#include "action.h"
#include "geom.h"
#include "render/render.h"
#import "AZMenu.h"

#include <glib.h>

@class AZMenuFrame;

typedef struct _ObMenu ObMenu;

typedef void (*ObMenuUpdateFunc)(AZMenuFrame *frame, gpointer data);
typedef void (*ObMenuExecuteFunc)(AZMenuEntry *entry,
                                  unsigned int state, gpointer data);
typedef void (*ObMenuDestroyFunc)(struct _ObMenu *menu, gpointer data);

struct _ObMenu
{
    /* Name of the menu. Used in the showmenu action. */
    gchar *name;
    /* Displayed title */
    gchar *title;

    /* Command to execute to rebuild the menu */
    gchar *execute;

    /* ObMenuEntry list */
    NSMutableArray *entries;

    /* plugin data */
    gpointer data;

    ObMenuUpdateFunc update_func;
    ObMenuExecuteFunc execute_func;
    ObMenuDestroyFunc destroy_func;

    /* Pipe-menu parent, we get destroyed when it is destroyed */
    ObMenu *pipe_creator;
};

void menu_startup(BOOL reconfig);
void menu_shutdown(BOOL reconfig);

ObMenu* menu_new(gchar *name, gchar *title, gpointer data);
void menu_free(ObMenu *menu);

/* Repopulate a pipe-menu by running its command */
void menu_pipe_execute(ObMenu *self);

void menu_show(gchar *name, int x, int y, AZClient *client);

void menu_set_update_func(ObMenu *menu, ObMenuUpdateFunc func);
void menu_set_execute_func(ObMenu *menu, ObMenuExecuteFunc func);
void menu_set_destroy_func(ObMenu *menu, ObMenuDestroyFunc func);

/* functions for building menus */
AZNormalMenuEntry* menu_add_normal(ObMenu *menu, int id, gchar *label,
                             GSList *actions);
AZSubmenuMenuEntry* menu_add_submenu(ObMenu *menu, int id, gchar *submenu);
AZSeparatorMenuEntry* menu_add_separator(ObMenu *menu, int id);

void menu_clear_entries(ObMenu *menu);
void menu_entry_remove(AZMenuEntry *menuentry);

AZMenuEntry* menu_find_entry_id(ObMenu *self, int id);

/* fills in the submenus, for use when a menu is being shown */
void menu_find_submenus(ObMenu *self);

#endif
