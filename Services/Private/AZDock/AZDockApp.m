#include "AZDockApp.h"
#include "AZDockView.h"
#include <XWindowServerKit/XFunctions.h>
#include <X11/Xutil.h>

@implementation AZDockApp 

/** Private **/

/* Action from AZDockView */
- (void) keepInDockAction: (id) sender
{
  NSLog(@"Keep in dock");
}

- (void) showAction: (id) sender
{
  switch(type) {
    case AZDockGNUstepApplication:
      {
        [[NSWorkspace sharedWorkspace] launchApplication: wm_instance];
	break;
      }
    case AZDockXWindowApplication:
      {
        /* Go through all windows and raise them */
        Display *dpy = (Display *)[GSCurrentServer() serverDevice];
        int i;
        Window w;
        for (i = 0; i < [xwindows count]; i++) {
          w = [[xwindows objectAtIndex: i] unsignedLongValue];
          unsigned long state = XWindowState(w);
          if (state == -1) {
          } else if (state == IconicState) {
            /* Iconified */
            XMapWindow(dpy, w);
          } else {
            XRaiseWindow(dpy, w);
	  }
        }
        /* Focus on the last one */
        XSetInputFocus(dpy, w, RevertToNone, CurrentTime);
      }
      break;
    default:
      break;
  }
}

- (void) quitAction: (id) sender
{
  switch(type) {
    case AZDockGNUstepApplication:
      {
        /* Connect to application */
        id appProxy = [NSConnection rootProxyForConnectionWithRegisteredName: wm_instance host: @""];
	if (appProxy) {
	  NS_DURING
	    [appProxy terminate: nil];
	  NS_HANDLER
	    /* Error occurs because application is terminated
	     * and connection dies. */
	  NS_ENDHANDLER
	}
	break;
      }
    case AZDockXWindowApplication:
      {
	int i;
	for (i = [xwindows count]-1; i > -1; i--) {
	  XWindowCloseWindow([[xwindows objectAtIndex: i] unsignedLongValue], NO);
	}
      }
    default:
      break;
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
  NSArray *array;
  if (type == AZDockGNUstepApplication) {
    ASSIGN(command, [wm_instance stringByAppendingPathExtension: @"app"]); 
    array = NSStandardApplicationPaths();
  } else {
    ASSIGN(command, XWindowCommandPath(w));
    if ((command == nil) || ([command length] == 0)) {
      /* WM_COMMAND is not used by many modern applications.
       * Try lowercase of wm_class */
      ASSIGN(command, [wm_class lowercaseString]);
    }
    /* Make sure the command exists */
    NSProcessInfo *pi = [NSProcessInfo processInfo];
    array = [[[pi environment] objectForKey: @"PATH"] componentsSeparatedByString: @":"];
  }
  BOOL isDir;
  NSFileManager *fm = [NSFileManager defaultManager];
  if ([fm fileExistsAtPath: command isDirectory: &isDir] == NO) {
    int i, count = [array count];
    BOOL found = NO;
    NSString *a;
    for (i = 0; i < count; i++) {
      a = [[array objectAtIndex: i] stringByAppendingPathComponent: command];
      if ([fm fileExistsAtPath: a isDirectory: &isDir])
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

/** End of Private **/

- (void) mouseDown: (NSEvent *) event
{
  [self showAction: self];
}

- (id) initWithXWindow: (Window) w
{
  self = [super init];
  xwindows = [[NSMutableArray alloc] init];
  [xwindows addObject: [NSNumber numberWithUnsignedLong: w]];

  NSRect rect = NSMakeRect(0, 0, 64, 64);
  view = [[AZDockView alloc] initWithFrame: rect];
  [view setDelegate: self];
  window = [[XWindow alloc] initWithContentRect: rect
                            styleMask: NSBorderlessWindowMask
			    backing: NSBackingStoreRetained
			    defer: NO];
  [window setDesktop: ALL_DESKTOP];
  [window skipTaskbarAndPager];
  [window setContentView: view];


  /* Get class and instance */
  if (XWindowClassHint(w, &wm_class, &wm_instance)) {
    RETAIN(wm_class);
    RETAIN(wm_instance);
  } 

  if ([wm_class isEqualToString: @"GNUstep"]) {
    type = AZDockGNUstepApplication;
    /* Get group leader if any */
    groupWindow = XWindowGroupWindow(w);
  } else {
    type = AZDockXWindowApplication;
    groupWindow = 0;
  }

  /* Try to get the icon */
  if (type == AZDockGNUstepApplication)
  {
	/* we try to get the application path */
	NSString* appPath = [[NSWorkspace sharedWorkspace]
		fullPathForApplication: wm_instance];
	if (appPath)
	{
		icon = [[NSWorkspace sharedWorkspace]
			iconForFile: appPath];
	}
  }
  if (!icon)
  {
  	icon = XWindowIcon(w);
  }

  if (!icon)
  {
	/* use default icon */
	icon = [NSImage imageNamed: @"Unknown.tiff"];
  }
  if (icon)
    [view setImage: icon];

  [self updateCommand: w];


  [window orderFront: self];

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

        if ([self type] == AZDockGNUstepApplication) {
	  groupWindow = XWindowGroupWindow(win);
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
      return YES;
    }
  }
  /* Note: sometimes group_window is the same as client window */
  if (win == groupWindow)
  {
    groupWindow = 0;
    [xwindows removeAllObjects];
  }
  return NO;
}

- (void) dealloc
{
  DESTROY(xwindows);
  DESTROY(wm_class);
  DESTROY(wm_instance);
  if (window) {
    [window close];
    DESTROY(window);
  }
  [self dealloc];
}

- (NSString *) description
{
  return [NSString stringWithFormat: @"%@", xwindows];
}

- (unsigned int) numberOfXWindows
{
  return [xwindows count];
}

- (XWindow *) window
{
  return window;
}

- (AZDockType) type
{
  return type;
}

- (Window) groupWindow
{
  return groupWindow;
}

- (NSString *) command
{
  return command;
}

@end
