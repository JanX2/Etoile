#include <AppKit/AppKit.h>

@interface AZDockView: NSView
{
  NSImage *image;
  id delegate;
}

- (void) setImage: (NSImage *) image;

- (void) setDelegate: (id) delegate;
- (id) delegate;

@end
