#import "AZDockApp.h"
#include <X11/Xlib.h>

@interface AZGNUstepApp: AZDockApp
{
  NSString *appName;
  Window group_leader;
  Window icon_win;
  NSTimer *timer;
}

- (id) initWithApplicationName: (NSString *) appName;
- (NSString *) applicationName; /* Without .app */
@end
