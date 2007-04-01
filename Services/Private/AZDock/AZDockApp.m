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

- (void) mouseUp: (NSEvent *) event
{
  [self showAction: self];
}

- (id) init
{
  self = [super init];

  NSRect rect = NSMakeRect(0, 0, DOCK_SIZE, DOCK_SIZE);
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
  [window setLevel: NSNormalWindowLevel+1];
  [window skipTaskbarAndPager]; // We need this because window level changed

  xwindows = [[NSMutableArray alloc] init];

  keepInDock = NO;
  [self setState: AZDockAppNotRunning];

  return self;
}

- (void) dealloc
{
  DESTROY(xwindows);
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
  [view setState: b];
}

- (AZDockAppState) state
{
  return [view state];
}

/* return YES if it has win already */
- (BOOL) acceptXWindow: (Window) win
{
  int i;
  unsigned long w;
  for (i = 0; i < [xwindows count]; i++) {
    w = [[xwindows objectAtIndex: i] unsignedLongValue];
    if (w == win) {
      return YES;
    }
  }
  return NO;
}

/* return YES if it has win already and remove it */
- (BOOL) removeXWindow: (Window) win
{
  int i;
  unsigned long w;
  for (i = 0; i < [xwindows count]; i++) {
    w = [[xwindows objectAtIndex: i] unsignedLongValue];
    if (w == win) {
      [xwindows removeObjectAtIndex: i];
      return YES;
    }
  }
  return NO;
}

@end
