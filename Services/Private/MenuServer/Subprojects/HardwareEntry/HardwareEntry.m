/*
    HardwareEntry.m

    Implementation of the HardwareEntry class for the
    EtoileMenuServer application.

    Copyright (C) 2006  Quentin Mathe

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

#import "HardwareEntry.h"

#import <Foundation/NSBundle.h>
#import <Foundation/NSString.h>
#import <Foundation/NSUserDefaults.h>

#import <AppKit/NSMenuItem.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSWorkspace.h>

@implementation HardwareEntry

- (id <NSMenuItem>) menuItem
{
  id <NSMenuItem> item;

  item = [[[NSMenuItem alloc]
    initWithTitle: _(@"Hardware")
           action: @selector (showHardwarePreferences)
    keyEquivalent: nil]
    autorelease];

  [item setTarget: self];

  return item;
}

- (NSString *) menuGroup
{
  return @"EtoilePreferences";
}

- (void) showHardwarePreferences
{
  NSString * prefsAppName = prefsAppName = @"Hardware";

  if (![[NSWorkspace sharedWorkspace] launchApplication: prefsAppName])
    {
      NSRunAlertPanel(_(@"Failed to launch Hardware preferences"),
        _(@"The %@ application is bundled with Etoile environment. If this \n"
          @"application isn't available anymore, you should reinstall it \n"
          @"otherwise the environment may not work properly."),
        nil, nil, nil, prefsAppName);
    }
}

@end
