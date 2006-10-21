#import "AZDockApp.h"

@interface AZGNUstepApp: AZDockApp
{
  NSString *appName;
}

- (id) initWithApplicationName: (NSString *) appName;
- (NSString *) applicationName; /* Without .app */
@end
