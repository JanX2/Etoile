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

#include <AppKit/NSApplication.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSMenuView.h>
#include <AppKit/NSWindow.h>

#include "NSMenu+Hackery.h"

#import "MenuBarHeight.h"

@interface NSMenu (EtoilePrivate)
- (NSRect) _menuServerWindowFrame;
@end

/* EtoileMenuServer NSApplication method (see -_menuServerWindowFrame) */
@interface NSObject (EtoileMenuServerController)
- (NSRect) menuBarWindowFrame;
@end


@implementation NSMenu (HorizontalHackery)

#define SHIFT_DELTA 18.0

- (void) shiftOnScreen
{
  NSWindow *theWindow = _transient ? _bWindow : _aWindow;
  NSRect    frameRect = [theWindow frame];
  NSRect    screenRect = [[NSScreen mainScreen] frame];
  NSPoint   vector    = {0.0, 0.0};
  BOOL      moveIt    = NO;

  // If we are the main menu forget about moving.
  if ([self isEqual: [NSApp mainMenu]])
    return;

  // 1 - determine the amount we need to shift in the y direction.
  if (NSMinY (frameRect) < 0)
    {
      vector.y = MIN (SHIFT_DELTA, -NSMinY (frameRect));
      moveIt = YES;
    }
  else if (NSMaxY (frameRect) > NSMaxY (screenRect))
    {
      vector.y = -MIN (SHIFT_DELTA, NSMaxY (frameRect) - NSMaxY (screenRect));
      moveIt = YES;   
    }

  // 2 - determine the amount we need to shift in the x direction.
  if (NSMinX (frameRect) < 0)
    {
      vector.x = MIN (SHIFT_DELTA, -NSMinX (frameRect));
      moveIt = YES;
    }
  // Note the -3.  This is done so the menu, after shifting completely
  // has some spare room on the right hand side.  This is needed otherwise
  // the user can never access submenus of this menu.   
  else if (NSMaxX (frameRect) > NSMaxX (screenRect) - 3)
    {
      vector.x
        = -MIN (SHIFT_DELTA, NSMaxX (frameRect) - NSMaxX (screenRect) + 3);
      moveIt = YES;
    }
     
  // This has been hacked for horizontal menus, i.e. we only scroll the 
  // menu that is off the screen.
  if (moveIt)
    {
      NSPoint  masterLocation;
      NSPoint  destinationPoint;
     
      masterLocation = [[self window] frame].origin;
      destinationPoint.x = masterLocation.x + vector.x;
      destinationPoint.y = masterLocation.y + vector.y;

      [self nestedSetFrameOrigin: destinationPoint];
    }
}

- (void) _rightMouseDisplay: (NSEvent*)theEvent 
{
  // enable context menus to function
  if (_horizontal == NO && [(NSMenuView *) _view isHorizontal] == NO)
    {
      [self displayTransient];
      [_view mouseDown: theEvent];
      [self closeTransient];
    }
}

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

  NSDebugLog(@"WildMenus", @"MenuServer menu bar rect %@", 
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
      NSLog(@"WARNING: Failed to retrieve MenuServer application proxy");
    }

  return menuBarWindowFrame;
}

//-(void) _updateUserDefaults:(id)notification
//{
  
  /*
    NSLog(@"not going to update because we don't use this and might mess
    something up for other menu layouts since they seem to draw from the
    bottom up and our bottom is really close to the top");
  */
//}

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
      NSMenuItem *appItem = [self itemWithTitle: appName];
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
