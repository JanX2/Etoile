#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSDisplayServer.h>
#import <X11/Xlib.h>

@class XWindow;

typedef enum _AZDockPosition {
  AZDockRightPosition = 0,
  AZDockLeftPosition = 1,
  AZDockBottomPosition = 2
} AZDockPosition;

@interface AZDock: NSObject
{
  GSDisplayServer *server;
  Display *dpy;
  int screen;
  Window root_win;
  NSMutableArray *apps;
  NSMutableArray *lastClientList; /* Cache last client list */

  /* Replace default gnustep icon window */
  XWindow *iconWindow;
  AZDockPosition position;
}

+ (AZDock *) sharedDock;

@end

