/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   parse.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

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
#import <XWindowServerKit/XFunctions.h>
#import "parse.h"
#import <string.h>
#import <errno.h>
#import <sys/stat.h>
#import <sys/types.h>

static BOOL xdg_start;
static NSMutableArray *xdg_config_dir_paths;
static NSMutableArray *xdg_data_dir_paths;

@interface AZCallback: NSObject
{
    NSString *tag;
    ParseCallback func;
    void *data;
}
- (NSString *) tag;
- (ParseCallback) func;
- (void *) data;
- (void) set_tag: (NSString *) tag;
- (void) set_func: (ParseCallback) func;
- (void) set_data: (void *) data;
@end

@implementation AZCallback
- (NSString *) tag { return tag; }
- (ParseCallback) func { return func; }
- (void *) data { return data; }
- (void) set_tag: (NSString *) t { ASSIGNCOPY(tag, t); }
- (void) set_func: (ParseCallback) f { func = f; }
- (void) set_data: (void *) d { data = d; }
- (void) dealloc
{
  DESTROY(tag);
  [super dealloc];
}
@end

@implementation AZParser

- (id) init
{
    self = [super init];
    callbacks = [[NSMutableDictionary alloc] init];
    return self;
}

- (void) dealloc
{
    DESTROY(callbacks);
    [super dealloc];
}

- (void) registerTag: (NSString *) tag callback: (ParseCallback) func 
                data: (void *) data
{
    AZCallback *c;

    if ((c = [callbacks objectForKey: tag])) {
        NSLog(@"Warning: tag '%@' already registered", tag);
        return;
    }

    c = [[AZCallback alloc] init];
    [c set_tag: tag];
    [c set_func: func];
    [c set_data: data];
    [callbacks setObject: c forKey: tag];
    DESTROY(c);
}

- (void) parseDocument: (xmlDocPtr) doc node: (xmlNodePtr) node;
{
    while (node) {
        AZCallback *c = [callbacks objectForKey: [NSString stringWithCString: (char*)(node->name)]];

        if (c)
            [c func](self , doc, node, [c data]);
        node = node->next;
    }
}

@end

BOOL parse_load_rc(xmlDocPtr *doc, xmlNodePtr *root)
{
    NSString *path;
    BOOL r = NO;

    int i, count = [xdg_config_dir_paths count];
    for (i = 0; !r && (i < count); i++) {

	path = [NSString pathWithComponents: [NSArray arrayWithObjects:
		[xdg_config_dir_paths objectAtIndex: i],
		@"openbox", @"rc.xml", nil]];
        r = parse_load(path, "openbox_config", doc, root);
    }
    if (!r)
        NSLog(@"Warning: unable to find a valid config file, using defaults");
    return r;
}

BOOL parse_load_menu(NSString *file, xmlDocPtr *doc, xmlNodePtr *root)
{
    NSString *path;
    BOOL r = NO;

    if ([file isAbsolutePath]) {
        r = parse_load(file, "openbox_menu", doc, root);
    } else {
        int i, count = [xdg_config_dir_paths count];
        for (i = 0; !r && (i < count); i++) {
	    path = [NSString pathWithComponents: [NSArray arrayWithObjects:
		[xdg_config_dir_paths objectAtIndex: i],
		@"openbox", file, nil]];
            r = parse_load(path, "openbox_menu", doc, root);
        }
    }
    if (!r)
        NSLog(@"Warning: unable to find a valid menu file '%@'", file);
    return r;
}

BOOL parse_load(NSString *path, const char *rootname,
                    xmlDocPtr *doc, xmlNodePtr *root)
{
    if ((*doc = xmlParseFile([path fileSystemRepresentation]))) {
        *root = xmlDocGetRootElement(*doc);
        if (!*root) {
            xmlFreeDoc(*doc);
            *doc = NULL;
            NSLog(@"%@ is an empty document", path);
        } else {
            if (xmlStrcasecmp((*root)->name, (const xmlChar*)rootname)) {
                xmlFreeDoc(*doc);
                *doc = NULL;
                NSLog(@"document %@ is of wrong type. root node is "
                          "not '%s'", path, rootname);
            }
        }
    }
    if (!*doc)
        return NO;
    return YES;
}

BOOL parse_load_mem(void *data, unsigned int len, const char *rootname,
                        xmlDocPtr *doc, xmlNodePtr *root)
{
    if ((*doc = xmlParseMemory(data, len))) {
        *root = xmlDocGetRootElement(*doc);
        if (!*root) {
            xmlFreeDoc(*doc);
            *doc = NULL;
            NSLog(@"Warning: Given memory is an empty document");
        } else {
            if (xmlStrcasecmp((*root)->name, (const xmlChar*)rootname)) {
                xmlFreeDoc(*doc);
                *doc = NULL;
                NSLog(@"Warning: document in given memory is of wrong type. root "
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

NSString *parse_string(xmlDocPtr doc, xmlNodePtr node)
{
    xmlChar *c = xmlNodeListGetString(doc, node->children, YES);
    NSString *s;
    if (c)
      s = [NSString stringWithUTF8String: (char*)c]; 
    else
      s = [NSString string];
    xmlFree(c);
    return s;
}

int parse_int(xmlDocPtr doc, xmlNodePtr node)
{
    xmlChar *c = xmlNodeListGetString(doc, node->children, YES);
    int i = atoi((char*)c);
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

BOOL parse_contains(const char *val, xmlDocPtr doc, xmlNodePtr node)
{
    xmlChar *c = xmlNodeListGetString(doc, node->children, YES);
    BOOL r;
    r = !xmlStrcasecmp(c, (const xmlChar*) val);
    xmlFree(c);
    return r;
}

xmlNodePtr parse_find_node(const char *tag, xmlNodePtr node)
{
    while (node) {
        if (!xmlStrcasecmp(node->name, (const xmlChar*) tag))
            return node;
        node = node->next;
    }
    return NULL;
}

BOOL parse_attr_int(const char *name, xmlNodePtr node, int *value)
{
    xmlChar *c = xmlGetProp(node, (const xmlChar*) name);
    BOOL r = NO;
    if (c) {
        *value = atoi((char*)c);
        r = YES;
    }
    xmlFree(c);
    return r;
}

BOOL parse_attr_string(const char *name, xmlNodePtr node, NSString **value)
{
    xmlChar *c = xmlGetProp(node, (const xmlChar*) name);
    BOOL r = NO;
    if (c) {
	*value = [NSString stringWithUTF8String: (char*)c ];
        r = YES;
    }
    xmlFree(c);
    return r;
}

BOOL parse_attr_contains(const char *val, xmlNodePtr node, const char *name)
{
    xmlChar *c = xmlGetProp(node, (const xmlChar*) name);
    BOOL r;
    r = !xmlStrcasecmp(c, (const xmlChar*) val);
    xmlFree(c);
    return r;
}

void parse_paths_startup()
{
    if (xdg_start)
        return;
    xdg_start = YES;

    /* We add resource path in the end so that 
       it can find the default setting */
    xdg_config_dir_paths = [NSMutableArray arrayWithArray: XDGConfigDirectories()];
    [xdg_config_dir_paths addObject: [[NSBundle mainBundle] resourcePath]];
    RETAIN(xdg_config_dir_paths);

    xdg_data_dir_paths = [NSMutableArray arrayWithArray: XDGDataDirectories()];
    [xdg_data_dir_paths addObject: [[NSBundle mainBundle] resourcePath]];
    RETAIN(xdg_data_dir_paths);
}

void parse_paths_shutdown()
{
    if (!xdg_start)
        return;
    xdg_start = NO;

    DESTROY(xdg_config_dir_paths);
    DESTROY(xdg_data_dir_paths);
}

BOOL parse_mkdir_path(NSString *path, int mode)
{
    if ((path == nil) || ([path isAbsolutePath] == NO)) 
      return NO;

    BOOL isDir;
    NSFileManager *fm = [NSFileManager defaultManager];

    if ([fm fileExistsAtPath: path isDirectory: &isDir] && (isDir == YES))
      return YES;

    /* Make each subdirectory */
    NSEnumerator *e = [[path pathComponents] objectEnumerator];
    NSString *p, *test_path = @"";
    while ((p = [e nextObject])) {
      test_path = [test_path stringByAppendingPathComponent: p];
      if ([fm fileExistsAtPath: test_path isDirectory: &isDir] == NO) {
	/* Create new */
	[fm createDirectoryAtPath: test_path
		attributes: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: mode] forKey: NSFilePosixPermissions]];
      } else {
	if (isDir == NO) {
          /* file exists, but not a directory: failed */
	  return NO;
	} else {
	  /* directory exists */
          continue;
	}
      }
    }
    return YES;
}

NSArray* parse_xdg_config_dir_paths()
{
    return xdg_config_dir_paths;
}

NSArray * parse_xdg_data_dir_paths()
{
    return xdg_data_dir_paths;
}
