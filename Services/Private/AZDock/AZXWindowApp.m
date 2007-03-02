#import "AZXWindowApp.h"
#import <XWindowServerKit/XFunctions.h>
#import <X11/Xutil.h>

@implementation AZXWindowApp 

/** Private **/

/* Action from AZDockView */
- (void) showAction: (id) sender
{
  if (state == AZDockAppRunning) {
    /* Go through all windows and raise them */
    Display *dpy = (Display *)[GSCurrentServer() serverDevice];
    int i;
    Window w;
    for (i = 0; i < [xwindows count]; i++) {
      w = [[xwindows objectAtIndex: i] unsignedLongValue];
      unsigned long s = XWindowState(w);
      if (s == -1) {
      } else if (s == IconicState) {
        /* Iconified */
        XMapWindow(dpy, w);
      } else {
        XRaiseWindow(dpy, w);
      }
    }
    /* Focus on the last one */
    XSetInputFocus(dpy, w, RevertToNone, CurrentTime);
  } else if (state == AZDockAppLaunching) {
    /* Do nothing during launching */
  } else {
    /* Application is not running. Execute it */
    if (command) {
      [NSTask launchedTaskWithLaunchPath: command arguments: nil];
      [self setState: AZDockAppLaunching];
    }
  }
}

- (void) quitAction: (id) sender
{
  int i;
  for (i = [xwindows count]-1; i > -1; i--) {
    XWindowCloseWindow([[xwindows objectAtIndex: i] unsignedLongValue], NO);
  }
}

/* This command is used to launch application.
 * For GNUstep, it use NSWorkspace. Therefore, the name of application is
 * sufficient. For other xwindow applications, we need to find the 
 * absolute path to do so.
 */
- (void) updateCommand: (Window) w
{
  /* Get command */
  ASSIGN(command, XWindowCommandPath(w));
  if ((command == nil) || ([command length] == 0)) {
    /* WM_COMMAND is not used by many modern applications.
     * Try lowercase of wm_class */
    ASSIGN(command, [wm_class lowercaseString]);
  }
  if ([command isEqualToString: @"firefox-bin"]) {
    // firefox has a weird class
    ASSIGN(command, @"firefox");
  }
  /* Make sure the command exists */
  NSProcessInfo *pi = [NSProcessInfo processInfo];
  NSArray *array = [[[pi environment] objectForKey: @"PATH"] componentsSeparatedByString: @":"];
  BOOL isDir;
  NSFileManager *fm = [NSFileManager defaultManager];
  if ([fm fileExistsAtPath: command isDirectory: &isDir] == NO) {
    int i, count = [array count];
    BOOL found = NO;
    NSString *a;
    for (i = 0; i < count; i++) {
      a = [[array objectAtIndex: i] stringByAppendingPathComponent: command];
      if ([fm fileExistsAtPath: a isDirectory: &isDir] && (isDir == NO))
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
}

- (void) updateIcon: (Window) w
{
  /* Try to get the icon */
  if (icon == nil)
    ASSIGN(icon, XWindowIcon(w));

  if (icon == nil) {
    /* use default icon */
    ASSIGN(icon, [NSImage imageNamed: @"Unknown.tiff"]);
  }

  if (icon) {
    [view setImage: icon];
  }
}

/** End of Private **/
- (id) init
{
  self = [super init];
  xwindows = [[NSMutableArray alloc] init];
  type = AZDockXWindowApplication;
  return self;
}

- (id) initWithCommand: (NSString *) cmd
       instance: (NSString *) instance class: (NSString *) class;

{
  self = [self init];

  /* use default icon */
  ASSIGN(icon, [NSImage imageNamed: @"Unknown.tiff"]);
  ASSIGN(command, cmd);
  ASSIGN(wm_instance, instance);
  ASSIGN(wm_class, class);
  [[view menu] setTitle: wm_instance];

  return self;
}

- (id) initWithXWindow: (Window) w
{
  self = [self init];
  [xwindows addObject: [NSNumber numberWithUnsignedLong: w]];

  /* Get class and instance */
  if (XWindowClassHint(w, &wm_class, &wm_instance)) {
    RETAIN(wm_class);
    RETAIN(wm_instance);
  } 

  [self updateIcon: w];
  [self updateCommand: w];
  [[view menu] setTitle: wm_instance];

  return self;
}

- (BOOL) acceptXWindow: (Window) win
{
  int i;
  unsigned long w;
  NSString *_class, *_instance;
  for (i = 0; i < [xwindows count]; i++)
  {
    w = [[xwindows objectAtIndex: i] unsignedLongValue];
    if (w == win) 
      return YES;
  }
  if (XWindowClassHint(win, &_class, &_instance)) {
    if ([_class isEqualToString: wm_class] &&
	[_instance isEqualToString: wm_instance])
      {
        [xwindows addObject: [NSNumber numberWithUnsignedLong: win]];

	if ((command == nil) || ([command length] == 0)) {
	  [self updateCommand: win];
	}
	return YES;
      }
  }
  return NO;
}

- (BOOL) removeXWindow: (Window) win
{
  int i;
  unsigned long w;
  for (i = 0; i < [xwindows count]; i++)
  {
    w = [[xwindows objectAtIndex: i] unsignedLongValue];
    if (w == win) {
      [xwindows removeObjectAtIndex: i];
      if ([xwindows count] == 0) {
        [self setState: AZDockAppNotRunning];
        [[NSNotificationCenter defaultCenter] 
		postNotificationName: AZApplicationDidTerminateNotification
		object: self];
      }
      return YES;
    }
  }
  return NO;
}

- (void) dealloc
{
  DESTROY(xwindows);
  DESTROY(wm_class);
  DESTROY(wm_instance);
  [super dealloc];
}

/* Override */
- (void) setState: (AZDockAppState) s
{
  AZDockAppState old = [self state];
  [super setState: s];
  /* When xwindow go from Launching to Running, we update the icon. */
  if ((s != AZDockAppNotRunning) && (old != s) && [xwindows count])
  {
    DESTROY(icon);
    [self updateIcon: [[xwindows lastObject] unsignedLongValue]];
  }
}

/* Accessories */

- (unsigned int) numberOfXWindows
{
  return [xwindows count];
}

- (NSString *) wmClass
{
  return wm_class;
}

- (NSString *) wmInstance
{
  return wm_instance;
}

@end
