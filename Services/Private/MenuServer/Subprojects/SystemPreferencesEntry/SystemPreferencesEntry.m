/*
    SystemPreferencesEntry.m

    Implementation of the SystemPreferencesEntry class for the
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

#import "SystemPreferencesEntry.h"

#import <Foundation/NSString.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSBundle.h>

#import <AppKit/NSWorkspace.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSMenuItem.h>

@implementation SystemPreferencesEntry

- (id <NSMenuItem>) menuItem
{
  id <NSMenuItem> item;

  item = [[[NSMenuItem alloc]
    initWithTitle: _(@"System Preferences...")
           action: @selector (showPreferences)
    keyEquivalent: nil]
    autorelease];

  [item setTarget: self];

  return item;
}

- (NSString *) menuGroup
{
  return @"Etoile";
}

- (void) showPreferences
{
  NSString * prefsAppName = [[NSUserDefaults standardUserDefaults]
    objectForKey: @"GSSystemPreferencesApplication"];

  if (prefsAppName == nil)
    {
      prefsAppName = @"SystemPreferences";
    }

  if (![[NSWorkspace sharedWorkspace] launchApplication: prefsAppName])
    {
      NSRunAlertPanel(_(@"Failed to launch preferences"),
        _(@"Couldn't launch the %@ application. If this application\n"
          @"isn't your system preferences application, please set the proper\n"
          @"application's name in the user defaults under the key "
          @"\"GSSystemPreferencesApplication\"."),
        nil, nil, nil);
    }
}

@end
