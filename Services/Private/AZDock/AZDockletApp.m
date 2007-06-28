#import "AZDockletApp.h"
#import "AZDock.h"
#import <XWindowServerKit/XFunctions.h>
#import <X11/Xutil.h>

@implementation AZDockletApp 

/** Private **/

/* Action from AZDockView */
- (void) showAction: (id) sender
{
  if ([self state] == AZDockAppRunning) {
    /* Docklet does not show */
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

- (void) quitAction: (id) sender
{
  if ([self isKeptInDock] == YES)
  {
    /* If docklet should stay in dock, it has to keep running.
       Therefore, we do not let users to quit it */
    return;
  }
  [[AZDock sharedDock] removeDockApp: self];
  [[AZDock sharedDock] organizeApplications];

  XUnmapWindow(dpy, iconWindow);
  XWindowCloseWindow(iconWindow, YES);

#if 0 // Seems not necessary and cause X window complaining
  if (iconWindow != mainWindow)
  {
    XUnmapWindow(dpy, mainWindow);
    XWindowCloseWindow(mainWindow, YES);
  }
#endif
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

#if 0
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
#endif

/** End of Private **/
- (id) init
{
  self = [super init];

  type = AZDockWindowMakerDocklet;
  dpy = (Display *)[GSCurrentServer() serverDevice];
  rootWindow = RootWindow(dpy, [[NSScreen mainScreen] screenNumber]);
  mainWindow = 0;
  iconWindow = 0;

  return self;
}

- (id) initWithCommand: (NSString *) cmd
       instance: (NSString *) instance class: (NSString *) class
{
  self = [self init];

  /* use default icon */
#if 0
  ASSIGN(icon, [NSImage imageNamed: @"Unknown.tiff"]);
#endif
  ASSIGN(command, cmd);
  ASSIGN(wm_instance, instance);
  ASSIGN(wm_class, class);
  [[view menu] setTitle: wm_instance];
  [view setToolTip: wm_instance];

#if 0 
  /* We do not start here because AZDock may not start completely.
     In that case, we cannot reparent docklet window */
  /* We start docklet automatically */
  if (command) 
  {
    NSLog(@"Docklet start at %@", command);
    [NSTask launchedTaskWithLaunchPath: command arguments: nil];
    [self setState: AZDockAppLaunching];
  }
#endif

  return self;
}

- (id) initWithXWindow: (Window) w
{
  self = [self init];

  /* We must get class and instance before accepting it
     because we depends on wm_class and wm_instance to decide 
     whether we can accept it. */
  if (XWindowClassHint(w, &wm_class, &wm_instance)) {
    RETAIN(wm_class);
    RETAIN(wm_instance);
  } 

  [self acceptXWindow: w];

#if 0
  [self updateIcon: w];
#endif
  [self updateCommand: w];
  [[view menu] setTitle: wm_instance];
  [view setToolTip: wm_instance];
  return self;
}

- (BOOL) acceptXWindow: (Window) win
{
  NSString *_class, *_instance;
  XWMHints *wmhints;
  XWindowAttributes attrib;
  if (XWindowClassHint(win, &_class, &_instance)) 
  {
    if ([_class isEqualToString: wm_class] &&
	[_instance isEqualToString: wm_instance])
    {
      if (mainWindow)
      {
	/* It is our window, but we already have one. Do nothing.
	   return YES so that it will not be taken by others. */
	return YES;
      }
      mainWindow = win;

      /* Let's attach window to ours */
      iconWindow = win;
      wmhints = XGetWMHints(dpy, win);
      if (wmhints && (wmhints->flags & IconWindowHint))
      {
        iconWindow = wmhints->icon_window;
      }
      XFree(wmhints);
      wmhints = NULL;

      if (XGetWindowAttributes(dpy, iconWindow, &attrib))
      {
        frame.size.width = attrib.width;
        frame.size.height = attrib.height;
      }
      else
      {
        frame.size.width = DOCK_SIZE;
        frame.size.height = DOCK_SIZE;
      }
      frame.origin.x = (DOCK_SIZE-NSWidth(frame))/2;
      frame.origin.y = (DOCK_SIZE-NSHeight(frame))/2;

      XReparentWindow(dpy, iconWindow, [window xwindow], 
                      NSMinX(frame), NSMinY(frame));
      XMapWindow(dpy, iconWindow);
      XSync(dpy, False);

      if ((command == nil) || ([command length] == 0)) 
      {
	[self updateCommand: win];
      }
      return YES;
    }
  }
  return NO;
}

- (BOOL) removeXWindow: (Window) win
{
/* Docklet window cannot be removed.
   Should we return YES if it is our window. */
#if 0
  if ((win == mainWindow) || (win == iconWindow))
  {
    return YES;
  }
#endif
  return NO;
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
//  AZDockAppState old = [self state];
  [super setState: s];
#if 0
  /* When xwindow go from Launching to Running, we update the icon. */
  if ((s != AZDockAppNotRunning) && (old != s) && [xwindows count])
  {
    DESTROY(icon);
    [self updateIcon: [[xwindows lastObject] unsignedLongValue]];
  }
#endif
}

/* Accessories */
- (NSString *) wmClass
{
  return wm_class;
}

- (NSString *) wmInstance
{
  return wm_instance;
}

@end
