#include "AZDockView.h"

@implementation AZDockView

- (BOOL) acceptsFirstMouse: (NSEvent *) event
{
  return YES;
}

- (void) mouseDown: (NSEvent *) event
{
  [delegate mouseDown: event];
}

- (void) drawRect: (NSRect) rect
{
  [super drawRect: rect];
  if (image) {
    NSRect source = NSMakeRect(0, 0, 64, 64);
    NSRect dest = NSMakeRect(8, 8, 48, 48);
    source.size = [image size];
    [self lockFocus];
    [image drawInRect: dest
	    fromRect: source 
	    operation: NSCompositeSourceAtop
            fraction: 1];
    [self unlockFocus];
		
  }
}

- (void) setImage: (NSImage *) i
{
  ASSIGN(image, i);
}

- (void) setDelegate: (id) d
{
  ASSIGN(delegate, d);
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
  [self setMenu: contextualMenu];
  return self;
}

- (void) dealloc
{
  DESTROY(image);
  DESTROY(delegate);
  DESTROY(contextualMenu);
  [super dealloc];
}

@end
