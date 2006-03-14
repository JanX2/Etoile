/* -*-objc-*-
   
   Project: RSSReader

   Copyright (C) 2005 Free Software Foundation

   Author: Guenther Noack,,,

   Created: 2005-03-25 19:42:31 +0100 by guenther
   
   Application Controller

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
 
   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
 
   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/
 
#ifndef _PCAPPPROJ_APPCONTROLLER_H
#define _PCAPPPROJ_APPCONTROLLER_H

#include <AppKit/AppKit.h>

@class FeedManagement;

@interface AppController : NSObject
{
  NSTableView* feedTable;
  NSTableView* mainTable;
  
  NSPanel* logPanel;
  NSPanel* feedManagementPanel;
  NSPanel* prefPanel;
  NSWindow* mainWindow;

  FeedManagement *feedManagement;
}

+ (void)initialize;

- (id)init;
- (void)dealloc;

- (void)awakeFromNib;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotif;
- (BOOL)applicationShouldTerminate:(id)sender;
- (void)applicationWillTerminate:(NSNotification *)aNotif;
- (BOOL)application:(NSApplication *)application openFile:(NSString *)fileName;

- (void)showPrefPanel:(id)sender;

- (void)update: (id) sender;

@end


#endif
