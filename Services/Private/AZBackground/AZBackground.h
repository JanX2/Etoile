#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSDisplayServer.h>
#import <X11/Xlib.h>

@interface AZBackground: NSObject
{
  /* Accessories */
  GSDisplayServer *server;
  Display *dpy;
  int screen;
  Window root_win;
}

+ (AZBackground *) background;

@end
