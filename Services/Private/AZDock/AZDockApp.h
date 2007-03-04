#import <AppKit/AppKit.h>
#import <XWindowServerKit/XWindow.h>
#import "AZDockView.h"

typedef enum _AZDockType {
  AZDockGNUstepApplication,
  AZDockXWindowApplication,
  AZDockWindowMakerDocklet,
  AZDockFile
} AZDockType;

typedef enum _AZDockAppState {
  AZDockAppNotRunning,
  AZDockAppLaunching,
  AZDockAppRunning,
} AZDockAppState;


/* Post when this dock application terminates and should be remove from dock.
 * Object is terminated application. */
extern NSString *const AZApplicationDidTerminateNotification;

@interface AZDockApp: NSObject
{
  AZDockType type;
  AZDockView *view;
  XWindow *window;
  NSImage *icon;
  NSMutableArray *xwindows;

  NSString *command; /* Command to launch this application */
  BOOL keepInDock;
  AZDockAppState state;
}

- (AZDockType) type;
- (NSString *) command;
- (XWindow *) window;
- (NSImage *) icon;
- (void) setIcon: (NSImage *) icon;

- (void) keepInDockAction: (id) sender;
- (void) removeFromDockAction: (id) sender;
- (void) showAction: (id) sender;
- (void) quitAction: (id) sender;

- (void) setKeptInDock: (BOOL) b;
- (BOOL) isKeptInDock;

- (void) setState: (AZDockAppState) b;
- (AZDockAppState) state;

/* return YES if it has win already */
- (BOOL) acceptXWindow: (Window) win;
/* return YES if it has win already and remove it */
- (BOOL) removeXWindow: (Window) win;

@end
