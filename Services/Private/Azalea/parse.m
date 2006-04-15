// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   parse.c for the Openbox window manager
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
#import "parse.h"
#import <glib.h>
#import <string.h>
#import <errno.h>
#import <sys/stat.h>
#import <sys/types.h>

static BOOL xdg_start;
static NSString *xdg_config_home_path;
static NSString *xdg_data_home_path;
static NSMutableArray *xdg_config_dir_paths;
static NSMutableArray *xdg_data_dir_paths;

struct Callback {
    gchar *tag;
    ParseCallback func;
    gpointer data;
};

struct _ObParseInst {
    GHashTable *callbacks;
};

static void destfunc(struct Callback *c)
{
    g_free(c->tag);
    g_free(c);
}

@implementation AZParser

- (struct _ObParseInst *) obParseInst
{
  return obParseInst;
}

- (id) init
{
    self = [super init];
    obParseInst = g_new(ObParseInst, 1);
    obParseInst->callbacks = g_hash_table_new_full(g_str_hash, g_str_equal, NULL,
                                         (GDestroyNotify)destfunc);
    return self;
}

- (void) dealloc
{
    if (obParseInst) {
        g_hash_table_destroy(obParseInst->callbacks);
        g_free(obParseInst);
    }
}

@end

void parse_register(ObParseInst *i, const gchar *tag,
                    ParseCallback func, gpointer data)
{
    struct Callback *c;

    if ((c = g_hash_table_lookup(i->callbacks, tag))) {
        g_warning("tag '%s' already registered", tag);
        return;
    }

    c = g_new(struct Callback, 1);
    c->tag = g_strdup(tag);
    c->func = func;
    c->data = data;
    g_hash_table_insert(i->callbacks, c->tag, c);
}

BOOL parse_load_rc(xmlDocPtr *doc, xmlNodePtr *root)
{
    gchar *path;
    BOOL r = NO;

    int i, count = [xdg_config_dir_paths count];
    for (i = 0; !r && (i < count); i++) {
	path = g_build_filename((char*)[[xdg_config_dir_paths objectAtIndex: i] cString], "openbox", "rc.xml", NULL);
        r = parse_load(path, "openbox_config", doc, root);
        g_free(path);
    }
    if (!r)
        g_warning("unable to find a valid config file, using defaults");
    return r;
}

BOOL parse_load_menu(const gchar *file, xmlDocPtr *doc, xmlNodePtr *root)
{
    gchar *path;
    BOOL r = NO;

    if (file[0] == '/') {
        r = parse_load(file, "openbox_menu", doc, root);
    } else {
        int i, count = [xdg_config_dir_paths count];
        for (i = 0; !r && (i < count); i++) {
	    path = g_build_filename((char*)[[xdg_config_dir_paths objectAtIndex: i] cString], "openbox", file, NULL);
            r = parse_load(path, "openbox_menu", doc, root);
            g_free(path);
        }
    }
    if (!r)
        g_warning("unable to find a valid menu file '%s'", file);
    return r;
}

BOOL parse_load(const gchar *path, const gchar *rootname,
                    xmlDocPtr *doc, xmlNodePtr *root)
{
    if ((*doc = xmlParseFile(path))) {
        *root = xmlDocGetRootElement(*doc);
        if (!*root) {
            xmlFreeDoc(*doc);
            *doc = NULL;
            g_warning("%s is an empty document", path);
        } else {
            if (xmlStrcasecmp((*root)->name, (const xmlChar*)rootname)) {
                xmlFreeDoc(*doc);
                *doc = NULL;
                g_warning("document %s is of wrong type. root node is "
                          "not '%s'", path, rootname);
            }
        }
    }
    if (!*doc)
        return NO;
    return YES;
}

BOOL parse_load_mem(gpointer data, unsigned int len, const gchar *rootname,
                        xmlDocPtr *doc, xmlNodePtr *root)
{
    if ((*doc = xmlParseMemory(data, len))) {
        *root = xmlDocGetRootElement(*doc);
        if (!*root) {
            xmlFreeDoc(*doc);
            *doc = NULL;
            g_warning("Given memory is an empty document");
        } else {
            if (xmlStrcasecmp((*root)->name, (const xmlChar*)rootname)) {
                xmlFreeDoc(*doc);
                *doc = NULL;
                g_warning("document in given memory is of wrong type. root "
                          "node is not '%s'", rootname);
            }
        }
    }
    if (!*doc)
        return NO;
    return YES;
}

void parse_close(xmlDocPtr doc)
{
    xmlFreeDoc(doc);
}

void parse_tree(ObParseInst *i, xmlDocPtr doc, xmlNodePtr node)
{
    while (node) {
        struct Callback *c = g_hash_table_lookup(i->callbacks, node->name);

        if (c)
            c->func(i, doc, node, c->data);

        node = node->next;
    }
}

gchar *parse_string(xmlDocPtr doc, xmlNodePtr node)
{
    xmlChar *c = xmlNodeListGetString(doc, node->children, YES);
    gchar *s = g_strdup(c ? (gchar*)c : "");
    xmlFree(c);
    return s;
}

int parse_int(xmlDocPtr doc, xmlNodePtr node)
{
    xmlChar *c = xmlNodeListGetString(doc, node->children, YES);
    int i = atoi((gchar*)c);
    xmlFree(c);
    return i;
}

BOOL parse_bool(xmlDocPtr doc, xmlNodePtr node)
{
    xmlChar *c = xmlNodeListGetString(doc, node->children, YES);
    BOOL b = NO;
    if (!xmlStrcasecmp(c, (const xmlChar*) "true"))
        b = YES;
    else if (!xmlStrcasecmp(c, (const xmlChar*) "yes"))
        b = YES;
    else if (!xmlStrcasecmp(c, (const xmlChar*) "on"))
        b = YES;
    xmlFree(c);
    return b;
}

BOOL parse_contains(const gchar *val, xmlDocPtr doc, xmlNodePtr node)
{
    xmlChar *c = xmlNodeListGetString(doc, node->children, YES);
    BOOL r;
    r = !xmlStrcasecmp(c, (const xmlChar*) val);
    xmlFree(c);
    return r;
}

xmlNodePtr parse_find_node(const gchar *tag, xmlNodePtr node)
{
    while (node) {
        if (!xmlStrcasecmp(node->name, (const xmlChar*) tag))
            return node;
        node = node->next;
    }
    return NULL;
}

BOOL parse_attr_int(const gchar *name, xmlNodePtr node, int *value)
{
    xmlChar *c = xmlGetProp(node, (const xmlChar*) name);
    BOOL r = NO;
    if (c) {
        *value = atoi((gchar*)c);
        r = YES;
    }
    xmlFree(c);
    return r;
}

BOOL parse_attr_string(const gchar *name, xmlNodePtr node, gchar **value)
{
    xmlChar *c = xmlGetProp(node, (const xmlChar*) name);
    BOOL r = NO;
    if (c) {
        *value = g_strdup((gchar*)c);
        r = YES;
    }
    xmlFree(c);
    return r;
}

BOOL parse_attr_contains(const gchar *val, xmlNodePtr node,
                             const gchar *name)
{
    xmlChar *c = xmlGetProp(node, (const xmlChar*) name);
    BOOL r;
    r = !xmlStrcasecmp(c, (const xmlChar*) val);
    xmlFree(c);
    return r;
}

static int slist_path_cmp(const gchar *a, const gchar *b)
{
    return strcmp(a, b);
}

typedef GSList* (*GSListFunc) (gpointer list, gconstpointer data);

static GSList* slist_path_add(GSList *list, gpointer data, GSListFunc func)
{
    g_assert(func);

    if (!data)
        return list;

    if (!g_slist_find_custom(list, data, (GCompareFunc) slist_path_cmp))
        list = func(list, data);

    return list;
}

void parse_paths_startup()
{
    NSString *p;
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    NSDictionary *env = [processInfo environment];

    if (xdg_start)
        return;
    xdg_start = YES;

    p = [env objectForKey: @"XDG_CONFIG_HOME"];
    if (p && [p length] > 0) /* not unset or empty */
	ASSIGNCOPY(xdg_config_home_path, p);
    else
	ASSIGN(xdg_config_home_path, [NSHomeDirectory() stringByAppendingPathComponent: @".config"]);

    p = [env objectForKey: @"XDG_DATA_HOME"];
    if (p && [p length] > 0) /* not unset or empty */
	ASSIGNCOPY(xdg_data_home_path, p);
    else
	ASSIGN(xdg_data_home_path, [[NSHomeDirectory() stringByAppendingPathComponent: @".local"] stringByAppendingPathComponent: @"share"]);

    p = [env objectForKey: @"XDG_CONFIG_DIRS"];
    xdg_config_dir_paths = [[NSMutableArray alloc] init];
    [xdg_config_dir_paths addObject: xdg_config_home_path];
    if (p && [p length] > 0) /* not unset or empty */
        [xdg_config_dir_paths addObjectsFromArray: [p componentsSeparatedByString: @":"]];
    else {
	[xdg_config_dir_paths addObject: [NSString pathWithComponents: [NSArray arrayWithObjects: @"/", @"etc", @"xdg", nil]]];
    }
    
    p = [env objectForKey: @"XDG_DATA_DIRS"];
    xdg_data_dir_paths = [[NSMutableArray alloc] init];
    [xdg_data_dir_paths addObject: xdg_data_home_path];
    if (p && [p length] > 0) /* not unset or empty */
        [xdg_data_dir_paths addObjectsFromArray: [p componentsSeparatedByString: @":"]];
    else {
	[xdg_data_dir_paths addObject: [NSString pathWithComponents: [NSArray arrayWithObjects: @"/", @"usr", @"local", @"share", nil]]];
	[xdg_data_dir_paths addObject: [NSString pathWithComponents: [NSArray arrayWithObjects: @"/", @"usr", @"share", nil]]];
    }
}

void parse_paths_shutdown()
{
    if (!xdg_start)
        return;
    xdg_start = NO;

    DESTROY(xdg_config_dir_paths);
    DESTROY(xdg_data_dir_paths);
}

char *parse_expand_tilde(char *f)
{
    if (!f) return NULL;
    NSString *p = [NSString stringWithCString: f];
    p = [p stringByExpandingTildeInPath];
    return g_strdup((char*)[p cString]);
}

static BOOL parse_mkdir(const gchar *path, int mode)
{
    BOOL ret = YES;

    g_return_val_if_fail(path != NULL, NO);
    g_return_val_if_fail(path[0] != '\0', NO);

    if (!g_file_test(path, G_FILE_TEST_IS_DIR))
        if (mkdir(path, mode) == -1)
            ret = NO;

    return ret;
}

BOOL parse_mkdir_path(const gchar *path, int mode)
{
    BOOL ret = YES;

    g_return_val_if_fail(path != NULL, NO);
    g_return_val_if_fail(path[0] == '/', NO);

    if (!g_file_test(path, G_FILE_TEST_IS_DIR)) {
        gchar *c, *e;

        c = g_strdup(path);
        e = c;
        while ((e = strchr(e + 1, '/'))) {
            *e = '\0';
            if (!(ret = parse_mkdir(c, mode)))
                goto parse_mkdir_path_end;
            *e = '/';
        }
        ret = parse_mkdir(c, mode);

    parse_mkdir_path_end:
        g_free(c);
    }

    return ret;
}

NSString* parse_xdg_config_home_path()
{
    return xdg_config_home_path;
}

NSString* parse_xdg_data_home_path()
{
    return xdg_data_home_path;
}

NSArray* parse_xdg_config_dir_paths()
{
    return xdg_config_dir_paths;
}

NSArray * parse_xdg_data_dir_paths()
{
    return xdg_data_dir_paths;
}
