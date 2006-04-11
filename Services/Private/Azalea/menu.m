/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   menu.c for the Openbox window manager
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
#import "AZClientManager.h"
#import "AZMenuFrame.h"
#include "menu.h"
#include "openbox.h"
#include "config.h"
#include "geom.h"
#include "misc.h"
#include "client_menu.h"
#include "client_list_menu.h"
#include "parse.h"

typedef struct _ObMenuParseState ObMenuParseState;

struct _ObMenuParseState
{
    ObMenu *parent;
    ObMenu *pipe_creator;
};

static GHashTable *menu_hash = NULL;
static ObParseInst *menu_parse_inst;
static ObMenuParseState menu_parse_state;

static void menu_destroy_hash_value(ObMenu *self);
static void parse_menu_item(ObParseInst *i, xmlDocPtr doc, xmlNodePtr node,
                            gpointer data);
static void parse_menu_separator(ObParseInst *i,
                                 xmlDocPtr doc, xmlNodePtr node,
                                 gpointer data);
static void parse_menu(ObParseInst *i, xmlDocPtr doc, xmlNodePtr node,
                       gpointer data);

void menu_startup(BOOL reconfig)
{
    xmlDocPtr doc;
    xmlNodePtr node;
    BOOL loaded = NO;
    GSList *it;

    menu_hash = g_hash_table_new_full(g_str_hash, g_str_equal, NULL,
                                      (GDestroyNotify)menu_destroy_hash_value);

    client_list_menu_startup();
    client_menu_startup();

    menu_parse_inst = parse_startup();

    menu_parse_state.parent = NULL;
    menu_parse_state.pipe_creator = NULL;
    parse_register(menu_parse_inst, "menu", parse_menu, &menu_parse_state);
    parse_register(menu_parse_inst, "item", parse_menu_item,
                   &menu_parse_state);
    parse_register(menu_parse_inst, "separator",
                   parse_menu_separator, &menu_parse_state);

    for (it = config_menu_files; it; it = g_slist_next(it)) {
        if (parse_load_menu(it->data, &doc, &node)) {
            loaded = YES;
            parse_tree(menu_parse_inst, doc, node->children);
            xmlFreeDoc(doc);
        }
    }
    if (!loaded) {
        if (parse_load_menu("menu.xml", &doc, &node)) {
            parse_tree(menu_parse_inst, doc, node->children);
            xmlFreeDoc(doc);
        }
    }
    
    g_assert(menu_parse_state.parent == NULL);
}

void menu_shutdown(BOOL reconfig)
{
    parse_shutdown(menu_parse_inst);
    menu_parse_inst = NULL;

    AZMenuFrameHideAll();
    g_hash_table_destroy(menu_hash);
    menu_hash = NULL;
}

static gboolean menu_pipe_submenu(gpointer key, gpointer val, gpointer data)
{
    ObMenu *menu = val;
    return menu->pipe_creator == data;
}

void menu_pipe_execute(ObMenu *self)
{
    xmlDocPtr doc;
    xmlNodePtr node;
    gchar *output;
    GError *err = NULL;

    if (!self->execute)
        return;

    if (!g_spawn_command_line_sync(self->execute, &output, NULL, NULL, &err)) {
        g_warning("Failed to execute command for pipe-menu: %s", err->message);
        g_error_free(err);
        return;
    }

    if (parse_load_mem(output, strlen(output),
                       "openbox_pipe_menu", &doc, &node))
    {
        g_hash_table_foreach_remove(menu_hash, menu_pipe_submenu, self);
        menu_clear_entries(self);

        menu_parse_state.pipe_creator = self;
        menu_parse_state.parent = self;
        parse_tree(menu_parse_inst, doc, node->children);
        xmlFreeDoc(doc);
    } else {
        g_warning("Invalid output from pipe-menu: %s", self->execute);
    }

    g_free(output);
}

static ObMenu* menu_from_name(gchar *name)
{
    ObMenu *self = NULL;

    g_assert(name != NULL);

    if (!(self = g_hash_table_lookup(menu_hash, name)))
        g_warning("Attempted to access menu '%s' but it does not exist.",
                  name);
    return self;
}  

static void parse_menu_item(ObParseInst *i, xmlDocPtr doc, xmlNodePtr node,
                            gpointer data)
{
    ObMenuParseState *state = data;
    gchar *label;
    
    if (state->parent) {
        if (parse_attr_string("label", node, &label)) {
            GSList *acts = NULL;

            for (node = node->children; node; node = node->next)
                if (!xmlStrcasecmp(node->name, (const xmlChar*) "action")) {
                    ObAction *a = action_parse
                        (i, doc, node, OB_USER_ACTION_MENU_SELECTION);
                    if (a)
                        acts = g_slist_append(acts, a);
                }
            menu_add_normal(state->parent, -1, label, acts);
            g_free(label);
        }
    }
}

static void parse_menu_separator(ObParseInst *i,
                                 xmlDocPtr doc, xmlNodePtr node,
                                 gpointer data)
{
    ObMenuParseState *state = data;

    if (state->parent)
        menu_add_separator(state->parent, -1);
}

static void parse_menu(ObParseInst *i, xmlDocPtr doc, xmlNodePtr node,
                       gpointer data)
{
    ObMenuParseState *state = data;
    gchar *name = NULL, *title = NULL, *script = NULL;
    ObMenu *menu;

    if (!parse_attr_string("id", node, &name))
        goto parse_menu_fail;

    if (!g_hash_table_lookup(menu_hash, name)) {
        if (!parse_attr_string("label", node, &title))
            goto parse_menu_fail;

        if ((menu = menu_new(name, title, NULL))) {
            menu->pipe_creator = state->pipe_creator;
            if (parse_attr_string("execute", node, &script)) {
                menu->execute = parse_expand_tilde(script);
            } else {
                ObMenu *old;

                old = state->parent;
                state->parent = menu;
                parse_tree(i, doc, node->children);
                state->parent = old;
            }
        }
    }

    if (state->parent)
        menu_add_submenu(state->parent, -1, name);

parse_menu_fail:
    g_free(name);
    g_free(title);
    g_free(script);
}

ObMenu* menu_new(gchar *name, gchar *title, gpointer data)
{
    ObMenu *self;

    self = g_new0(ObMenu, 1);
    self->name = g_strdup(name);
    self->title = g_strdup(title);
    self->data = data;
    self->entries = [[NSMutableArray alloc] init];

    g_hash_table_replace(menu_hash, self->name, self);

    return self;
}

static void menu_destroy_hash_value(ObMenu *self)
{
    /* make sure its not visible */
    {
	NSArray *visibles = [AZMenuFrame visibleFrames];
	int i, count = [visibles count];
        AZMenuFrame *f;

	for (i = 0; i < count; i++) {
	    f = [visibles objectAtIndex: i];
            if ([f menu] == self)
		AZMenuFrameHideAll();
        }
    }

    if (self->destroy_func)
        self->destroy_func(self, self->data);

    menu_clear_entries(self);
    g_free(self->name);
    g_free(self->title);
    g_free(self->execute);

    g_free(self);
}

void menu_free(ObMenu *menu)
{
    g_hash_table_remove(menu_hash, menu->name);
    DESTROY(menu->entries);
}

void menu_show(gchar *name, int x, int y, AZClient *client)
{
    ObMenu *self;
    AZMenuFrame *frame;
    unsigned int i;

    if (!(self = menu_from_name(name))) return;

    /* if the requested menu is already the top visible menu, then don't
       bother */
    NSArray *visibles = [AZMenuFrame visibleFrames];
    if ([visibles count]) {
	frame = [visibles objectAtIndex: 0];
        if ([frame menu] == self)
            return;
    }

    AZMenuFrameHideAll();

    frame = [[AZMenuFrame alloc] initWithMenu: self client: client];
    if (client && x < 0 && y < 0) {
        x = [[client frame] area].x + [[client frame] size].left;
        y = [[client frame] area].y + [[client frame] size].top;
	[frame moveToX: x y: y];
    } else
	[frame moveToX: x - ob_rr_theme->bwidth y: y - ob_rr_theme->bwidth];
    AZScreen *screen = [AZScreen defaultScreen];
    for (i = 0; i < [screen numberOfMonitors]; ++i) {
        Rect *a = [screen physicalAreaOfMonitor: i];
        if (RECT_CONTAINS(*a, x, y)) {
	    [frame set_monitor: i];
            break;
        }
    }
    if (![frame showWithParent: nil])
	DESTROY(frame);
}

void menu_clear_entries(ObMenu *self)
{
#ifdef DEBUG
    /* assert that the menu isn't visible */
    {
        GList *it;
        AZMenuFrame *f;

        for (it = menu_frame_visible; it; it = g_list_next(it)) {
            f = it->data;
            g_assert([f menu] != self);
        }
    }
#endif

    [self->entries removeAllObjects];
}

void menu_entry_remove(AZMenuEntry *menuentry)
{
    [[menuentry menu]->entries removeObject: menuentry];
    DESTROY(menuentry);
}

AZNormalMenuEntry* menu_add_normal(ObMenu *self, int id, gchar *label,
                             GSList *actions)
{
  AZNormalMenuEntry *e = [[AZNormalMenuEntry alloc] initWithMenu: self identifier: id
	                        label: label actions: actions];
  [self->entries addObject: e];
  return e;
}

AZSubmenuMenuEntry* menu_add_submenu(ObMenu *self, int id, gchar *submenu)
{
  AZSubmenuMenuEntry *e = [[AZSubmenuMenuEntry alloc] initWithMenu: self identifier: id submenu: submenu];

  [self->entries addObject: e];
  return e;
}

AZSeparatorMenuEntry* menu_add_separator(ObMenu *self, int id)
{
  AZSeparatorMenuEntry *e = [[AZSeparatorMenuEntry alloc] initWithMenu: self identifier: id];
  [self->entries addObject: e];
  return e;
}

void menu_set_update_func(ObMenu *self, ObMenuUpdateFunc func)
{
    self->update_func = func;
}

void menu_set_execute_func(ObMenu *self, ObMenuExecuteFunc func)
{
    self->execute_func = func;
}

void menu_set_destroy_func(ObMenu *self, ObMenuDestroyFunc func)
{
    self->destroy_func = func;
}

AZMenuEntry* menu_find_entry_id(ObMenu *self, int id)
{
    AZMenuEntry *ret = NULL;
    int i, count = [self->entries count];
    for (i = 0; i < count; i++) {
      AZMenuEntry *e = [self->entries objectAtIndex: i];
      if ([e identifier] == id) {
	ret = e;
	break;
      }
    }
    return ret;
}

void menu_find_submenus(ObMenu *self)
{
  int i, count = [self->entries count];
  for (i = 0; i < count; i++) {
    AZMenuEntry *e = [self->entries objectAtIndex: i];
    if ([e type] == OB_MENU_ENTRY_TYPE_SUBMENU)
      [(AZSubmenuMenuEntry *)e set_submenu: menu_from_name([(AZSubmenuMenuEntry *)e name])];
  }
}

