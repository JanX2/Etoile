#import "AZWorkspaceView.h"
#import <XWindowServerKit/XScreen.h>

@implementation AZWorkspaceView

- (void) workspaceDidChanged: (NSNotification *) not
{
  NSLog(@"%@", not);
}

- (id) initWithFrame: (NSRect) rect
{
  self = [super initWithFrame: rect];
  ASSIGN(GNUstepIcon, [NSImage imageNamed: @"GNUstep.tiff"]);

  [[NSDistributedNotificationCenter defaultCenter] 
	  addObserver: self
	  selector: @selector(workspaceDidChanged:)
	  name: XCurrentWorkspaceDidChangeNotification
	  object: nil];

  return self;
}

- (void) drawRect: (NSRect) rect
{
  [super drawRect: rect];
  if (GNUstepIcon) {
    NSRect source = NSMakeRect(0, 0, 64, 64);
    NSRect dest = NSMakeRect(8, 8, 48, 48);
    source.size = [GNUstepIcon size];
    [self lockFocus];
    [GNUstepIcon drawInRect: dest
	     fromRect: source
	    operation: NSCompositeSourceAtop
	     fraction: 1];
    [self unlockFocus];
  }
}

- (void) dealloc
{
  DESTROY(GNUstepIcon);
  [super dealloc];
}

@end
