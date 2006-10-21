#include "AZDockApp.h"
#include "AZDockView.h"

NSString *const AZApplicationDidTerminateNotification = @"AZApplicationDidTerminateNotification";

@implementation AZDockApp 

/** Private **/

/* Action from AZDockView */
- (void) keepInDockAction: (id) sender
{
  NSLog(@"Keep in dock");
}

- (void) showAction: (id) sender
{
  NSLog(@"showAction: %@", sender);
}

- (void) quitAction: (id) sender
{
  NSLog(@"quitAction: %@", sender);
}

/** End of Private **/

- (void) mouseDown: (NSEvent *) event
{
  [self showAction: self];
}

- (id) init
{
  self = [super init];

  NSRect rect = NSMakeRect(0, 0, 64, 64);
  view = [[AZDockView alloc] initWithFrame: rect];
  [view setDelegate: self];
  window = [[XWindow alloc] initWithContentRect: rect
 	                              styleMask: NSBorderlessWindowMask
				        backing: NSBackingStoreRetained
				          defer: NO];
  [window setDesktop: ALL_DESKTOP];
  [window skipTaskbarAndPager];
  [window setContentView: view];

  return self;
}

- (void) dealloc
{
  DESTROY(command);
  DESTROY(view);
  DESTROY(icon);
  if (window) {
    [window close];
    DESTROY(window);
  }
  [self dealloc];
}

- (XWindow *) window
{
  return window;
}

- (AZDockType) type
{
  return type;
}

- (NSString *) command
{
  return command;
}

@end
