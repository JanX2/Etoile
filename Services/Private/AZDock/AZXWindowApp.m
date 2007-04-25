#import "AZXWindowApp.h"
#import <XWindowServerKit/XFunctions.h>
#import <X11/Xutil.h>

@implementation AZXWindowApp 

/** Private **/

/* Action from AZDockView */
- (void) showAction: (id) sender
{
  if ([self state] == AZDockAppRunning) {
    /* Go through all windows and raise the ones on current desktop. */
    Display *dpy = (Display *)[GSCurrentServer() serverDevice];
    int i;
    Window w, last;
    unsigned int currentDesktop = [[NSScreen mainScreen] currentWorkspace];
    BOOL hasSome = NO;
    int desk = -1;
    for (i = 0; i < [xwindows count]; i++) 
    {
      /* Do we have windows on current desktop ? */
      w = [[xwindows objectAtIndex: i] unsignedLongValue];
      desk = XWindowDesktopOfWindow(w);
      if ((desk == currentDesktop) || (desk == 0xFFFFFFFF))
      {
	 hasSome = YES;
         break;
      }
    }

    if (hasSome == NO)
    {
      /* No window at current desktop */
      w = [[xwindows lastObject] unsignedLongValue];
      desk = XWindowDesktopOfWindow(w);
      [[NSScreen mainScreen] setCurrentWorkspace: desk];
    }
    
    currentDesktop = [[NSScreen mainScreen] currentWorkspace];
    for (i = 0; i < [xwindows count]; i++) {
      w = [[xwindows objectAtIndex: i] unsignedLongValue];
      desk = XWindowDesktopOfWindow(w);
      if ((desk == currentDesktop) || (desk == 0xFFFFFFFF))
      {
        last = w;
        unsigned long s = XWindowState(w);
        if (s == -1) {
        } else if (s == IconicState) {
          /* Iconified */
          XMapWindow(dpy, w);
        } else {
          //XRaiseWindow(dpy, w); // Not handled by OpenBox anymore
  	  XWindowSetActiveWindow(w, None);      
        }
      }
    }
    /* Focus on the last one */
    //XSetInputFocus(dpy, last, RevertToNone, CurrentTime);
    //XWindowSetActiveWindow(last, None);      
  } else if ([self state] == AZDockAppLaunching) {
    /* Do nothing during launching */
  } else {
    /* Application is not running. Execute it */
    if (command) {
      [NSTask launchedTaskWithLaunchPath: command arguments: nil];
      [self setState: AZDockAppLaunching];
    }
  }
}

- (void) newAction: (id) sender
{
  NSLog(@"newAction");
  /* We create new window on current desktop no matter what is the status. */
  if (command) {
    [NSTask launchedTaskWithLaunchPath: command arguments: nil];
    /* If it is not running (no running windows) */
    if ([self state] == AZDockAppNotRunning)
      [self setState: AZDockAppLaunching];
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
  NSString *_class, *_instance;
  BOOL result = [super acceptXWindow: win];
  if (result == YES) /* xwindow already exists */
    return YES;

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
  BOOL result = [super removeXWindow: win];
  if (result == YES) {
    if ([xwindows count] == 0) {
      [self setState: AZDockAppNotRunning];
      [[NSNotificationCenter defaultCenter] 
	        postNotificationName: AZApplicationDidTerminateNotification
		object: self];
    }
  }
  return result;
}

- (void) dealloc
{
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
