/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   parse.h for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

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

@class AZParser;

typedef void (*ParseCallback)(AZParser *i, xmlDocPtr doc, xmlNodePtr node,
                              void *data);

@interface AZParser: NSObject
{
  NSMutableDictionary *callbacks;
}
- (void) registerTag: (NSString *) tag callback: (ParseCallback) func data: (void *) data;
- (void) parseDocument: (xmlDocPtr) doc node: (xmlNodePtr) node;
             
@end 

/* Loads Openbox's rc, from the normal paths */
BOOL parse_load_rc(xmlDocPtr *doc, xmlNodePtr *root);
/* Loads an Openbox menu, from the normal paths */
BOOL parse_load_menu(NSString *file, xmlDocPtr *doc, xmlNodePtr *root);

/* open/close */

BOOL parse_load(NSString *path, const char *rootname,
                    xmlDocPtr *doc, xmlNodePtr *root);
BOOL parse_load_mem(void *data, unsigned int len, const char *rootname,
                        xmlDocPtr *doc, xmlNodePtr *root);
void parse_close(xmlDocPtr doc);


/* helpers */

xmlNodePtr parse_find_node(const char *tag, xmlNodePtr node);

/* Autoreleased string */
NSString *parse_string(xmlDocPtr doc, xmlNodePtr node);
int parse_int(xmlDocPtr doc, xmlNodePtr node);
BOOL parse_bool(xmlDocPtr doc, xmlNodePtr node);

BOOL parse_contains(const char *val, xmlDocPtr doc, xmlNodePtr node);
BOOL parse_attr_contains(const char *val, xmlNodePtr node, const char *name);

/* return autoreleased string */
BOOL parse_attr_string(const char *name, xmlNodePtr node, NSString **value);
BOOL parse_attr_int(const char *name, xmlNodePtr node, int *value);
BOOL parse_attr_bool(const char *name, xmlNodePtr node, BOOL *value);

/* paths */

void parse_paths_startup();
void parse_paths_shutdown();

NSArray *parse_xdg_config_dir_paths();
NSArray *parse_xdg_data_dir_paths();

/*! Makes a directory and all its parents */
BOOL parse_mkdir_path(NSString *path, int mode);

#endif
