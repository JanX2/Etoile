#include <AppKit/AppKit.h>
#include <MultimediaKit/MultimediaKit.h>

@interface MixerController: NSObject
{
}
@end

@implementation MixerController

- (id) init
{
  self = [super init];
  NSRect rect = NSMakeRect(0, 0, 100, 100);
  MixerView *view = [[MixerView alloc] init];
  rect.size = [view sizeToFit];
  
  NSWindow *window = [[NSWindow alloc] initWithContentRect: rect
                                       styleMask: (NSTitledWindowMask |
                                                 NSClosableWindowMask |
                                           NSMiniaturizableWindowMask)
                                         backing: NSBackingStoreRetained
                                           defer: NO];
  [[window contentView] addSubview: view];
  [window setTitle: @"Volumn Control"];
  [window setDelegate: self];
  [window makeKeyAndOrderFront: self];

  return self;
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (id)sender
{
  return YES;
}

@end

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(x);

  [NSApplication sharedApplication];
  [NSApp setDelegate: AUTORELEASE([[MixerController alloc] init])];
  [NSApp run];

  DESTROY(x);
  return 0;
}

