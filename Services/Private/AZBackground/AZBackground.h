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
  Atom X_NAME; /* property name */
}

+ (AZBackground *) background;

@end
