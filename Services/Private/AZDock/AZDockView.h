#include <AppKit/AppKit.h>

typedef enum _AZDockAppState {
  AZDockAppNotRunning,
  AZDockAppLaunching,
  AZDockAppRunning,
} AZDockAppState;

typedef enum _AZDockPosition {
  AZDockLeftPosition = 0,
  AZDockRightPosition = 1,
  AZDockBottomPosition = 2
} AZDockPosition;

extern NSString *AZUserDefaultDockPosition;
extern NSString *AZDockPositionDidChangeNotification;

@interface AZDockView: NSView
{
  NSImage *image;
  id delegate;
  NSMenu *contextualMenu;
  AZDockAppState state;
  NSBezierPath *bp;
}

- (void) setImage: (NSImage *) image;
- (void) setState: (AZDockAppState) state;
- (AZDockAppState) state;

- (void) setDelegate: (id) delegate;
- (id) delegate;

- (NSMenu *) contextualMenu;

@end
