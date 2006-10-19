#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSDisplayServer.h>
#import <X11/Xlib.h>

@class XWindow;
@class AZWorkspaceView;
@class BKBookmarkStore;

typedef enum _AZDockPosition {
  AZDockLeftPosition = 0,
  AZDockRightPosition = 1,
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
  BKBookmarkStore *store;

  /* Replace default gnustep icon window */
  XWindow *iconWindow;
  AZWorkspaceView *workspaceView;
  AZDockPosition position;

  Atom X_NET_CURRENT_DESKTOP;
  Atom X_NET_NUMBER_OF_DESKTOPS;
  Atom X_NET_DESKTOP_NAMES;
  Atom X_NET_CLIENT_LIST;
  Atom X_NET_WM_STATE_SKIP_PAGER;
  Atom X_NET_WM_STATE_SKIP_TASKBAR;
}

+ (AZDock *) sharedDock;

@end

