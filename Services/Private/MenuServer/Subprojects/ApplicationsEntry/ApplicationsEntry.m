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
#import <Foundation/NSInvocation.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSString.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSValue.h>

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

#import "CheckProcessExists.h"

//#import <WorkspaceCommKit/WorkspaceCommKit.h>

@implementation ApplicationsEntry

- (void) dealloc
{
  [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver: self];

  TEST_RELEASE (launchedApplications);
  TEST_RELEASE (sortedAppNames);

  TEST_RELEASE (menuItem);
  TEST_RELEASE (menu);

  [autocheckTimer invalidate];
  TEST_RELEASE (autocheckTimer);

  [super dealloc];
}

- init
{
  if ((self = [super init]) != nil)
    {
      NSNotificationCenter * nc = [[NSWorkspace sharedWorkspace]
        notificationCenter];
      NSInvocation * inv;

      launchedApplications = [NSMutableArray new];
      sortedAppNames = [NSMutableArray new];

      [nc addObserver: self
             selector: @selector(noteAppLaunched:)
                 name: NSWorkspaceDidLaunchApplicationNotification
               object: nil];
      [nc addObserver: self
             selector: @selector(noteAppTerminated:)
                 name: NSWorkspaceDidTerminateApplicationNotification
               object: nil];

      inv = [NSInvocation invocationWithMethodSignature: [self
        methodSignatureForSelector: @selector (checkRunningApps)]];
      [inv setTarget: self];
      [inv setSelector: @selector (checkRunningApps)];
      
      ASSIGN (autocheckTimer, [NSTimer scheduledTimerWithTimeInterval: 1.0
                                                           invocation: inv
                                                              repeats: YES]);
    }

  return self;
}

- (id <NSMenuItem>) menuItem
{
  NSMenuItem * item;
  NSEnumerator * e;
  NSDictionary * appInfo;

  if (menuItem != nil)
    {
      return menuItem;
    }

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

  e = [[[NSWorkspace sharedWorkspace] launchedApplications] objectEnumerator];
  while ((appInfo = [e nextObject]) != nil)
    {
      [self noteAppLaunched: [NSNotification
        notificationWithName: NSWorkspaceDidLaunchApplicationNotification
                      object: self
                    userInfo: appInfo]];
    }
//  [self noteAppListChanged: nil];

  return menuItem;
}

- (void) noteAppLaunched: (NSNotification *) notif
{
  NSWorkspace *ws = [NSWorkspace sharedWorkspace];
  NSDictionary * appInfo = [notif userInfo];
  NSString * appName = [appInfo objectForKey: @"NSApplicationName"];
  NSString * appPath = [appInfo objectForKey: @"NSApplicationPath"];
  NSImage * icon;
  NS_DURING
    icon = [[[ws iconForFile: appPath] copy] autorelease];
  NS_HANDLER
    icon = nil;
  NS_ENDHANDLER
  NSNumber * pid = [appInfo objectForKey: @"NSApplicationProcessIdentifier"];
  NSMenuItem * appMenuItem;
  int index;
  
  // don't accept duplicate entries
  if ([[launchedApplications valueForKey: @"NSApplicationProcessIdentifier"]
    indexOfObject: pid] != NSNotFound)
    {
      return;
    }

  [icon setScalesWhenResized: YES];
  [icon setSize: NSMakeSize(18, 18)];

  appMenuItem = [[[NSMenuItem alloc]
    initWithTitle: appName
           action: @selector(activateApplication:)
    keyEquivalent: nil]
    autorelease];
  [appMenuItem setTarget: self];
  [appMenuItem setImage: icon];

  [sortedAppNames addObject: appName];
  [sortedAppNames sortUsingSelector: @selector (caseInsensitiveCompare:)];
  index = [sortedAppNames indexOfObject: appName];

  [launchedApplications insertObject: [notif userInfo] atIndex: index];

  [menu insertItem: appMenuItem atIndex: index];
  [menu sizeToFit];

  if (window != nil)
    {
      // refresh the interface if necessary

      [appTable reloadData];
      [self showApplication: self];
    }
}

- (void) noteAppTerminated: (NSNotification *) notif
{
  NSDictionary * appInfo = [notif userInfo];
  int index = [launchedApplications indexOfObject: appInfo],
      index2 = [sortedAppNames indexOfObject: [appInfo objectForKey:
        @"NSApplicationName"]];

  if (index != NSNotFound)
    {
      [launchedApplications removeObjectAtIndex: index];
      [sortedAppNames removeObjectAtIndex: index2];
      [menu removeItemAtIndex: index2];
    }

  if (window != nil)
    {
      // refresh the interface if necessary

      [appTable reloadData];
      [self showApplication: self];
    }
}

- (void) checkRunningApps
{
  int i, n;
  
  for (i = 0, n = [launchedApplications count]; i < n; i++)
    {
      NSDictionary * appInfo = [launchedApplications objectAtIndex: i];
      int pid = [[appInfo objectForKey: @"NSApplicationProcessIdentifier"]
        intValue];
      
      if (!CheckProcessExists (pid))
        {
          [self noteAppTerminated: [NSNotification
            notificationWithName: NSWorkspaceDidTerminateApplicationNotification
                          object: self
                        userInfo: appInfo]];
          i--;
          n--;
        }
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


      NS_DURING
        [appIcon setImage: [[NSWorkspace sharedWorkspace]
          iconForFile: appPath]];
      NS_HANDLER
      NS_ENDHANDLER
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
  return [sortedAppNames objectAtIndex: rowIndex];
}

@end
