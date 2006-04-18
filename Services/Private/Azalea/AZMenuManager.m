/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZMenuManager.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

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

#import "AZMenuManager.h"
#import "AZScreen.h"
#import "AZClient.h"
#import "AZClientManager.h"
#import "AZMenuFrame.h"
#import "openbox.h"
#import "config.h"
#import "geom.h"
#import "misc.h"
#import "client_menu.h"
#import "client_list_menu.h"
#import "parse.h"
#import "action.h"

typedef struct _ObMenuParseState ObMenuParseState;

struct _ObMenuParseState
{
    AZMenu *parent;
    AZMenu *pipe_creator;
};

static AZParser *menu_parse_inst = nil;
static ObMenuParseState menu_parse_state;

static void menu_destroy_hash_value(AZMenu *self);
static void parse_menu_item(AZParser *parser, xmlDocPtr doc, xmlNodePtr node,
                            gpointer data);
static void parse_menu_separator(AZParser *parser,
                                 xmlDocPtr doc, xmlNodePtr node,
                                 gpointer data);
static void parse_menu(AZParser *parser, xmlDocPtr doc, xmlNodePtr node,
                       gpointer data);

void menu_pipe_execute(AZMenu *self)
{
    xmlDocPtr doc;
    xmlNodePtr node;
    const char *output;

    if (![self execute])
        return;

#if 1
    NSString *command;
    NSArray *com = [[self execute] componentsSeparatedByString: @" "];
    NSArray *args = nil;
    if ([com count] > 1) {
      args = [com subarrayWithRange: NSMakeRange(1, [com count]-1)];
      command = [com objectAtIndex: 0];

    }
    else
    {
      command = [self execute];
    }
    NSPipe *pipe = [NSPipe pipe];
    NSTask *task = [[NSTask alloc] init];
    [task setStandardOutput: pipe];
    [task setLaunchPath: command];
    if (args)
      [task setArguments: args];
    [task launch];
    NSFileHandle *f_output = [pipe fileHandleForReading];
    NSData *data = [f_output readDataToEndOfFile];
    NSString *s = [[NSString alloc] initWithData: data encoding: [NSString defaultCStringEncoding]];
    output = [s UTF8String];
    AUTORELEASE(task);
#else
    GError *err = NULL;
    if (!g_spawn_command_line_sync((char*)[[self execute] cString], &output, NULL, NULL, &err)) {
        g_warning("Failed to execute command for pipe-menu: %s", err->message);
        g_error_free(err);
        return;
    }
#endif

    if (parse_load_mem((char*)output, strlen(output),
                       "openbox_pipe_menu", &doc, &node))
    {
	[[AZMenuManager defaultManager] removePipeMenu: self];
	[self clearEntries];

        menu_parse_state.pipe_creator = self;
        menu_parse_state.parent = self;
	[menu_parse_inst parseDocument: doc node: node->children];
        xmlFreeDoc(doc);
    } else {
        NSLog(@"Warning: Invalid output from pipe-menu: %@", [self execute]);
    }

//    g_free(output);
}

static void parse_menu_item(AZParser *parser, xmlDocPtr doc, xmlNodePtr node,
                            gpointer data)
{
    ObMenuParseState *state = data;
    NSString *label;
    
    if (state->parent) {
        if (parse_attr_string("label", node, &label)) {
	    NSMutableArray *acts = [[NSMutableArray alloc] init];

            for (node = node->children; node; node = node->next)
                if (!xmlStrcasecmp(node->name, (const xmlChar*) "action")) {
                    AZAction *a = action_parse
                        (doc, node, OB_USER_ACTION_MENU_SELECTION);
                    if (a)
			[acts addObject: a];
                }
	    [state->parent addNormalMenuEntry: -1 label: label actions: acts];
	    DESTROY(acts);
        }
    }
}

static void parse_menu_separator(AZParser *parser,
                                 xmlDocPtr doc, xmlNodePtr node,
                                 gpointer data)
{
    ObMenuParseState *state = data;

    if (state->parent)
	[state->parent addSeparatorMenuEntry: -1];
}

static void parse_menu(AZParser *parser, xmlDocPtr doc, xmlNodePtr node,
                       gpointer data)
{
    ObMenuParseState *state = data;
    NSString *name = nil, *title = nil, *script = nil;
    AZMenu *menu;

    if (!parse_attr_string("id", node, &name))
	return;

    if (![[AZMenuManager defaultManager] menuWithName: name]) {
        if (!parse_attr_string("label", node, &title))
	    return;

        if ((menu = [[AZMenu alloc] initWithName: name title: title])) {
            [menu set_pipe_creator: state->pipe_creator];
            if (parse_attr_string("execute", node, &script)) {
                [menu set_execute: [script stringByExpandingTildeInPath]];
            } else {
                AZMenu *old;

                old = state->parent;
                state->parent = menu;
		[parser parseDocument: doc node: node->children];
                state->parent = old;
            }
	    [[AZMenuManager defaultManager] registerMenu: menu];
	    DESTROY(menu);
        }
    }

    if (state->parent)
	[state->parent addSubmenuMenuEntry: -1 submenu: name];
}

static void menu_destroy_hash_value(AZMenu *self)
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

    DESTROY(self);
}

static AZMenuManager *sharedInstance;

@implementation AZMenuManager

+ (AZMenuManager *) defaultManager
{
  if (sharedInstance == nil)
    sharedInstance = [[AZMenuManager alloc] init];
  return sharedInstance; 
}

- (void) startup: (BOOL) reconfig
{
    xmlDocPtr doc;
    xmlNodePtr node;
    BOOL loaded = NO;
    int i, count;

    menu_hash = [[NSMutableDictionary alloc] init];

    client_list_menu_startup();
    client_menu_startup();

    menu_parse_inst = [[AZParser alloc] init];

    menu_parse_state.parent = nil;
    menu_parse_state.pipe_creator = nil;
    [menu_parse_inst registerTag: "menu" callback: parse_menu 
	                 data: &menu_parse_state];
    [menu_parse_inst registerTag: "item" callback: parse_menu_item 
	                 data: &menu_parse_state];
    [menu_parse_inst registerTag: "separator" callback: parse_menu_separator
	                 data: &menu_parse_state];

    count = [config_menu_files count];
    for (i = 0; i < count; i++) {
	if (parse_load_menu([config_menu_files objectAtIndex: i],
				&doc, &node))
	{
            loaded = YES;
	    [menu_parse_inst parseDocument: doc node: node->children];
            xmlFreeDoc(doc);
        }
    }
    if (!loaded) {
        if (parse_load_menu(@"menu.xml", &doc, &node)) {
	    [menu_parse_inst parseDocument: doc node: node->children];
            xmlFreeDoc(doc);
        }
    }
    
    NSAssert(menu_parse_state.parent == nil, @"menu_parse_state.parent is not nil");
}

- (void) shutdown: (BOOL) reconfig
{
    DESTROY(menu_parse_inst);

    AZMenuFrameHideAll();
    DESTROY(menu_hash);
}

- (AZMenu *) menuWithName: (NSString *) name
{
    AZMenu *menu = nil;

    NSAssert(name != nil, @"menuWithName: cannot take 'nil'.");

    if (!(menu = [menu_hash objectForKey: name]))
	NSLog(@"Warning: Attemped to access menu '%@' but it does not exist.", name);
    return menu;
}  

- (void) removeMenu: (AZMenu *) menu
{
  /* make sure its not visible */
  {
    NSArray *visibles = [AZMenuFrame visibleFrames];
    int i, count = [visibles count];
    AZMenuFrame *f;

    for (i = 0; i < count; i++) {
      f = [visibles objectAtIndex: i];
      if ([f menu] == menu)
        AZMenuFrameHideAll();
    }
  }

  [menu_hash removeObjectForKey: [menu name]];
}

- (void) removePipeMenu: (AZMenu *) pipe_menu
{
  NSArray *keys = [menu_hash allKeys];
  int i, count = [keys count];
  for (i = 0; i < count; i++) {
     AZMenu *m = [menu_hash objectForKey: [keys objectAtIndex: i]];
     if ([m pipe_creator] == pipe_menu) {
       [self removeMenu: m];
     }
  }
}

- (void) showMenu: (NSString *) name x: (int) x y: (int) y 
	   client: (AZClient *) client
{
    AZMenu *menu;
    AZMenuFrame *frame;
    unsigned int i;

    if (!(menu = [self menuWithName: name])) return;

    /* if the requested menu is already the top visible menu, then don't
       bother */
    NSArray *visibles = [AZMenuFrame visibleFrames];
    if ([visibles count]) {
	frame = [visibles objectAtIndex: 0];
        if ([frame menu] == menu)
            return;
    }

    AZMenuFrameHideAll();

    frame = [[AZMenuFrame alloc] initWithMenu: menu client: client];
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

- (void) registerMenu: (AZMenu *) menu
{
  AZMenu *m = nil;
  if ((m = [menu_hash objectForKey: [menu name]]))  {
    [self removeMenu: m];
  }
  [menu_hash setObject: menu forKey: [menu name]];
}

@end

