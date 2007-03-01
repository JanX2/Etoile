#include "AZDockApp.h"
#include "AZDockView.h"

NSString *const AZApplicationDidTerminateNotification = @"AZApplicationDidTerminateNotification";

@implementation AZDockApp 

/** Private **/

/* Action from AZDockView */
- (void) keepInDockAction: (id) sender
{
  NSLog(@"Keep in dock");
  [self setKeptInDock: YES];
}

- (void) removeFromDockAction: (id) sender
{
  NSLog(@"remove from dock");
  [self setKeptInDock: NO];
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
  [window setBackgroundColor: [NSColor windowBackgroundColor]];

  keepInDock = NO;
  state = AZDockAppNotRunning;

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
  [super dealloc];
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

- (void) setKeptInDock: (BOOL) b
{
  keepInDock = b;
}

- (BOOL) isKeptInDock
{
  return keepInDock;
}

- (void) setState: (AZDockAppState) b
{
  state = b;
  if (state == AZDockAppRunning) {
//    [window setBackgroundColor: [NSColor controlHighlightColor]];
    [window setBackgroundColor: [NSColor redColor]];
  } else if (state == AZDockAppLaunching) {
    [window setBackgroundColor: [NSColor yellowColor]];
  } else {
    [window setBackgroundColor: [NSColor windowBackgroundColor]];
  }
}

- (AZDockAppState) state
{
  return state;
}

@end
