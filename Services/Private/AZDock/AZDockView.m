#include "AZDockView.h"
#include "AZDockApp.h"

NSString *AZUserDefaultDockPosition= @"DockPosition";
NSString *AZDockPositionDidChangeNotification = @"AZDockPositionDidChangeNotification";

@implementation AZDockView
/* Private */
- (void) resizeRunningIndicator
{
	int p = [[NSUserDefaults standardUserDefaults] 
                          integerForKey: AZUserDefaultDockPosition];
	NSSize size = [self bounds].size;
	int w = size.width/8;
	ASSIGN(bp, [NSBezierPath bezierPath]);
	switch (p)
	{
		case AZDockBottomPosition:
			[bp moveToPoint: NSMakePoint((size.width-w*1.44)/2, 0)];
			[bp lineToPoint: NSMakePoint(size.width/2, w)];
			[bp lineToPoint: NSMakePoint((size.width+w*1.44)/2, 0)];
			break;
		case AZDockRightPosition:
			[bp moveToPoint: NSMakePoint(size.width, (size.height-w*1.44)/2)];
			[bp lineToPoint: NSMakePoint(size.width-w, size.height/2)];
			[bp lineToPoint: NSMakePoint(size.width, (size.height+w*1.44)/2)];
			break;
		case AZDockLeftPosition:
			[bp moveToPoint: NSMakePoint(0, (size.height-w*1.44)/2)];
			[bp lineToPoint: NSMakePoint(w, size.height/2)];
			[bp lineToPoint: NSMakePoint(0, (size.height+w*1.44)/2)];
			break;
	}
	[bp closePath];
}

/* End of Private */

/* Notification */
- (void) dockPositionChanged: (NSNotification *) not
{
	[self resizeRunningIndicator];
}

- (void) setFrame: (NSRect) frame
{
	[super setFrame: frame];
	[self resizeRunningIndicator];
}

- (BOOL) acceptsFirstMouse: (NSEvent *) event
{
	return YES;
}

- (void) mouseUp: (NSEvent *) event
{
	/* Make sure the mouse is released inside the window */
	NSPoint p = [event locationInWindow];
	if (NSPointInRect(p, [self bounds]) == NO) 
	{
		return;
	}

	[delegate mouseUp: event];
}

- (void) drawRect: (NSRect) rect
{
	[super drawRect: rect];

	[self lockFocus];
#define USE_TRANSPARENCY 1
#if USE_TRANSPARENCY
	NSRectFillUsingOperation([self bounds], NSCompositeClear);
	NSColor *color = [NSColor colorWithCalibratedRed: 1.0
	                                          green: 1.0
	                                          blue: 1.0
	                                alpha: 0.5];
	[color set];
	NSRectFillUsingOperation([self bounds], NSCompositeSourceOver);
#endif
	if (image) 
	{
		NSSize size = [image size];
		NSRect frame = [self frame];
		NSRect source = NSMakeRect(0, 0, size.width, size.height);
		NSRect dest = NSMakeRect(NSWidth(frame)/8, NSHeight(frame)/8, NSWidth(frame)-NSWidth(frame)/4, NSHeight(frame)-NSHeight(frame)/4);
		source.size = [image size];
		[image drawInRect: dest
		         fromRect: source 
		        operation: NSCompositeSourceOver
		         fraction: 1];
	}
	if (state == AZDockAppRunning) 
	{
		[[NSColor darkGrayColor] set];
		[bp fill];
	}
	[self unlockFocus];
}

- (void) setImage: (NSImage *) i
{
	ASSIGN(image, i);
}

- (void) setDelegate: (id) d
{
  ASSIGN(delegate, d);

  int i, count = [contextualMenu numberOfItems];
  id <NSMenuItem> item;
  for (i = 0; i < count; i++) {
    item = [contextualMenu itemAtIndex: i];
    [item setTarget: delegate];
  }
}

- (id) delegate
{
  return delegate;
}

- (NSMenu *) contextualMenu
{
  return contextualMenu;
}

- (id) initWithFrame: (NSRect) frame
{
	self = [super initWithFrame: frame];

	contextualMenu = [[NSMenu alloc] init];
	[contextualMenu addItemWithTitle: _(@"Keep in dock")
	                          action: @selector(keepInDockAction:)
	                   keyEquivalent: nil];
	[contextualMenu addItemWithTitle: _(@"Show")
	                          action: @selector(showAction:)
	                   keyEquivalent: nil];
	[contextualMenu addItemWithTitle: _(@"Quit")
	                          action: @selector(quitAction:)
	                   keyEquivalent: nil];
	[self setMenu: contextualMenu];

	/* Update dock position */
	[self dockPositionChanged: nil];

	/* Listen to notification for dock position */
	[[NSNotificationCenter defaultCenter]
                   addObserver: self
                   selector: @selector(dockPositionChanged:)
                   name: AZDockPositionDidChangeNotification
                   object: nil];

	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	DESTROY(image);
	DESTROY(delegate);
	DESTROY(contextualMenu);
	DESTROY(bp);
	[super dealloc];
}

- (void) setState: (AZDockAppState) b
{
  state = b;

  int i, count = [[self menu] numberOfItems];
  id <NSMenuItem> item = nil;
  NSColor *color;
  BOOL enabled = YES;
  if (state == AZDockAppRunning) {
//    color = [NSColor redColor];
    color = [NSColor windowBackgroundColor];
    enabled = YES; /* enable all menu before launching */
  } else if (state == AZDockAppLaunching) {
    color = [NSColor yellowColor];
    enabled = NO; /* Disable all menu during launching */
  } else {
    color = [NSColor windowBackgroundColor];
    enabled = YES; /* enable all menu after launching */
  }

  [[self window] setBackgroundColor: color];
  for (i = 0; i < count; i++) {
    item = [[self menu] itemAtIndex: i];
    [item setEnabled: enabled]; // FIXME: not really work.
  }
  [[self menu] update];
}

- (AZDockAppState) state
{
  return state;
}


@end
