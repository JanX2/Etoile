#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSDisplayServer.h>
#import <X11/Xlib.h>

@interface AZBackground: NSObject
{
  GSDisplayServer *server;
  Display *dpy;
  int screen;
  Window root_win;
  Window window;

  NSString *serviceItem;
  Atom X_PROPERTY_NAME; /* property name */
  Atom X_NET_ACTIVE_WINDOW;
  Atom X_NET_CLIENT_LIST_STACKING;
  Atom X_XROOTPMAP_ID;
}

+ (AZBackground *) background;

@end
