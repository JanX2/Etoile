/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   client_list_menu.c for the Openbox window manager
   Copyright (c) 2006        Mikael Magnusson
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

#import "openbox.h"
#import "AZMenuManager.h"
#import "AZMenu.h"
#import "AZMenuFrame.h"
#import "action.h"
#import "AZScreen.h"
#import "AZClient.h"
#import "AZClientManager.h"
#import "AZFocusManager.h"
#import "config.h"

#define MENU_NAME @"client-list-combined-menu"

static AZMenu *combined_menu;

@interface AZCombinedMenu: AZMenu
@end

@implementation AZCombinedMenu

- (void) update: (AZMenuFrame *) frame
{
    AZMenu *menu = [frame menu];
    unsigned int i, j, jcount, desktop;
    BOOL icons = NO;
  
    [menu clearEntries];
    
    AZScreen *screen = [AZScreen defaultScreen];
    AZFocusManager *fManager = [AZFocusManager defaultManager];
    for (desktop = 0; desktop < [screen numberOfDesktops]; desktop++) 
    {
      jcount = [fManager numberOfFocusOrderInScreen: desktop];
      for (j = 0, i = 0; j < jcount; j++, ++i)
      {
        AZClient *c = [fManager focusOrder: j inScreen: desktop];
        if ([c normal] && (![c skip_taskbar] || [c iconic]))
        {
          NSMutableArray *acts = [[NSMutableArray alloc] init];
          AZAction *act;
          AZNormalMenuEntry *e;
          AZClientIcon *icon;

          if ((icons == NO) &&  [c iconic])
          {
            icons = YES;
            [menu addSeparatorMenuEntry: -1];
          }

          act = [AZAction actionWithName: @"Activate" 
                              userAction: OB_USER_ACTION_MENU_SELECTION];
          [act data_pointer]->activate.any.c = c;
          [acts addObject: act];
          act = [AZAction actionWithName: @"Desktop" 
                              userAction: OB_USER_ACTION_MENU_SELECTION];
          [act data_pointer]->desktop.desk = desktop;
          [acts addObject: act];
          e = [menu addNormalMenuEntry: i
                                 label: ([c iconic] ? [c icon_title] : [c title])
                               actions: acts];
          if (config_menu_client_list_icons &&
              (icon = [c iconWithWidth: 32 height: 32])) 
          {
              [e set_icon_width: [icon width]];
              [e set_icon_height: [icon height]];
              [e set_icon_data: [icon data]];
          }
        }
      }
      [menu addSeparatorMenuEntry: -1];
      [menu addSeparatorMenuEntry: -1];
      icons = NO;
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

- (void) clientDestroy: (NSNotification *) not
{
    /* This concise function removes all references to a closed
     * client in the client_list_menu, so we don't have to check
     * in client.c */
    NSArray *mentries = [combined_menu entries];
    int i, count = [mentries count];
    for (i = 0; i < count; i++) 
    {
        AZMenuEntry *it = [mentries objectAtIndex: i];
        if ([it type] == OB_MENU_ENTRY_TYPE_NORMAL) 
        {
            AZAction *a = [[(AZNormalMenuEntry *)it actions] objectAtIndex: 0];
            AZClient *c = [a data].any.c;
            if (c == [not object]) 
            {
                [a data_pointer]->any.c = NULL;
            }
        }
    }
}

@end

void client_list_combined_menu_startup(BOOL reconfig)
{
    combined_menu = [[AZCombinedMenu alloc] initWithName: MENU_NAME
                                                   title: @"Windows"];
    [[AZMenuManager defaultManager] registerMenu: combined_menu];

//    if (!reconfig)
    {
      [[NSNotificationCenter defaultCenter] addObserver: combined_menu 
                            selector: @selector(clientDestroy:)
                            name: AZClientDestroyNotification
                            object: nil];
    }
}

void client_list_combined_menu_shutdown(BOOL reconfig)
{
//    if (!reconfig)
    {
      [[NSNotificationCenter defaultCenter] removeObserver: combined_menu];
    }
    DESTROY(combined_menu);
}
