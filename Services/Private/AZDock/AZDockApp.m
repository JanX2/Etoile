#include "AZDockApp.h"
#include "AZDockView.h"
#include "AZDock.h"

NSString *const AZApplicationDidTerminateNotification = @"AZApplicationDidTerminateNotification";

@implementation AZDockApp 

/** Private **/

/* Action from AZDockView */
- (void) keepInDockAction: (id) sender
{
//  NSLog(@"Keep in dock");
  [self setKeptInDock: YES];
}

- (void) removeFromDockAction: (id) sender
{
//  NSLog(@"remove from dock");
  [self setKeptInDock: NO];
  
  if ([self state] == AZDockAppNotRunning) 
  {
    [[AZDock sharedDock] removeDockApp: self];
    [[AZDock sharedDock] organizeApplications];
  }
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

- (NSImage *) icon
{
  return icon;
}

- (void) setIcon: (NSImage *) i
{
  ASSIGN(icon, i);
  [view setImage: icon];
}

- (void) setKeptInDock: (BOOL) b
{
  keepInDock = b;
  id <NSMenuItem> item = nil;
  if (keepInDock == NO)
  {
    /* Change menu to keep in dock */
    item = [[view menu] itemWithTitle: _(@"Remove from dock")];
    if (item) {
      [item setTitle: _(@"Keep in dock")];
      [item setAction: @selector(keepInDockAction:)];
    } else {
      NSLog(@"Internal Error: cannot find menu item 'Remove from dock'");
    }
  } 
  else
  {
    /* Change menu to remove from dock */
    item = [[view menu] itemWithTitle: _(@"Keep in dock")];
    if (item) {
      [item setTitle: _(@"Remove from dock")];
      [item setAction: @selector(removeFromDockAction:)];
    } else {
      NSLog(@"Internal Error: cannot find menu item 'Keep in dock'");
    }
  }
}

- (BOOL) isKeptInDock
{
  return keepInDock;
}

- (void) setState: (AZDockAppState) b
{
  state = b;
  int i, count = [[view menu] numberOfItems];
  id <NSMenuItem> item = nil;
  NSColor *color;
  BOOL enabled = YES;
  if (state == AZDockAppRunning) {
    color = [NSColor redColor];
    enabled = YES; /* enable all menu before launching */
  } else if (state == AZDockAppLaunching) {
    color = [NSColor yellowColor];
    enabled = NO; /* Disable all menu during launching */
  } else {
    color = [NSColor windowBackgroundColor];
    enabled = YES; /* enable all menu after launching */
  }

  [window setBackgroundColor: color];
  for (i = 0; i < count; i++) {
    item = [[view menu] itemAtIndex: i];
    [item setEnabled: enabled]; // FIXME: not really work.
  }
  [[view menu] update];
}

- (AZDockAppState) state
{
  return state;
}

@end
