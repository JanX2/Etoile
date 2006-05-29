/*
    ClockMenulet.m

    Implementation of the ClockMenulet class for the EtoileMenuServer
    application.

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

#import "WorkspaceSwitcher.h"
#import <AppKit/AppKit.h>
#import <XWindowServerKit/XScreen.h>

@implementation WorkspaceSwitcher

- (void) currentWorkspaceDidChangeAction: (NSNotification *) not
{
  int num = [[NSScreen mainScreen] currentWorkspace];
  [button selectItemAtIndex: num];
}

- (void) dealloc
{
  [[NSDistributedNotificationCenter defaultCenter] removeObserver: self];
  DESTROY(button);
  [super dealloc];
}

- init
{
  self = [super init];

  button = [[NSPopUpButton alloc] initWithFrame: NSMakeRect(0, 0, 100, 20)];

  NSScreen *screen = [NSScreen mainScreen];
  int i, num = [screen numberOfWorkspaces];
  NSArray *names = [screen namesOfWorkspaces];
  int n_count = (names ? [names count] : 0);
  for (i = 0; i < num; i++) {
    if (i < n_count)
      [button addItemWithTitle: [names objectAtIndex: i]];
    else
      [button addItemWithTitle: [NSString stringWithFormat: _(@"Workspace %d"), i]];
  }
  if (i == 0) {
    /* No workspace, probably because there is no window manager */
    [button addItemWithTitle: @"Workspace"];
  }
  [button selectItemAtIndex: 0];
  [button setTarget: self];
  [button setAction: @selector(workspaceAction:)];

  /* Listen to notification */
  [[NSDistributedNotificationCenter defaultCenter]
	  addObserver: self
	  selector: @selector(currentWorkspaceDidChangeAction:)
	  name: XCurrentWorkspaceDidChangeNotification
	  object: nil];

  return self;
}

- (void) workspaceAction: (id) sender
{
  NSScreen *screen = [NSScreen mainScreen];
  [screen setCurrentWorkspace: [button indexOfSelectedItem]];
}

- (NSView *) menuletView
{
  return button;
}

@end
