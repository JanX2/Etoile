/* 
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

#import "AppController.h"
#import "FeedList.h"
#import "RSSReaderService.h"

@implementation AppController

+ (void)initialize
{
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];

  /*
   * Register your app's defaults here by adding objects to the
   * dictionary, eg
   *
   * [defaults setObject:anObject forKey:keyForThatObject];
   *
   */
  [defaults setObject: @"/usr/bin/dillo" forKey: @"WebBrowser"];

  [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id)init
{
  if ((self = [super init]))
    {
    }
  return self;
}

- (void)dealloc
{
  [super dealloc];
}

- (void)awakeFromNib
{
  /* This will be called multiple times because interfaces are loaded
   * multiple times 
   */
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotif
{
  [[NSApp mainMenu] setTitle:@"RSSReader"];
  [NSBundle loadNibNamed: @"Preferences" owner: self];
  [NSBundle loadNibNamed: @"ErrorLogPanel" owner: self];
  NSLog(@"%@", prefPanel);

  /* Register service... */
  [NSApp setServicesProvider: [[RSSReaderService alloc] init]];
  
  [logPanel setFrameAutosaveName: @"logPanel"];
  [feedManagementPanel setFrameAutosaveName: @"feedManagementPanel"];
  [prefPanel setFrameAutosaveName: @"prefPanel"];
  [mainWindow setFrameAutosaveName: @"mainWindow"];
}

- (BOOL)applicationShouldTerminate:(id)sender
{
  // create directory
  [[NSFileManager defaultManager]
    createDirectoryAtPath: [FeedList storeDir]
    attributes: nil ];
  
  [NSArchiver
    archiveRootObject: getFeedList()
    toFile: [FeedList storeFile]];  
  return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotif
{
}

- (BOOL)application:(NSApplication *)application openFile:(NSString *)fileName
{
  NSURL* fileURL = [[NSURL alloc] initFileURLWithPath: fileName];
  [getFeedList() addFeedWithURL: fileURL];
  RELEASE(fileURL);
}

- (void)showPrefPanel:(id)sender
{
  [prefPanel orderFront: self];
}

-(void)update: (id) sender
{
  [feedTable reloadData];
  [feedTable setNeedsDisplay: YES];
  
  [mainTable reloadData];
  [mainTable setNeedsDisplay: YES];
}

@end
