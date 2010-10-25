/*
    MenuBarView.m

    Implementation of the MenuBarView class for the EtoileMenuServer
    application.

    Copyright (C) 2005  Saso Kiselkov

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

#import <Foundation/Foundation.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSScreen.h>
#import <AppKit/NSWindow.h>
#import "MenuBarView.h"
#import "EtoileSystemBarEntry.h"
#import "BundleExtensionLoader.h"

@interface MenuBarView (Private)

- (void) loadSystemBarEntries;

@end

@implementation MenuBarView (Private)

/**
 * Loads system bar entries and stuffs them into the system bar menu. System
 * bar entries are objects which conform to the EtoileSystemBarEntry protocol.
 *
 * The system bar is the menu which is brought up when the user hits
 * the Etoile logo on the left edge of the menubar. The entries in
 * there are menu items provided by system bar entries.
 */
- (void) loadSystemBarEntries
{
  NSMutableDictionary * groups;
  NSArray * bundles;
  NSEnumerator * e;
  NSBundle * bundle;
  NSString * group;
  NSMutableArray * ungrouped;
  NSSortDescriptor * sortDesc;

  // load all the system bar entry menus
  bundles = [[BundleExtensionLoader shared]
    extensionsForBundleType: @"sysbarentry"
     principalClassProtocol: @protocol(EtoileSystemBarEntry)
         bundleSubdirectory: @"EtoileMenuServer"
                  inDomains: 0
       domainDetectionByKey: @"SystemBarEntries"];

  groups = [NSMutableDictionary dictionary];
  ungrouped = [NSMutableArray array];

  // now load all system bar entries and put them into the `groups'
  // dictionary where they are each placed in an array keyed to their
  // group name
  e = [bundles objectEnumerator];
  while ((bundle = [e nextObject]) != nil)
    {
      Class principalClass = [bundle principalClass];
      id <EtoileSystemBarEntry> entry = [principalClass new];

      if (entry != nil)
        {
          NSString * group = [entry menuGroup];

          if (group != nil)
            {
              NSMutableArray * groupArray = [groups objectForKey: group];

              if (groupArray == nil)
                {
                  groupArray = [NSMutableArray array];
                  [groups setObject: groupArray forKey: group];
                }

              [groupArray addObject: entry];
            }
          else
            {
              [ungrouped addObject: entry];
            }
        }
      else
        {
          NSLog(_(@"Failed to load system bar entry %@"), [bundle bundlePath]);
        }
    }

  sortDesc = [[[NSSortDescriptor alloc]
    initWithKey: @"menuItem.title"
      ascending: YES
       selector: @selector (caseInsensitiveCompare:)]
    autorelease];

  // now sort the groups, and start adding the menu items into the
  // system bar for the individual entries
  e = [[[groups allKeys]
    sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)]
    objectEnumerator];
  while ((group = [e nextObject]) != nil)
    {
      // also sort the entries within a group based on the title of
      // their menu item
      NSMutableArray * groupEntries = [groups objectForKey: group];
      NSEnumerator * ee;
      id <EtoileSystemBarEntry> entry;

      NSDebugLLog(@"MenuServer", @"Inserting items: %@ part of group %@", groupEntries, group);

      [groupEntries sortUsingDescriptors: [NSArray arrayWithObject: sortDesc]];
      ee = [groupEntries objectEnumerator];

      while ((entry = [ee nextObject]) != nil)
        {
          NSMenuItem *menuItem = (id)[entry menuItem];

          if (menuItem != nil)
            [systemMenu addItem: menuItem];
        }

      // insert a new separator if non nil items were just inserted
      if (![[[systemMenu itemArray] lastObject] isSeparatorItem])
      {
        [systemMenu addItem: [NSMenuItem separatorItem]];
      }
    }

  if ([ungrouped count] > 0)
    {
      id <EtoileSystemBarEntry> entry;

      NSDebugLLog(@"MenuServer", @"Inserting ungrouped items: %@", ungrouped);

      e = [ungrouped objectEnumerator];
      while ((entry = [e nextObject]) != nil)
        {
          NSMenuItem *menuItem = (id)[entry menuItem];

          if (menuItem != nil)
            [systemMenu addItem: menuItem];
        }

      // insert a new separator if non nil items were just inserted
      if (![[[systemMenu itemArray] lastObject] isSeparatorItem])
      {
        [systemMenu addItem: [NSMenuItem separatorItem]];
      }
    }
}

@end

@implementation MenuBarView

static NSImage * filler = nil,
               * leftEdge = nil,
               * rightEdge = nil,
               * etoileLogo = nil,
               * etoileLogoH = nil;

+ (void) initialize
{
  if (self == [MenuBarView class])
    {
      // load all menubar images

      ASSIGN(filler, [NSImage imageNamed: @"MenuBarFiller"]);
      ASSIGN(leftEdge, [NSImage imageNamed: @"MenuBarLeftEdge"]);
      ASSIGN(rightEdge, [NSImage imageNamed: @"MenuBarRightEdge"]);

      ASSIGN(etoileLogo, [NSImage imageNamed: @"EtoileLogo"]);
      ASSIGN(etoileLogoH, [NSImage imageNamed: @"EtoileLogoH"]);
    }
}

- (void) dealloc
{
  TEST_RELEASE(systemMenu);

  [super dealloc];
}

- initWithFrame: (NSRect) frame
{
  if ((self = [super initWithFrame: frame]) != nil)
    {
      NSWindow * systemMenuWindow;
      NSRect frame;

      // create the system bar menu (the menu shown when the user pushes
      // the Etoile logo on the menubar)
      systemMenu = [[NSMenu alloc] initWithTitle: 
#ifdef __clang__
		  @"Étoilé"
#else
		  @"\x00C9toil\x00E9"
#endif
		  ];

      [self loadSystemBarEntries];

      // last, add the Sleep, Log Out, Reboot, Shut down entry
      [systemMenu addItemWithTitle: _(@"Sleep")
                            action: @selector(sleep:)
                     keyEquivalent: nil];
      [systemMenu addItem: [NSMenuItem separatorItem]];
      [systemMenu addItemWithTitle: _(@"Log Out")
                            action: @selector(logOut:)
                     keyEquivalent: nil];
      [systemMenu addItemWithTitle: _(@"Reboot")
                            action: @selector(reboot:)
                     keyEquivalent: nil];
      [systemMenu addItemWithTitle: _(@"Shut Down")
                            action: @selector(shutDown:)
                     keyEquivalent: nil];
      [systemMenu sizeToFit];
    }

  return self;
}

- (void) drawRect: (NSRect) r
{
  float offset;
  NSSize size;
  NSPoint p;

  // draw the background filler tiles
  size = [filler size];
  for (offset = NSMinX(r); offset < NSMaxX(r); offset += size.width)
    {
      [filler compositeToPoint: NSMakePoint(offset, 0)
                     operation: NSCompositeCopy];
    }

  // now the edges
  size = [leftEdge size];
  if (NSMinX(r) <= size.width)
    {
      [leftEdge compositeToPoint: NSZeroPoint operation: NSCompositeCopy];
    }
  size = [rightEdge size];
  p = NSMakePoint(NSMaxX([self frame]) - size.width, 0);
  [rightEdge compositeToPoint: p operation: NSCompositeCopy];

  // and the Etoile logo
  if (systemLogoPushedIn)
    {
      [etoileLogoH compositeToPoint: NSZeroPoint
                          operation: NSCompositeSourceOver];
    }
  else
    {
      [etoileLogo compositeToPoint: NSZeroPoint
                         operation: NSCompositeSourceOver];
    }
}

- (BOOL) acceptsFirstMouse: (NSEvent *) ev
{
  return YES;
}

- (void) mouseDown: (NSEvent *) ev
{
  // invoke the system bar menu if the user hit the Etoile logo
  if ([ev locationInWindow].x < [etoileLogo size].width)
    {
      systemLogoPushedIn = YES;
      [self setNeedsDisplay: YES];

      // and now adjust the menubar's window's frame to appear in the
      // upper left corner just under the menubar
      NSWindow *systemMenuWindow = [systemMenu window];
      NSRect frame = [systemMenuWindow frame];
      NSRect menuBarFrame = [[self window] frame];

      frame.origin.x = menuBarFrame.origin.x;
      // NOTE: Useful in short menu bar mode where the menu bar width can be 
      // too small to display system menu without cutting it at its right.
      if (NSMaxX(frame) > NSMaxX(menuBarFrame))
      {
        /* Shift menu window to left back on screen */
        frame.origin.x = NSMaxX([[NSScreen mainScreen] frame]) -
                         frame.size.width;
      }

      frame.origin.y = menuBarFrame.origin.y - NSHeight(frame);
      [systemMenuWindow setFrameOrigin: frame.origin];

      [NSEvent startPeriodicEventsAfterDelay: 0.1 withPeriod: 0.01];
      [systemMenu display];
      [[systemMenu menuRepresentation] trackWithEvent: ev];
      [systemMenu close];
      [NSEvent stopPeriodicEvents];

      systemLogoPushedIn = NO;
      [self setNeedsDisplay: YES];
    }
}

- (NSSize) minimalSize
{
  NSSize size = [etoileLogo size];
  return size;
}

@end
