/*
    ApplicationsEntry.m

    Implementation of the ApplicationsEntry class for the
    EtoileMenuServer application.

    Copyright (C) 2005, 2006  Saso Kiselkov

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#import "ApplicationsEntry.h"

#import <Foundation/NSBundle.h>
#import <Foundation/NSConnection.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSException.h>
#import <Foundation/NSHost.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSString.h>
#import <Foundation/NSUserDefaults.h>

#import <AppKit/NSApplication.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSImageView.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSWorkspace.h>

#import <sys/types.h>
#import <signal.h>
#import <errno.h>
#import <string.h>

//#import <WorkspaceCommKit/WorkspaceCommKit.h>

@implementation ApplicationsEntry

- (void) dealloc
{
  [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver: self];

  TEST_RELEASE(launchedApplications);

  TEST_RELEASE(menuItem);
  TEST_RELEASE(menu);

  [super dealloc];
}

- init
{
  if ((self = [super init]) != nil)
    {
      NSNotificationCenter * nc = [[NSWorkspace sharedWorkspace]
        notificationCenter];

      [nc addObserver: self
             selector: @selector(noteAppListChanged:)
                 name: NSWorkspaceDidLaunchApplicationNotification
               object: nil];
      [nc addObserver: self
             selector: @selector(noteAppListChanged:)
                 name: NSWorkspaceDidTerminateApplicationNotification
               object: nil];
    }

  return self;
}

- (id <NSMenuItem>) menuItem
{
  NSMenuItem * item;

  // build the Applications -> Applications menu item and submenu
  menuItem = [[NSMenuItem alloc]
    initWithTitle: _(@"Applications")
           action: NULL
    keyEquivalent: nil];

  menu = [[NSMenu alloc] initWithTitle: _(@"Applications")];
  [menuItem setSubmenu: menu];

  // add the top two elements in the Applications submenu:
  // - the "Applications List..." menu item
  // - the separator
  item = [[[NSMenuItem alloc]
    initWithTitle: _(@"Applications List...")
           action: @selector(showApplicationsPanel:)
    keyEquivalent: nil]
    autorelease];
  [item setTarget: self];
  [menu addItem: item];

//  [menu addItem: [NSMenuItem separatorItem]];

  // synthetize the first app change so that we load the initial list
  [self noteAppListChanged: nil];

  return menuItem;
}

- (void) noteAppListChanged: (NSNotification *) notif
{
  NSWorkspace * ws = [NSWorkspace sharedWorkspace];
  NSArray * newAppList = [ws launchedApplications];
  NSArray * oldAppNames, * newAppNames;
  int oldAppCount, newAppCount;

  oldAppNames = [launchedApplications valueForKey: @"NSApplicationName"];
  oldAppCount = [oldAppNames count];

  newAppNames = [newAppList valueForKey: @"NSApplicationName"];
  newAppCount = [newAppNames count];

  NSDebugLLog(@"ApplicationsEntry", @"Running apps list changed to: %@",
    newAppNames);

  // apps have been launched
  if (newAppCount > oldAppCount)
    {
      int i, n;

      if (oldAppCount == 0)
        {
          [menu insertItem: [NSMenuItem separatorItem] atIndex: 0];
        }

      for (i = 0, n = [newAppNames count]; i < n; i++)
        {
          NSString * appName = [newAppNames objectAtIndex: i];

          if (![oldAppNames containsObject: appName])
            {
              NSString * appPath = [[newAppList objectAtIndex: i]
                objectForKey: @"NSApplicationPath"];
              NSImage * icon = [[[ws iconForFile: appPath] copy] autorelease];
              NSMenuItem * appMenuItem;

              [icon setScalesWhenResized: YES];
              [icon setSize: NSMakeSize(18, 18)];

              appMenuItem = [[[NSMenuItem alloc]
                initWithTitle: appName
                       action: @selector(activateApplication:)
                keyEquivalent: nil]
                autorelease];
              [appMenuItem setTarget: self];
              [appMenuItem setImage: icon];

              [menu insertItem: appMenuItem atIndex: i];
            }
        }
    }
  // apps have been terminated
  else if (newAppCount < oldAppCount)
    {
      int i, n;

      for (i = 0, n = [oldAppNames count]; i < n; i++)
        {
          NSString * appName = [oldAppNames objectAtIndex: i];

          if (![newAppNames containsObject: appName])
            {
              [menu removeItemAtIndex: i];
            }
        }

      // remove the unneeded menu item separator
      if (newAppCount == 0)
        {
          [menu removeItemAtIndex: 0];
        }
    }

  [menu sizeToFit];

  ASSIGN(launchedApplications, newAppList);

  if (window != nil)
    {
      // refresh the interface if necessary

      [appTable reloadData];
      [self showApplication: self];
    }
}

- (NSString *) menuGroup
{
  return @"Etoile";
}

- (void) awakeFromNib
{
  [appTable setDoubleAction: @selector(activateApplication:)];
}

- (void) showApplicationsPanel: sender
{
  if (window == nil)
    {
      [NSBundle loadNibNamed: @"ApplicationsPanel" owner: self];
    }

  [window makeKeyAndOrderFront: nil];
}

- (void) showApplication: sender
{
  int row = [appTable selectedRow];

  if (row >= 0)
    {
      NSDictionary * entry = [launchedApplications objectAtIndex: row];
      NSString * appName = [entry objectForKey: @"NSApplicationName"],
               * appPath = [entry objectForKey: @"NSApplicationPath"];

      [appIcon setImage: [[NSWorkspace sharedWorkspace]
        iconForFile: appPath]];
      [appNameField setStringValue: appName];
      [appPathField setStringValue: appPath];
      [appPIDField setObjectValue: [entry objectForKey:
        @"NSApplicationProcessIdentifier"]];

      [killButton setEnabled: YES];
      [killButton setTransparent: NO];
    }
  else
    {
      [appIcon setImage: nil];
      [appNameField setStringValue: nil];
      [appPathField setStringValue: nil];
      [appPIDField setStringValue: nil];

      [killButton setEnabled: NO];
      [killButton setTransparent: YES];
    }
}

- (void) kill: sender
{
  NSDictionary * entry = [launchedApplications objectAtIndex: [appTable
    selectedRow]];
  NSString * appName = [entry objectForKey: @"NSApplicationName"];
  int pid = [[entry objectForKey: @"NSApplicationProcessIdentifier"] intValue];

  if (NSRunAlertPanel(_(@"Really kill application?"),
    _(@"Really kill application %@?"), _(@"Yes"), _(@"Cancel"), nil,
    appName) == NSAlertDefaultReturn)
    {
      if (kill(pid, SIGKILL) < 0)
        {
          NSRunAlertPanel(_(@"Couldn't kill application"),
            _(@"Couldn't kill application %@, PID %i: %s"),
            nil, nil, nil, appName, pid, strerror(errno));
        }
    }
}

- (void) activateApplication: sender
{
 /*
  * This was previously implemented using a special WorkspaceCommKit
  * framework to contact and launch applications, but since it's not
  * included in Etoile, this functionality currently has to be disabled.
  * Ask Quentin on what mechanism we'll be using in the future.
  */
#if 0
  // find out from where we have been invoked
  if (sender == appTable)
    {
      row = [appTable selectedRow];
    }
  else
    {
      row = [menu indexOfItem: sender];
    }

  if (row >= 0)
    {
      NSString * appName = [[launchedApplications objectAtIndex: row]
        objectForKey: @"NSApplicationName"];
      id app;

      app = [[NSWorkspace sharedWorkspace] connectToApplication: appName
                                                         launch: NO];
      if (app != nil)
        {
          NS_DURING
            [app activateIgnoringOtherApps: YES];
          NS_HANDLER
            NSRunAlertPanel (_(@"Failed to activate application"),
              _(@"Exception occured while trying to activate "
                @"application %@: %@"), nil, nil, nil, appName,
              [localException reason]);
          NS_ENDHANDLER
        }
      else
        {
          NSRunAlertPanel(_(@"Failed to activate application"),
            _(@"Failed to connect to application %@ to activate it"),
            nil, nil, nil, appName);
        }
    }
#endif
}

- (int) numberOfRowsInTableView: (NSTableView *)aTableView
{
  return [launchedApplications count];
}

- (id) tableView: (NSTableView *)aTableView
objectValueForTableColumn: (NSTableColumn *)aTableColumn
             row: (int)rowIndex
{
  return [[launchedApplications objectAtIndex: rowIndex]
    objectForKey: @"NSApplicationName"];
}

@end
