#include <AppKit/AppKit.h>

@interface AZDockView: NSView
{
  NSImage *image;
  id delegate;
  NSMenu *contextualMenu;
}

- (void) setImage: (NSImage *) image;

- (void) setDelegate: (id) delegate;
- (id) delegate;

- (NSMenu *) contextualMenu;

@end
