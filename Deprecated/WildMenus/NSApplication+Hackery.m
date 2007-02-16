/*
   Copyright (C) 2004 Michael Hanni.

   Author: Michael Hanni <mhanni@yahoo.com>
   Date: 2004

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#include <Foundation/Foundation.h>

#include <AppKit/NSImage.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSWindow.h>

#include "GSHorizontalMenuView.h"
#include "NSApplication+Hackery.h"
#include "NSMenu+Hackery.h"

@implementation NSApplication (Hackery)
- (void) setApplicationIconImage: (NSImage*)anImage
{
  NSEnumerator  *iterator = [[self windows] objectEnumerator];
  NSWindow      *current;
  NSImage       *old_app_icon = _app_icon;

  RETAIN(old_app_icon);
  [_app_icon setName: nil];
  [anImage setName: @"NSApplicationIcon"];
  ASSIGN(_app_icon, anImage);

  // Update app icon on menubar.
  [_main_menu _organizeMenu];

  if (_app_icon_window != nil)
    {
      [[_app_icon_window contentView] setImage: anImage];
    }

  // Swap the old image for the new one wherever it's used
  while ((current = [iterator nextObject]) != nil)
    {
      if ([current miniwindowImage] == old_app_icon)
        [current setMiniwindowImage: anImage];
    }

  DESTROY(old_app_icon);
}


- (void) setMainMenu: (NSMenu*)aMenu
{
  if (_main_menu != nil && _main_menu != aMenu)
    {
      [_main_menu close];
      [[_main_menu window] setLevel: NSSubmenuWindowLevel];
    }

  ASSIGN(_main_menu, aMenu);

  [_main_menu setMenuRepresentation: [[GSHorizontalMenuView alloc] initWithFrame: NSZeroRect]];
  [[_main_menu menuRepresentation] setHorizontal: YES];
  [_main_menu _organizeMenu];

  // Set the title of the window.
  // This wont be displayed, but the window manager may need it.
  [[_main_menu window] setTitle: [[NSProcessInfo processInfo] processName]];
  [[_main_menu window] setLevel: NSMainMenuWindowLevel];
  [_main_menu setGeometry];
}
@end
