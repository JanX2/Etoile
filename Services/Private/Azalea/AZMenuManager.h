/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZMenuManager.h for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

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

#import <Foundation/Foundation.h>
#import "AZMenu.h"

@class AZClient;

@interface AZMenuManager: NSObject
{
  NSMutableDictionary *menu_hash;
}

+ (AZMenuManager *) defaultManager;

- (void) startup: (BOOL) reconfig;
- (void) shutdown: (BOOL) reconfig;

- (AZMenu *) menuWithName: (NSString *) name;
- (void) removeMenu: (AZMenu *) menu;
- (void) removePipeMenu: (AZMenu *) pipe_menu;
- (void) showMenu: (NSString *) name x: (int) x y: (int) y client: (AZClient *) client;
- (void) registerMenu: (AZMenu *) menu;

@end

void menu_pipe_execute(AZMenu *menu);

