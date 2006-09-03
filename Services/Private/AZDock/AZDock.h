#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSDisplayServer.h>
#import <X11/Xlib.h>

@interface AZDock: NSObject
{
  GSDisplayServer *server;
  Display *dpy;
  int screen;
  Window root_win;
  NSMutableArray *apps;
  NSMutableArray *lastClientList; /* Cache last client list */
}

+ (AZDock *) sharedDock;

@end

