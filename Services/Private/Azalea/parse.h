// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   parse.h for the Openbox window manager
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

#ifndef __parse_h
#define __parse_h

#import <Foundation/Foundation.h>
#import "version.h"
#import <libxml/parser.h>
#import <glib.h>

typedef struct _ObParseInst ObParseInst;

typedef void (*ParseCallback)(ObParseInst *i, xmlDocPtr doc, xmlNodePtr node,
                              gpointer data);

@interface AZParser: NSObject
{
  struct _ObParseInst *obParseInst;
}
- (ObParseInst *) obParseInst;
@end

/* Loads Openbox's rc, from the normal paths */
BOOL parse_load_rc(xmlDocPtr *doc, xmlNodePtr *root);
/* Loads an Openbox menu, from the normal paths */
BOOL parse_load_menu(const gchar *file, xmlDocPtr *doc, xmlNodePtr *root);

void parse_register(ObParseInst *inst, const gchar *tag,
                    ParseCallback func, gpointer data);
void parse_tree(ObParseInst *inst, xmlDocPtr doc, xmlNodePtr node);


/* open/close */

BOOL parse_load(const gchar *path, const gchar *rootname,
                    xmlDocPtr *doc, xmlNodePtr *root);
BOOL parse_load_mem(gpointer data, unsigned int len, const gchar *rootname,
                        xmlDocPtr *doc, xmlNodePtr *root);
void parse_close(xmlDocPtr doc);


/* helpers */

xmlNodePtr parse_find_node(const gchar *tag, xmlNodePtr node);

gchar *parse_string(xmlDocPtr doc, xmlNodePtr node);
int parse_int(xmlDocPtr doc, xmlNodePtr node);
BOOL parse_bool(xmlDocPtr doc, xmlNodePtr node);

BOOL parse_contains(const gchar *val, xmlDocPtr doc, xmlNodePtr node);
BOOL parse_attr_contains(const gchar *val, xmlNodePtr node,
                             const gchar *name);

BOOL parse_attr_string(const gchar *name, xmlNodePtr node, gchar **value);
BOOL parse_attr_int(const gchar *name, xmlNodePtr node, int *value);

/* paths */

void parse_paths_startup();
void parse_paths_shutdown();

NSString *parse_xdg_config_home_path();
NSString *parse_xdg_data_home_path();
NSArray *parse_xdg_config_dir_paths();
NSArray *parse_xdg_data_dir_paths();

/*! Expands the ~ character to the home directory throughout the given
  string */
char *parse_expand_tilde(char *f);
/*! Makes a directory and all its parents */
BOOL parse_mkdir_path(const gchar *path, int mode);

#endif
