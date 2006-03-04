
#import <AppKit/NSApplication.h>
#import <Foundation/NSAutoreleasePool.h>

#import "Controller.h"

int main(int argc, const char * argv[])
{
  Controller * delegate;

  CREATE_AUTORELEASE_POOL (pool);

  delegate = [Controller new];
  [NSApplication sharedApplication];

  [NSApp setDelegate: delegate];

  DESTROY (pool);

  return NSApplicationMain(argc, argv);
}
