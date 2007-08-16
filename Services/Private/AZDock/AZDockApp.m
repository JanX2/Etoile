#include "AZDockApp.h"
#include "AZDockView.h"
#include "AZDock.h"

NSString *const AZApplicationDidTerminateNotification = @"AZApplicationDidTerminateNotification";

@implementation AZDockApp 

/** Private **/

/* Action from AZDockView */
- (void) keepInDockAction: (id) sender
{
	[self setKeptInDock: YES];
	int min = [[AZDock sharedDock] minimalCountToStayInDock];
	if ([self counter] <= min)
		[self setCounter: min+1];
}

- (void) removeFromDockAction: (id) sender
{
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

- (void) newAction: (id) sender
{
	NSLog(@"newAction: %@", sender);
}

- (void) quitAction: (id) sender
{
	NSLog(@"quitAction: %@", sender);
}

/** End of Private **/

- (void) mouseUp: (NSEvent *) event
{
  NSEventType eventType = [event type];
  unsigned int modifier = [event modifierFlags];
//  int clickCount = [event clickCount];
//NSLog(@"modifier %d, click %d", modifier, clickCount);
  if (eventType == NSLeftMouseUp)
  {
    if (modifier & NSCommandKeyMask)
      [self newAction: self]; 
    else
      [self showAction: self];
  }
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
	[window setAsSystemDock];
	[window setContentView: view];
	[window setBackgroundColor: [NSColor windowBackgroundColor]];
	[window setLevel: NSNormalWindowLevel+1];
	[window skipTaskbarAndPager]; // We need this because window level changed

	xwindows = [[NSMutableArray alloc] init];

	keepInDock = YES;
	[self setState: AZDockAppNotRunning];
	counter = 0;

	return self;
}

- (void) dealloc
{
	DESTROY(xwindows);
	DESTROY(command);
	DESTROY(view);
	DESTROY(icon);
	if (window) 
	{
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
#if 0 // NOT_USED
	id <NSMenuItem> item = nil;
	if (keepInDock == NO)
	{
		/* Change menu to keep in dock */
		item = [[view menu] itemWithTitle: _(@"Remove from dock")];
		if (item) 
		{
			[item setTitle: _(@"Keep in dock")];
			[item setAction: @selector(keepInDockAction:)];
		}
		else 
		{
			NSLog(@"Internal Error: cannot find menu item 'Remove from dock'");
		}
	} 
	else
	{
		/* Change menu to remove from dock */
		item = [[view menu] itemWithTitle: _(@"Keep in dock")];
		if (item) 
		{
			[item setTitle: _(@"Remove from dock")];
			[item setAction: @selector(removeFromDockAction:)];
		}
		else 
		{
			NSLog(@"Internal Error: cannot find menu item 'Keep in dock'");
		}
	}
#endif
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

- (int) counter
{
	return counter;
}

- (void) setCounter: (int) value
{
	counter = value;
}

- (void) increaseCounter
{
	counter++;
}

- (NSComparisonResult) compareCounter: (id) object
{
	if ([object isKindOfClass: [AZDockApp class]])
	{
		/* Bigger counter has less index in array */
		AZDockApp *other = (AZDockApp *) object;
		if ([self counter] > [other counter])
			return NSOrderedAscending;
		else if ([self counter] < [other counter])
			return NSOrderedDescending;
		else
			return NSOrderedSame;
	}
	return NSOrderedDescending;
}

@end
