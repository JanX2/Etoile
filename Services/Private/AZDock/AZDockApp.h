#include <AppKit/AppKit.h>
#include <X11/Xlib.h>
#include <XWindowServerKit/XWindow.h>

@class AZDockView;

typedef enum _AZDockType {
  AZDockGNUstepApplication,
  AZDockXWindowApplication,
  AZDockWindowMakerDocklet,
  AZDockFile
} AZDockType;

/* Dock app can be a x window application, a gnustep application 
 * or a file on harddisk */
@interface AZDockApp: NSObject
{
  Window groupWindow; /* Keep a record of group leader, especially for GNUstep. */
  AZDockType type;
  NSMutableArray *xwindows;
  XWindow *window;
  AZDockView *view;
  NSImage *icon;
  NSString *wm_class;
  NSString *wm_instance;
}

- (id) initWithXWindow: (Window) win;

- (AZDockType) type;
- (Window) groupWindow;

/* Return NO is the win does not belong to this view */
- (BOOL) acceptXWindow: (Window) win;

/* Return YES if it has win and remove it successfully.
 * If win is the group window, all x windows in this application 
 * will be remove */
- (BOOL) removeXWindow: (Window) win;

/* Return number of XWindows */
- (unsigned int) numberOfXWindows;

/* return window for this application */
- (XWindow *) window;

@end
