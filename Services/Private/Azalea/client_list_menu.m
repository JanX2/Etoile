/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   client_list_menu.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

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
#import "AZMenuManager.h"
#import "AZClientManager.h"
#import "openbox.h"
#import "AZMenu.h"
#import "action.h"
#import "config.h"

#define MENU_NAME @"client-list-menu"

static NSMutableArray *desktop_menus;
static AZMenu *client_list_menu;

@interface AZDesktopMenu: AZMenu
{
  unsigned int data;
}

- (id) initWithName: (NSString *) name title: (NSString *) title desktop: (unsigned int) desktop;
@end

@implementation AZDesktopMenu

- (id) initWithName: (NSString *) n title: (NSString *) t desktop: (unsigned int) d
{
  self = [super initWithName: n title: t];
  data = d;
  return self;
}

- (void) update: (AZMenuFrame *) frame 
{
    AZMenu *menu = [frame menu];
    int i;
    int j, jcount;
    BOOL icons = NO;
    BOOL empty = YES;

    [menu clearEntries];

    AZFocusManager *fManager = [AZFocusManager defaultManager];
    jcount = [fManager numberOfFocusOrderInScreen: data];
    for (j = 0, i = 0; j < jcount; j++, ++i) {
        AZClient *c = [fManager focusOrder: j inScreen: data];
        if ([c normal] && ![c skip_taskbar]) {
	    NSMutableArray *acts = [[NSMutableArray alloc] init];
            AZAction* act;
            AZNormalMenuEntry *e;
            AZClientIcon *icon;

            empty = NO;

            if (!icons && [c iconic]) {
                icons = YES;
		[menu addSeparatorMenuEntry: -1];
            }

            act = [AZAction actionWithName: @"Activate" userAction: OB_USER_ACTION_MENU_SELECTION];
            [act data_pointer]->activate.any.c = c;
	    [acts addObject: act];
            act = [AZAction actionWithName: @"Desktop" userAction: OB_USER_ACTION_MENU_SELECTION];
            [act data_pointer]->desktop.desk = data;
	    [acts addObject: act];
	    e = [menu addNormalMenuEntry: i label: ([c iconic] ? [c icon_title] : [c title]) actions: acts];
	    DESTROY(acts);

            if (config_menu_client_list_icons && 
		(icon = [c iconWithWidth: 32 height: 32])) {
                [e set_icon_width: [icon width]];
                [e set_icon_height: [icon height]];
                [e set_icon_data: [icon data]];
            }
        }
    }

    if (empty) {
        /* no entries */

        AZAction* act;
        AZNormalMenuEntry *e;

        act = [AZAction actionWithName: @"Desktop" userAction: OB_USER_ACTION_MENU_SELECTION];
        [act data_pointer]->desktop.desk = data;
	e = [menu addNormalMenuEntry: 0 label: @"Go there..." actions: [NSArray arrayWithObjects: act, nil]];
        if (data == [[AZScreen defaultScreen] desktop])
            [e set_enabled: NO];
    }
}

/* executes it using the client in the actions, since we set that
   when we make the actions! */
- (BOOL) execute: (AZMenuEntry *) entry state: (unsigned int) state
{
    AZAction *a;

    if ([entry isKindOfClass: [AZNormalMenuEntry class]] &&
		    [(AZNormalMenuEntry *)entry actions]) {
	AZNormalMenuEntry *e = (AZNormalMenuEntry *) entry;
        a = [[e actions] objectAtIndex: 0];
        action_run([e actions], [a data].any.c, state);
    }
    return YES;
}

- (void) dealloc
{
  [desktop_menus removeObject: self];
  [super dealloc];
}
@end

@interface AZClientListMenu: AZMenu
@end

@implementation AZClientListMenu

- (void) update: (AZMenuFrame *) frame 
{
    AZMenu *menu = [frame menu];
    unsigned int i, j;

    AZScreen *screen = [AZScreen defaultScreen];
    for (i = 0; i < [screen numberOfDesktops]; ++i) {
        if (i >= [desktop_menus count]) {
            AZDesktopMenu *submenu;
	    NSString *n = [NSString stringWithFormat: @"%@-%u", MENU_NAME, i];
	    submenu = [[AZDesktopMenu alloc] initWithName: n title: [screen nameOfDesktopAtIndex: i] desktop: i];

	    [menu addSubmenuMenuEntry: i submenu: n];
	    [[AZMenuManager defaultManager] registerMenu: submenu];
	    RELEASE(submenu);

	    [desktop_menus addObject: submenu];
        } 
    }

    for (j = [desktop_menus count]-1; j > i-1; j--) {
	[[AZMenuManager defaultManager] removeMenu: [desktop_menus objectAtIndex: j]];
	[desktop_menus removeObjectAtIndex: j];
	[menu removeEntryWithIdentifier: j];
    }
}

- (void) clientDestroy: (NSNotification *) not
{
    /* This concise function removes all references to a closed
     * client in the client_list_menu, so we don't have to check
     * in client.c */
     int i, j;
     for (i = 0; i < [desktop_menus count]; i++) {
	AZMenu *mit = [desktop_menus objectAtIndex: i];
	NSArray *mentries = [mit entries];
	for (j = 0; j < [mentries count]; j++) {
	    AZMenuEntry *meit = [mentries objectAtIndex: i];
	    if ([meit type] == OB_MENU_ENTRY_TYPE_NORMAL) {
	      AZAction *a = [[(AZNormalMenuEntry *)meit actions] objectAtIndex: 0];
	      AZClient *c = [a data].any.c;
	      if (c == [not object])
	        [a data_pointer]->any.c = NULL;
	    }
	}
     }
}

@end

void client_list_menu_startup(BOOL reconfig)
{
    if (desktop_menus == nil) {
      desktop_menus = [[NSMutableArray alloc] init];
    } else {
      [desktop_menus removeAllObjects];
    }

    client_list_menu = [[AZClientListMenu alloc] initWithName: MENU_NAME 
	                                                title: @"Desktops"];
    [[AZMenuManager defaultManager] registerMenu: client_list_menu];
    if (!reconfig) {
      [[NSNotificationCenter defaultCenter] addObserver: client_list_menu
		            selector: @selector(clientDestroy:)
			    name: AZClientDestroyNotification
			    object: nil];
    }
}

void client_list_menu_shutdown(BOOL reconfig)
{
    if (!reconfig) {
      [[NSNotificationCenter defaultCenter] removeObserver: client_list_menu];
    }
    DESTROY(client_list_menu);
}
