#import "AZGNUstepApp.h"
#import "AZDock.h"
#import <X11/Xutil.h>

#ifdef ETOILE
#import <WorkspaceCommKit/NSWorkspace+Communication.h>
#endif

@implementation AZGNUstepApp 

/** Private **/

/* Action from AZDockView */
- (void) showAction: (id) sender
{
  if ([self state] == AZDockAppLaunching) {
    /* Do nothing during launching */
    return;
  }

  NSString *path = [self command];
  BOOL success = [[NSWorkspace sharedWorkspace] launchApplication: path];
  if (path && (success == NO)) {
    /* Try regular execute */
    [NSTask launchedTaskWithLaunchPath: path arguments: nil];
  }
  if ([self state] == AZDockAppNotRunning) {
    [self setState: AZDockAppLaunching];
  }
}

- (void) quitAction: (id) sender
{
  NSLog(@"quit %@", appName);
  /* Connect to application */
#ifdef ETOILE // Use System's WorkspaceCommKit
  id appProxy = [[NSWorkspace sharedWorkspace] connectToApplication: appName launch: NO];
  NSLog(@"Use ETOILE");
#else
  id appProxy = [NSConnection rootProxyForConnectionWithRegisteredName: appName
	                                                          host: @""];
#endif
  if (appProxy) {
    NS_DURING
      [appProxy terminate: nil];
      [self setState: AZDockAppNotRunning];
    NS_HANDLER
      /* Error occurs because application is terminated
       * and connection dies. */
    NS_ENDHANDLER
  }
}

/** End of Private **/
- (id) init
{
  self = [super init];
  type = AZDockGNUstepApplication;
  group_leader = 0;
  icon_win = 0;
  return self;
}

- (id) initWithApplicationName: (NSString *) ap
{
  self = [self init];

  ASSIGN(appName, [ap stringByDeletingPathExtension]);

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

  [[view menu] setTitle: appName];

  return self;
}

- (void) dealloc
{
  DESTROY(appName);
  if (timer) {
    [timer invalidate];
  }
  DESTROY(timer);

  [super dealloc];
}

- (NSString *) applicationName
{
  return appName;
}

/* Override */

/* return YES if it has win already */
- (BOOL) acceptXWindow: (Window) win
{
  BOOL result = [super acceptXWindow: win];

  /* If it comes here, it must be our window. AZDock check it already */
  if (result == NO) {
    [xwindows addObject: [NSNumber numberWithUnsignedLong: win]];
    result = YES;
  }

  Display *dpy = (Display *)[GSCurrentServer() serverDevice];
  XWMHints *wmHints = XGetWMHints(dpy, win);
  if (wmHints->flags & WindowGroupHint) {
    if (group_leader == 0) {
      group_leader = wmHints->window_group;
      //NSLog(@"Got group leader %d", wmHints->window_group);
      XWMHints *rootHints = XGetWMHints(dpy, group_leader);
      if (rootHints->flags & IconWindowHint) {
        //NSLog(@"Got app icon %d", rootHints->icon_window);
        icon_win = rootHints->icon_window;
        /* Now, it becomes ugly. 
           We have to reparent app icon on top of our window. 
           Then we probably have to use XWindow for mouse actions.
           And remember to remove it when app terminates. */
        /* FIXME: This does not work at all,
           probably because GNUstep draw on top of the icon. */
        //XReparentWindow(dpy, icon_win, [window xwindow], 0, 0);
        /* FIXME: we move GNUstep's app icon out of sight
                  so that there is only one icon show. 
                  If we unmap it, some applications will complain. */
        //XUnmapWindow(dpy, icon_win);
        XMoveWindow(dpy, icon_win, -1000, -1000);
        /* FIXME: the third option is to move GNUstep's app icon to where
           the icon suppose be. But one problem is that we cannto control it.
           There is not menu item to keep the icon on the dock */
        /*[window orderOut: self];
         * and move GNUstep's icon to where it is supposed to be */
        /* FIXME: the fourth option is to copy the out-of-sight icon
           to our icon. It is doable. But we need a notification to know
           when to copy. And we need to block AZDockApp and AZDockView
           from drawing if that happens. */
#if 0
        {
	  GC gc = XCreateGC(dpy, icon_win, 0, 0);
	  if (gc < 0) {
            NSLog(@"XCreateGC failed");
          }
          XCopyArea(dpy, icon_win, [window xwindow], gc, 0, 0, 48, 48, 0, 0);
        }
#endif
      }
      XFree(rootHints);
    }
    if (group_leader != wmHints->window_group) {
      NSLog(@"Internal Error: this GNUstep window has different group leader than others");
    }
  }
  XFree(wmHints);

  return result;
}

/* return YES if it has win already and remove it */
- (BOOL) removeXWindow: (Window) win
{
  BOOL result = [super removeXWindow: win];
  if (result == YES) {
    //NSLog(@"%d removed %d", win, result);
    if ([xwindows count] == 0) {
      // NSLog(@"empty");
      /* There is a corner case. 
         A GNUstep application may terminate abnormally.
         We can only use NSConnection to check that. */
      if (timer) {
        [timer invalidate];  
      }
      DESTROY(timer);
      /* We give it a few seconds to terminate */
      ASSIGN(timer, [NSTimer scheduledTimerWithTimeInterval: 3
                                     target: [AZDock sharedDock]
                                   selector: @selector(checkAlive:)
                                   userInfo: self
                                    repeats: NO]);

    }
  }
  return result;
}

- (void) setState: (AZDockAppState) b
{
  [super setState: b];
  if (b == AZDockAppNotRunning) {
    /* GNUstep application terminate.
       Release group_leader and icon_win. */
    group_leader = 0;
    icon_win = 0;
    /* Remove timer */
    if (timer) {
      [timer invalidate];
    }
    DESTROY(timer);
  }
}

@end
