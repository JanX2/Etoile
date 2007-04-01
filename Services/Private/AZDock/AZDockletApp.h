#import "AZDockApp.h"
#import <X11/Xlib.h>

/* WindowMaker dock app */
@interface AZDockletApp: AZDockApp
{
  Display *dpy;
  Window rootWindow;
  Window mainWindow;
  Window iconWindow;
  NSRect frame; // frame for docklet window.

  NSString *wm_class;
  NSString *wm_instance;
}

- (id) initWithCommand: (NSString *) cmd
       instance: (NSString *) instance class: (NSString *) class;
- (id) initWithXWindow: (Window) win;

- (NSString *) wmClass;
- (NSString *) wmInstance;

@end
