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
#import <Foundation/NSDebug.h>

#import <AppKit/NSView.h>

#import "Controller.h"
#import "BundleExtensionLoader.h"
#import "MenuBarWindow.h"
#import "Controller.h"
#import "EtoileMenulet.h"

/* Informal protocol to test Menulet set up */
@interface NSObject (MenuletTest)
- (void) test;
@end


@implementation MenuletLoader

static MenuletLoader * shared = nil;

+ (MenuletLoader *) sharedLoader
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
  NSDebugLLog(@"MenuServer", @"Loading menulet bundles %@", bundles);

  e = [bundles objectEnumerator];
  while ((bundle = [e nextObject]))
    {
      id <EtoileMenulet> menulet;
      NSView * view;
      NSRect frame;

      menulet = [[bundle principalClass] new];
      if (menulet == nil)
        {
          NSWarnLog(@"Unable to instantiate principal class %@ in bundle %@", 
            [bundle principalClass], bundle);
          continue;
        }

      [array addObject: menulet];
      view = [menulet menuletView];
      NSDebugLLog(@"MenuServer", @"Retrieved menulet view %@", view);

      totalWidth += (2 + [view frame].size.width);

      /* The -test method below is useful when a menulet want to test whether
         it is properly set up or not. */
      if ([(id)menulet respondsToSelector: @selector(test)])
        [(id)menulet test];
    }

  ASSIGNCOPY(menulets, array);
}

- (int) width
{
  return totalWidth;
}

- (void) organizeMenulets
{
  NSRect windowFrame = [ServerMenuBarWindow frame];
  int offset = windowFrame.size.width;
  NSEnumerator *e = [menulets objectEnumerator];
  id <EtoileMenulet> menulet = nil;
  while ((menulet = [e nextObject]))
  {
    NSView *view = [menulet menuletView];
    NSRect frame = [view frame];
    offset -= (frame.size.width + 2);
    frame.origin.x = offset;
    frame.origin.y = windowFrame.size.height / 2 - frame.size.height / 2;
    [view setFrame: frame];

    NSDebugLLog(@"MenuServer", @"Inserting menulet view with the frame \
          %@", NSStringFromRect([view frame]));
    [[ServerMenuBarWindow contentView] addSubview: view];
  }
}

@end
