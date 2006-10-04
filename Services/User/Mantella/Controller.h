#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSDisplayServer.h>
#import <X11/Xlib.h>
#import <gtk/gtk.h>
#import <gtkmozembed.h>

@interface Controller: NSObject
{
  GSDisplayServer *server;
  Display *dpy;
  GMainLoop *gloop;
  GMainContext *gcontext;
}

@end

