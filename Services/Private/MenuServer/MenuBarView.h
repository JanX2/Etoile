
#import <AppKit/NSView.h>

@interface MenuBarView : NSView
{
  BOOL drawsCorners;
}

- (BOOL) drawsCorners;
- (void) setDrawsCorners: (BOOL) flag;

@end
