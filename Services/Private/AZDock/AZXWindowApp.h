#import "AZDockApp.h"
#import <X11/Xlib.h>

/* Dock app can be a x window application, a gnustep application 
 * or a file on harddisk */
@interface AZXWindowApp: AZDockApp
{
  NSMutableArray *xwindows;
  NSString *wm_class;
  NSString *wm_instance;
}

- (id) initWithXWindow: (Window) win;

/* Return NO is the win does not belong to this view */
- (BOOL) acceptXWindow: (Window) win;

/* Return YES if it has win and remove it successfully.
 * If win is the group window, all x windows in this application 
 * will be remove */
- (BOOL) removeXWindow: (Window) win;

/* Return number of XWindows */
- (unsigned int) numberOfXWindows;

@end
