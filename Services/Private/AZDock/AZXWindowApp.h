#import "AZDockApp.h"
#import <X11/Xlib.h>

/* X window application */
@interface AZXWindowApp: AZDockApp
{
  NSString *wm_class;
  NSString *wm_instance;
}

- (id) initWithCommand: (NSString *) cmd
       instance: (NSString *) instance class: (NSString *) class;
- (id) initWithXWindow: (Window) win;

/* Return NO is the win does not belong to this view */
- (BOOL) acceptXWindow: (Window) win;

/* Return YES if it has win and remove it successfully.
 * If win is the group window, all x windows in this application 
 * will be remove */
- (BOOL) removeXWindow: (Window) win;

/* Return number of XWindows */
- (unsigned int) numberOfXWindows;

- (NSString *) wmClass;
- (NSString *) wmInstance;

@end
