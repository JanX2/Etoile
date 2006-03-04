
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
         bundleSubdirectory: @"EtoileMenuServer"
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
