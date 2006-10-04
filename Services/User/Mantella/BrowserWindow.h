#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSDisplayServer.h>
#import <gtkmozembed.h>
#import <XWindowServerKit/XWindow.h>

/* Run all queued NSEvent once.
 * It is better to run XFlush(dpy) before call this.
 * Otherwise, not all XEvent go into queue yet. */
@interface NSApplication (GMainLoop)
- (void) runOnce;
@end

@interface BrowserWindow: XWindow
{
  GtkWidget *mozembed;
  GtkWidget *gtk_window;
  Window gtkwin;

  int max_y, min_y;
  NSButton *back;
  NSButton *forward;
  NSButton *reload;
  NSButton *stop;
  NSButton *go;
  NSTextField *urlLocation;
}

- (void) setMaxYMargin: (int) height; // top margin between title and mozilla
- (void) setMinYMargin: (int) height; // bottom margin between title and mozilla

- (void) back: (id) sender;
- (void) forward: (id) sender;
- (void) reload: (id) sender;
- (void) stop: (id) sender;
- (void) go: (id) sender;
- (NSTextField *) urlLocation;

@end

