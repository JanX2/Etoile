#import <AppKit/AppKit.h>
#import <gtk/gtk.h>
#import <gtkmozembed.h>

@interface Controller: NSObject
{
  GMainLoop *gloop;
  GMainContext *gcontext;
}

@end

