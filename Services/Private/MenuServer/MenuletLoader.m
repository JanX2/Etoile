/*
    MenuletLoader.m

    Implementation of the MenuletLoader class for the EtoileMenuServer
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

#import "MenuletLoader.h"

#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>

#import <AppKit/NSView.h>

#import "Controller.h"
#import "BundleExtensionLoader.h"
#import "MenuBarWindow.h"
#import "Controller.h"
#import "EtoileMenulet.h"

@implementation MenuletLoader

static MenuletLoader * shared = nil;

+ shared
{
  if (shared == nil)
    {
      shared = [self new];
    }

  return shared;
}

- (void) dealloc
{
  TEST_RELEASE(menulets);

  [super dealloc];
}

- (void) loadMenulets
{
  float offset;
  NSRect windowFrame = [ServerMenuBarWindow frame];
  NSArray * bundles = [[BundleExtensionLoader shared]
    extensionsForBundleType: @"menulet"
     principalClassProtocol: @protocol(EtoileMenulet)
         bundleSubdirectory: nil /* @"EtoileMenuServer" */
                  inDomains: 0
       domainDetectionByKey: @"MenuMenulets"];
  NSEnumerator * e;
  NSBundle * bundle;
  NSMutableArray * array;

  array = [NSMutableArray arrayWithCapacity: [bundles count]];
  e = [bundles objectEnumerator];
  for (offset = windowFrame.size.width; (bundle = [e nextObject]) != nil;)
    {
      id <EtoileMenulet> menulet;
      NSView * view;
      NSRect frame;

      menulet = [[bundle principalClass] new];
      if (menulet == nil)
        {
          continue;
        }

      [array addObject: menulet];
      view = [menulet menuletView];
      frame = [view frame];

      offset -= (frame.size.width + 2);
      frame.origin.x = offset;
      frame.origin.y = windowFrame.size.height / 2 - frame.size.height / 2;
      [view setFrame: frame];

      [[ServerMenuBarWindow contentView] addSubview: view];
    }

  ASSIGNCOPY(menulets, array);
}

@end
