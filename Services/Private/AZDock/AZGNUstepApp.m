#import "AZGNUstepApp.h"

@implementation AZGNUstepApp 

/** Private **/

/* Action from AZDockView */

#if 0
- (void) removeFromDockAction: (id) sender
{
  [super removeFromDockAction: sender];
  /* Am I dead ? */
  int k;
  NSArray *allApps = [[NSWorkspace sharedWorkspace] launchedApplications];
  NSMutableArray *allNames = AUTORELEASE([[NSMutableArray alloc] init]);
  for (k = 0; k < [allApps count]; k++) {
    [allNames addObject: [[(NSDictionary *)[allApps objectAtIndex: k] objectForKey: @"NSApplicationName"] stringByDeletingPathExtension]];
  }
  if ([allNames containsObject: [self applicationName]] == NO) {
    [[NSNotificationCenter defaultCenter]
        postNotificationName: AZApplicationDidTerminateNotification
        object: self];
  }
}
#endif

- (void) showAction: (id) sender
{
  NSString *path = [self command];
  BOOL success = [[NSWorkspace sharedWorkspace] launchApplication: path];
  if (success == NO) {
    /* Try regular execute */
    [NSTask launchedTaskWithLaunchPath: path arguments: nil];
  }
  [self setRunning: YES];
}

- (void) quitAction: (id) sender
{
  NSLog(@"quit %@", appName);
  /* Connect to application */
  id appProxy = [NSConnection rootProxyForConnectionWithRegisteredName: appName
	                                                          host: @""];
  if (appProxy) {
    NS_DURING
      [appProxy terminate: nil];
      [self setRunning: NO];
    NS_HANDLER
      /* Error occurs because application is terminated
       * and connection dies. */
    NS_ENDHANDLER
  }
}

/** End of Private **/

- (id) initWithApplicationName: (NSString *) ap
{
  self = [super init];

  ASSIGN(appName, [ap stringByDeletingPathExtension]);
  type = AZDockGNUstepApplication;

  /* Get command */
  ASSIGN(command, [appName stringByAppendingPathExtension: @"app"]);
  NSArray *array = NSStandardApplicationPaths();
  /* Make sure the command exists */
  BOOL isDir;
  NSFileManager *fm = [NSFileManager defaultManager];
  if ([fm fileExistsAtPath: command isDirectory: &isDir] == NO) {
    int i, count = [array count];
    BOOL found = NO;
    NSString *a;
    for (i = 0; i < count; i++) {
      a = [[array objectAtIndex: i] stringByAppendingPathComponent: command];
      if ([fm fileExistsAtPath: a isDirectory: &isDir] && (isDir == YES))
      {
        ASSIGN(command, a);
        found = YES;
        break;
      }
    }
    if (found == NO) {
      DESTROY(command);
    }
  }

  /* Try to get the icon */
  if (command) {
    ASSIGN(icon, [[NSWorkspace sharedWorkspace] iconForFile: command]);
  }
  if (!icon) {
    /* use default icon */
    ASSIGN(icon, [NSImage imageNamed: @"Unknown.tiff"]);
  }
  if (icon)
    [view setImage: icon];

  return self;
}

- (void) dealloc
{
  DESTROY(appName);
  [super dealloc];
}

- (NSString *) applicationName
{
  return appName;
}

@end
