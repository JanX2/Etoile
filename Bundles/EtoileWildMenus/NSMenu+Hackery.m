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

#import <Foundation/Foundation.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSMenuView.h>
#import <AppKit/NSScreen.h>
#import <AppKit/NSWindow.h>
#import "NSMenu+Hackery.h"
#import "MenuBarHeight.h"

@interface NSMenu (EtoilePrivate)
- (NSRect) _menuServerWindowFrame;
@end

/* EtoileMenuServer NSApplication method (see -_menuServerWindowFrame) */
@interface NSObject (EtoileMenuServerController)
- (NSRect) menuBarWindowFrame;
@end

//TODO: Wrap these in a conditional so they are only used on GNUstep versions
//after Christmas day 2007 (Yes, Fred really was hacking GNUstep then)
#define _transient (_menu.transient)
#define _horizontal (_menu.horizontal)

@implementation NSMenu (HorizontalHackery)

- (void) _setGeometry
{
  [self setGeometry];
}

/* By mapping geometry by default on EtoileMenuServer menu bar, menus and menu
   bar should remained bound together if the menu bar moves. A common use case
   is when you run Etoile inside GNOME (or whatever) which already displays a
   a menu bar at the top. In GNOME case, menu bar is shifted down automatically
   and menus can follow it thanks to -_menuServerWindowFrame. */
- (void) setGeometry
{
  NSPoint origin;
  NSRect menuBarRect = [self _menuServerWindowFrame];

  NSDebugLLog(@"WildMenus", @"MenuServer menu bar rect %@",
    NSStringFromRect(menuBarRect));

  if (NSEqualRects(menuBarRect, NSZeroRect) == NO)
    {
      // TODO: Find why origin.y must be shifted down of 3 px.
      origin = NSMakePoint (1.5 * MenuBarHeight, menuBarRect.origin.y);
    }
  else /* Fall back on screen frame */
    {
      origin = NSMakePoint (1.5 * MenuBarHeight,
        [[NSScreen mainScreen] frame].size.height - [_aWindow frame].size.height);
    }

  [_aWindow setFrameOrigin: origin];
  [_bWindow setFrameOrigin: origin];
}

/* Requests menu bar window rect to EtoileMenuServer process. */
- (NSRect) _menuServerWindowFrame
{
  NSRect menuBarWindowFrame = NSZeroRect;
  id app = [NSConnection 
    rootProxyForConnectionWithRegisteredName: @"EtoileMenuServer" 
                                        host: nil];

  if (app != nil)
    {
      menuBarWindowFrame = [app menuBarWindowFrame];
    }
  else
    {
		static BOOL log = YES;
		if (log)
		{
			log = NO;
      		NSLog(@"WARNING: Failed to retrieve MenuServer application proxy");
		}
    }

  return menuBarWindowFrame;
}

- (void) _organizeMenu
{
  static NSString * appName = nil;
  NSMenu * appMenu;

  if (appName == nil)
    {
      ASSIGN(appName, [[[NSBundle mainBundle] infoDictionary]
        objectForKey: @"ApplicationName"]);
      if (appName == nil)
        {
          ASSIGN(appName, [[NSApp mainMenu] title]);
        }
    }

  appMenu = [[self itemWithTitle: appName] submenu];

  if (![self isEqual: [NSApp mainMenu]])
    return;

  [[NSNotificationCenter defaultCenter]
    addObserver: self
       selector: @selector(setGeometry)
           name: NSWindowDidMoveNotification
         object: [self window]];

  if (appMenu == nil)
    {
      int i, n;
      NSMutableArray *itemsToMove = [NSMutableArray new];
      NSMenuItem *appItem;

      NSUserDefaults *defs=[NSUserDefaults standardUserDefaults];

      float bar = MenuBarHeight - 4;

      appMenu = [NSMenu new];

      for (i = 0, n = [_items count]; i < n; i++)
        {
          NSMenuItem *anItem = [_items objectAtIndex: i];
          NSString *title = [anItem title];

          if (![anItem submenu])
	    {
	      [itemsToMove addObject: anItem];
	    }

          if ([title isEqual: _(@"Info")])
	    {
	      [itemsToMove addObject: anItem];
	    }
        }

      for (i = 0, n = [itemsToMove count]; i < n; i++)
        {
          [self removeItem: [itemsToMove objectAtIndex: i]];
          [appMenu addItem: [itemsToMove objectAtIndex: i]];
        }

      [self insertItemWithTitle: appName
		         action: NULL
	          keyEquivalent: @"" 
                        atIndex: 0];
      appItem = (NSMenuItem *)[self itemWithTitle: appName];

      [self setSubmenu: appMenu forItem: appItem];

      [itemsToMove release];
    }
  else
    {
      int i, n;
      NSMutableArray *itemsToMove = [NSMutableArray new];
      NSMenuItem *appItem = (id)[self itemWithTitle: appName];
      int index = [self indexOfItem: appItem];

      NSUserDefaults *defs=[NSUserDefaults standardUserDefaults];

      float bar = MenuBarHeight - 4;

      if (index != 0)
        {
	  RETAIN (appItem);
	  [self removeItemAtIndex: index];
	  [self insertItem: appItem atIndex: 0];
	  RELEASE (appItem);
        }

      for (i = 0, n = [_items count]; i < n; i++)
        {
          NSMenuItem *anItem = [_items objectAtIndex: i];
          NSString *title = [anItem title];

          if (![anItem submenu])
	    {
	      [itemsToMove addObject: anItem];
	    }

          if ([title isEqual: _(@"Info")])
	    {
	      [itemsToMove addObject: anItem];
	    }
        }

      for (i = 0, n = [itemsToMove count]; i < n; i++)
        {
          [self removeItem: [itemsToMove objectAtIndex: i]];
          [appMenu addItem: [itemsToMove objectAtIndex: i]];
        }

      [itemsToMove release];
    }
}

@end
