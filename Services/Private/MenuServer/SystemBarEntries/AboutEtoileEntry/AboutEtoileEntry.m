
#import "AboutEtoileEntry.h"

#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>

#import <AppKit/NSNibLoading.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSWindow.h>

@implementation AboutEtoileEntry

- (id <NSMenuItem>) menuItem
{
  NSMenuItem * menuItem;

  menuItem = [[[NSMenuItem alloc]
    initWithTitle: _(@"About Étoilé")
           action: @selector(activate)
    keyEquivalent: nil]
    autorelease];

  [menuItem setTarget: self];

  return menuItem;
}

- (NSString *) menuGroup
{
  return @"Etoile";
}

- (void) activate
{
  if (window == nil)
    {
      [NSBundle loadNibNamed: @"AboutEtoileEntry" owner: self];

      [window center];
    }

  [window makeKeyAndOrderFront: nil];
}

@end
