#import <AppKit/AppKit.h>
#import <XWindowServerKit/XWindow.h>
#import "AZDockView.h"

typedef enum _AZDockType {
	AZDockGNUstepApplication,
	AZDockXWindowApplication,
	AZDockWindowMakerDocklet,
	AZDockFile
} AZDockType;

/* Post when this dock application terminates and should be remove from dock.
 * Object is terminated application. Not used now. */
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
	int counter;
}

- (AZDockType) type;
- (NSString *) command;
- (XWindow *) window;
- (NSImage *) icon;
- (void) setIcon: (NSImage *) icon;

- (void) keepInDockAction: (id) sender;
- (void) removeFromDockAction: (id) sender;
/* Left-mouse click on dock. */
/* Shows the last window.
   It may change desktop if last window is not on current desktop. */
- (void) showAction: (id) sender;
/* NSCommandKeyMask & Left-mouse-click on dock */
/* It should create new window on current desktop. */
- (void) newAction: (id) sender;
- (void) quitAction: (id) sender;

- (void) setKeptInDock: (BOOL) b;
- (BOOL) isKeptInDock;

- (void) setState: (AZDockAppState) b;
- (AZDockAppState) state;

/* return YES if it has win already */
- (BOOL) acceptXWindow: (Window) win;
/* return YES if it has win already and remove it */
- (BOOL) removeXWindow: (Window) win;

- (int) counter;
- (void) setCounter: (int) value;
- (void) increaseCounter;
- (NSComparisonResult) compareCounter: (id) another;


@end
