#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSDisplayServer.h>
#import <X11/Xlib.h>

@class XWindow;

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
}

+ (AZDock *) sharedDock;

@end

