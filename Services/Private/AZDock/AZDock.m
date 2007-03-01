#import "AZDock.h"
#import "AZXWindowApp.h"
#import "AZGNUstepApp.h"
#import "AZWorkspaceView.h"
#import <X11/Xatom.h>
#import <X11/Xutil.h>
#import <XWindowServerKit/XFunctions.h>
#import <BookmarkKit/BookmarkKit.h>

static AZDock *sharedInstance;

@interface BKBookmark (AZDockSorting)
@end

@implementation BKBookmark (AZDockSorting)
- (NSComparisonResult) isLaterThan: (BKBookmark *) other
{
  NSDate *thisDate = [self lastVisitedDate];
  NSDate *thatDate = [other lastVisitedDate];
  if ([thisDate timeIntervalSinceDate: thatDate] > 0)
    return NSOrderedAscending;
  else if ([thisDate timeIntervalSinceDate: thatDate] < 0)
    return NSOrderedDescending;
  else
    return NSOrderedSame;
}	
@end

@implementation AZDock

/** Private **/
- (void) addGNUstepAppNamed: (NSString *) name
{
  if ([blacklist containsObject: name])
    return;

  AZGNUstepApp *app = [[AZGNUstepApp alloc] initWithApplicationName: name];
  [app setRunning: YES];
  [apps addObject: app];
  [self addBookmark: app];
  [[app window] orderFront: self];
  DESTROY(app);
  /* Do not organize applications here 
     because it will be called multiple times from other method. */
}

- (void) removeGNUstepAppNamed: (NSString *) name
{
  AZGNUstepApp *app = nil;
  int i, count = [apps count];
  for (i = 0; i < count; i++) 
  {
    app = [apps objectAtIndex: i];
    if ([app type] == AZDockGNUstepApplication)
    {
      if ([[app applicationName] isEqualToString: name])
      {
        if ([app isKeptInDock] == YES) {
          [app setRunning: NO];
          return;
        }
        [[app window] orderOut: self];
        [apps removeObject: app];
      }
    }
  }
  /* Do not organize applications here 
     because it will be called multiple times from other method. */
}

- (void) addXWindowWithID: (int) wid
{
  /* Avoid _NET_WM_STATE_SKIP_PAGER and _NET_WM_STATE_SKIP_TASKBAR */
  if (wid) 
  {
    unsigned long k, kcount;
    Atom *states = XWindowNetStates(wid, &kcount);
    for (k = 0; k < kcount; k++) 
    {
      if ((states[k] == X_NET_WM_STATE_SKIP_PAGER) ||
          (states[k] == X_NET_WM_STATE_SKIP_TASKBAR)) 
      {
        return;
      }
    }
  }

  /* Avoid transcient window */
  {
    Window tr = None;
    if (XGetTransientForHint(dpy, wid, &tr)) 
    {
      return;
    }
  }

  NSString *wm_class, *wm_instance;
  BOOL result = XWindowClassHint(wid, &wm_class, &wm_instance);
  if (result) 
  {
    /* Avoid anything in blacklist */
    if ([blacklist containsObject: wm_instance] == YES) {
      return;
    }

    /* GNUstep application is managed through NSWorkspace,
       not here */
    if ([wm_class isEqualToString: @"GNUstep"]) {
      return;
    }
  }

  /* Go through all apps to see which one want to accept it */
  AZXWindowApp *app = nil;
  int j;
  for (j = 0; j < [apps count]; j++)
  {
    app = [apps objectAtIndex: j];
    if ([app type] == AZDockXWindowApplication) 
    {
      if ([(AZXWindowApp *)app acceptXWindow: wid]) 
      {
        [app setRunning: YES];
        return;
      }
    }
  }
   
  /* No one takes it. Create new dock apps */
  app = [[AZXWindowApp alloc] initWithXWindow: wid];
  [app setRunning: YES];
  [apps addObject: app];
  [self addBookmark: app];
  [[app window] orderFront: self];
  DESTROY(app);
}

- (void) removeXWindowWithID: (int) wid 
{
  AZXWindowApp *app = nil;
  int k;
  for (k = 0; k < [apps count]; k++) 
  {
    app = [apps objectAtIndex: k];
    if ([app type] == AZDockXWindowApplication) 
    {
      if ([app removeXWindow: wid])
      {
        if ([app numberOfXWindows] == 0)
        {
          if ([app isKeptInDock] == YES) 
          {
            [app setRunning: NO];
          }
          else
          {
            [[app window] orderOut: self];
            [apps removeObject: app];
          }
        }
        return;
      }
    }
  }
}

- (void) gnustepAppWillLaunch: (NSNotification *) not
{
//  Not working ?
//  NSLog(@"will launch %@", not);
}

- (void) gnustepAppDidLaunch: (NSNotification *) not
{
  NSString *name = [[not userInfo] objectForKey: @"NSApplicationName"];
  AZGNUstepApp *app = nil;
  int i, count = [apps count];
  for (i = 0; i < count; i++) 
  {
    app = [apps objectAtIndex: i];
    if ([app type] == AZDockGNUstepApplication)
    {
      if ([[app applicationName] isEqualToString: name])
      {
        /* Application exists in dock. */
        [app setRunning: YES];
        return;
      }
    }
  }
  [self addGNUstepAppNamed: name];
  [self organizeApplications];
}

- (void) gnustepAppDidTerminate: (NSNotification *) not
{
//  NSLog(@"did terminate %@", not);
  NSString *name = [[not userInfo] objectForKey: @"NSApplicationName"];
  [self removeGNUstepAppNamed: name];
  [self organizeApplications];
}

- (void) xwindowAppDidLaunch: (NSNotification *) not
{
//  NSLog(@"xwindow launch %@", not);
  [self addXWindowWithID: 
           [[[not userInfo] objectForKey: @"AZXWindowID"] intValue]];
  [self organizeApplications];
}

- (void) xwindowAppDidTerminate: (NSNotification *) not
{
//  NSLog(@"xwindow terminate %@", not);
  [self removeXWindowWithID:
           [[[not userInfo] objectForKey: @"AZXWindowID"] intValue]];
  [self organizeApplications];
}

#if 0
- (BOOL) isMyWindow: (Window) win
{
  if (win == 0) return NO;
  NSString *wm_instance;
  BOOL result = XWindowClassHint(win, NULL, &wm_instance);
  if (result) {
    if ([wm_instance isEqualToString: [[NSProcessInfo processInfo] processName]]) {
      return YES;
    }
  }
  return NO;
}
#endif

- (void) addBookmark: (AZDockApp *) app
{
  /* Add application into bookmark.
   * First, make sure we don't have the same application.
   * If so, just update the recent visited data.
   * Only 10 applications are keeped in the bookmark
   * and are ordered by recent visit date (from latest to older). */
  NSString *command = [app command];
  BKBookmark *bk;
  NSEnumerator *e;
  if (command){
    e = [[store items] objectEnumerator];
    NSURL *url;
    NSURL *app_url = [NSURL URLWithString: [NSString stringWithFormat: @"file://%@", command]];
    BOOL found = NO;
    while ((bk = [e nextObject])) {
      url = [bk URL];
      if ([url isEqual: app_url]) {
        /* Command exist. Update recent visited date */
	[bk setLastVisitedDate: [NSDate date]];
	found = YES;
	break;
      }
    }
    if (found == NO) {
      bk = [BKBookmark bookmarkWithURL: app_url];
      [bk setLastVisitedDate: [NSDate date]];
      [store addBookmark: bk];
    }
    [[store topLevelRecords] sortUsingSelector: @selector(isLaterThan:)];
    /* Only keep the lastest 10 records */
    unsigned int count = [[store topLevelRecords] count];
    unsigned int limit = 10; 
    if (count > limit) {
      NSArray *subarray = [[store topLevelRecords] subarrayWithRange: NSMakeRange(limit, count-limit)];
      e = [subarray objectEnumerator];
      while ((bk = [e nextObject])) {
        [store removeBookmark: bk];
      }
    }
    [store save];
  }
}

/** End of private */
- (void) organizeApplications
{
  NSWindow *win;
  int i, x, y, w, h;

  /* Calculate the position */
  NSSize size = [[iconWindow screen] frame].size;
  w = [iconWindow frame].size.width;
  h = 0;

  switch (position) 
  {
    case AZDockBottomPosition:
      for (i = 0; i < [apps count]; i++)
      {
        w += [[(AZDockApp *)[apps objectAtIndex: i] window] frame].size.width;
      }
      x = (size.width-w)/2;
      y = 0;
      break;
    case AZDockRightPosition:
      for (i = 0; i < [apps count]; i++)
      {
        h += [[(AZDockApp *)[apps objectAtIndex: i] window] frame].size.height;
      }
      x = size.width-w;
      y = (size.height+h)/2;
      break;
    case AZDockLeftPosition:
    default:
      for (i = 0; i < [apps count]; i++)
      {
        h += [[(AZDockApp *)[apps objectAtIndex: i] window] frame].size.height;
      }
      x = 0;
      y = (size.height+h)/2;
      break;
  }

  [iconWindow setFrameOrigin: NSMakePoint(x, y)];
  NSRect rect = [iconWindow frame];

  switch (position)
  {
    case AZDockBottomPosition:
      x = rect.origin.x+rect.size.width;
      y = rect.origin.y;

      for (i = 0; i < [apps count]; i++)
      {
        win = [(AZDockApp *)[apps objectAtIndex: i] window];
        [win setFrameOrigin: NSMakePoint(x, y)];
        rect = [win frame];
        x += rect.size.width;
      }
      break;
    case AZDockRightPosition:
    case AZDockLeftPosition:
    default:
      x = rect.origin.x;
      y = rect.origin.y-rect.size.height;

      for (i = 0; i < [apps count]; i++)
      {
        win = [(AZDockApp *)[apps objectAtIndex: i] window];
        [win setFrameOrigin: NSMakePoint(x, y)];
        rect = [win frame];
        y -= rect.size.height;
      }
      break;
  }
}

#if 0
- (void) applicationDidTerminate: (NSNotification *) not
{
  AZDockApp *app = [not object];
  if ([app isKeptInDock] == YES) {
    return;
  }
  [[app window] orderOut: self];
  [apps removeObject: app];
}
#endif

#if 0
- (void) readClientList
{
  CREATE_AUTORELEASE_POOL(x);
  Window *win = NULL;
  unsigned long count;
  int i, j, k, m;
  AZDockApp *app;

  Atom type_ret;
  int format_ret;
  unsigned long after_ret;
  int result = XGetWindowProperty(dpy, root_win, X_NET_CLIENT_LIST,
                                  0, 0x7FFFFFFF, False, XA_WINDOW,
                                  &type_ret, &format_ret, &count,
                                  &after_ret, (unsigned char **)&win);
  if ((result != Success) || (count < 1) || (win == NULL)) {
    return;
  }

  /* Remove destroyed windows */
  for (m = 0; m < count; m++) {
    for (k = 0; k < [lastClientList count]; k++) {
      if (win[m] == [[lastClientList objectAtIndex: k] unsignedLongValue]) {
        [lastClientList removeObjectAtIndex: k];
        k--;
      }
    }
  }
  for (m = 0; m < [lastClientList count]; m++) {
    for (k = 0; k < [apps count]; k++) {
      app = [apps objectAtIndex: k];
      if ([app type] == AZDockXWindowApplication) {
        if ([(AZXWindowApp *)app removeXWindow: [[lastClientList objectAtIndex: m] unsignedLongValue]])
          {
            break;
	  }
      }
    }
  }

  [lastClientList removeAllObjects];

  for (i = 0; i < count; i++)
  {
    BOOL skip = NO;

    /* Avoid _NET_WM_STATE_SKIP_PAGER and _NET_WM_STATE_SKIP_TASKBAR */
    if (win[i]) {
      unsigned long k, kcount;
      Atom *states = XWindowNetStates(win[i], &kcount);
      for (k = 0; k < kcount; k++) {
        if ((states[k] == X_NET_WM_STATE_SKIP_PAGER) ||
            (states[k] == X_NET_WM_STATE_SKIP_TASKBAR)) 
	{
	  skip = YES;
	  break;
	}
      }
    }

    if (skip)
      continue;

    /* Avoid transcient window */
    {
      Window tr = None;
      if (XGetTransientForHint(dpy, win[i], &tr)) {
        continue;
      }
    }

    NSString *wm_class, *wm_instance;
    BOOL result = XWindowClassHint(win[i], &wm_class, &wm_instance);
    if (result) {
      /* Avoid anything in blacklist */
      if ([blacklist containsObject: [NSString stringWithFormat: @"%@.%@", wm_instance, wm_class]] == YES) {
        continue;
      }

      if ([wm_class isEqualToString: @"GNUstep"]) {
        /* Check windown level */
        int level;
        if (XGNUstepWindowLevel(win[i], &level)) {
          if (level == NSDesktopWindowLevel) {
            continue;
          } else if (level == NSFloatingWindowLevel) {
            continue;
          } else if (level == NSSubmenuWindowLevel) {
            continue;
          } else if (level == NSTornOffMenuWindowLevel) {
            continue;
#if 0 // Keep main menu for now
          } else if (level == NSMainMenuWindowLevel) {
            continue;
#endif
#if 0 // The same as NSDockWindowLevel. Keep it.
          } else if (level == NSStatusWindowLevel) {
            continue;
#endif
          } else if (level == NSModalPanelWindowLevel) {
            continue;
          } else if (level == NSPopUpMenuWindowLevel) {
            continue;
          } else if (level == NSScreenSaverWindowLevel) {
            continue;
          }
        } 

	if ([gnusteps containsObject: wm_instance]) {
          [lastClientList addObject: [NSNumber numberWithUnsignedLong: win[i]]];
          continue;
	}
      }
    }

    /* Go through all apps to see which one want to accept it */
    for (j = 0; j < [apps count]; j++)
    {
      app = [apps objectAtIndex: j];
      if ([app type] == AZDockXWindowApplication) {
        if ([(AZXWindowApp *)app acceptXWindow: win[i]]) {
          [app setRunning: YES];
          /* Cache xwindow */
          [lastClientList addObject: [NSNumber numberWithUnsignedLong: win[i]]];
          //[self addBookmark: app];
	  skip = YES;
          break;
        }
      }
    }
   
    if (skip)
      continue;

    /* No one takes it. Create new dock apps */
    /* Cache xwindow */
    if (result && [wm_class isEqualToString: @"GNUstep"]) {
      app = [[AZGNUstepApp alloc] initWithApplicationName: wm_instance];
      [lastClientList addObject: [NSNumber numberWithUnsignedLong: win[i]]];
      [gnusteps addObject: wm_instance];
    } else {
      app = [[AZXWindowApp alloc] initWithXWindow: win[i]];
      [lastClientList addObject: [NSNumber numberWithUnsignedLong: win[i]]];
    }
    [app setRunning: YES];
    [apps addObject: app];
    [self addBookmark: app];
    [[app window] orderFront: self];
    DESTROY(app);

    /* Listen to change on client */
#if 0
    XSelectInput(dpy, win[i], (PropertyChangeMask|StructureNotifyMask));
#endif
  }
  free(win);
  DESTROY(x);
}
#endif

#if 0
- (void) handleReparentNotify: (XEvent *) event
{
  NSLog(@"Window %d, Parent %d", event->xreparent.window, event->xreparent.parent);
}
#endif

#if 0
- (void) handleCreateNotify: (XEvent *) event
{
  NSString *c, *i;
  if (XWindowClassHint(event->xcreatewindow.window, &c, &i)) {
    NSLog(@"%@, %@", c, i);
  }
  NSLog(@"Create: %d", event->xcreatewindow.window);
}
#endif

#if 0
- (void) handleMapNotify: (XEvent *) event
{
  NSLog(@"Map: %d", event->xmap.window);
}
#endif

#if 0
- (void) handleUnmapNotify: (XEvent *) event
{
  NSLog(@"Unmap: %d", event->xunmap.window);
}
#endif

#if 0
- (void) handleDestroyNotify: (XEvent *) event
{
  [self removeMissingGNUstepApplication];
}
#endif

#if 0
- (void) handleClientMessage: (XEvent *) event
{
  Atom atom = event->xclient.message_type;
  if (atom == X_NET_NUMBER_OF_DESKTOPS) {
    /* For some reason, this never happens */
    [workspaceView setNumberOfWorkspaces: event->xclient.data.l[0]];
    //[workspaceView setNumberOfWorkspaces: [[NSScreen mainScreen] numberOfWorkspaces]];
  }
}
#endif

#if 0
- (void) handlePropertyNotify: (XEvent *) event
{
  Window win = event->xproperty.window;  
  Atom atom = event->xproperty.atom;

  if (win == root_win)
  {
    if (atom == X_NET_CLIENT_LIST) {
      [self readClientList];
      [self organizeApplications];
    } else if (atom == X_NET_CURRENT_DESKTOP) {
      [workspaceView setCurrentWorkspace: [[iconWindow screen] currentWorkspace]];
    } else if (atom == X_NET_DESKTOP_NAMES) {
      [workspaceView setWorkspaceNames: [[iconWindow screen] namesOfWorkspaces]];
    } else if (atom == X_NET_NUMBER_OF_DESKTOPS) {
      [workspaceView setNumberOfWorkspaces: [[iconWindow screen] numberOfWorkspaces]];
    }
    return;
  }
}
#endif

#if 0
- (void)receivedEvent:(void *)data
                 type:(RunLoopEventType)type
                extra:(void *)extra
              forMode:(NSString *)mode
{
  XEvent event;
//  NSString *wm_class, *wm_instance;
//  BOOL result;

  while (XPending(dpy)) 
  {
    XNextEvent (dpy, &event);

    if ([self isMyWindow: event.xany.window])
    {
      [server processEvent: &event];
      continue;
    }

    switch (event.type) {
#if 0
      case Expose:
	[self handleExpose: &event];
        break;
      case ReparentNotify:
	[self handleReparentNotify: &event];
	break;
      case MapNotify:
	[self handleMapNotify: &event];
	break;
      case UnmapNotify:
	[self handleUnmapNotify: &event];
	break;
      case CreateNotify:
	[self handleCreateNotify: &event];
	break;
#endif
      case ClientMessage:
	[self handleClientMessage: &event];
	break;
      case DestroyNotify:
	/* We need to track the destroy notify only for GNUstep application
	 * because if GNUstep application is hiden, all windows is unmaped
	 * and will not show up in client_list by window manager. */
	[self handleDestroyNotify: &event];
	break;
      case PropertyNotify:
	[self handlePropertyNotify: &event];
	break;
#if 0
      default:
	[server processEvent: &event];
#endif
    }
  }
}
#endif

- (void) applicationWillFinishLaunching: (NSNotification *) not
{
  apps = [[NSMutableArray alloc] init];
  blacklist = [[NSMutableArray alloc] init];
  backup = [[NSMutableArray alloc] init];

  server = GSCurrentServer();
  dpy = (Display *)[server serverDevice];
  screen = [[NSScreen mainScreen] screenNumber];
  root_win = RootWindow(dpy, screen);
  workspace = [NSWorkspace sharedWorkspace];

  /* Hard-coded blacklist for now */
  [blacklist addObject: @"EtoileMenuServer"];
  [blacklist addObject: @"AZDock"];
  [blacklist addObject: @"AZBackground"];
  [blacklist addObject: @"etoile_system"];

#if 0
  lastClientList = [[NSMutableArray alloc] init];
  gnusteps = [[NSMutableArray alloc] init];

  /* Listen event */
  NSRunLoop     *loop = [NSRunLoop currentRunLoop];
  int xEventQueueFd = XConnectionNumber(dpy);

  [loop addEvent: (void*)(gsaddr)xEventQueueFd
                        type: ET_RDESC
                     watcher: (id<RunLoopEvents>)self
                     forMode: NSDefaultRunLoopMode];

  /* Listen to window closing and opening */
  XSelectInput(dpy, root_win, PropertyChangeMask|StructureNotifyMask|SubstructureNotifyMask);

  /* Decide position */
  position = [[NSUserDefaults standardUserDefaults] integerForKey: @"DockPosition"];

  /* Setup Atom */
  X_NET_CURRENT_DESKTOP = XInternAtom(dpy, "_NET_CURRENT_DESKTOP", False);
  X_NET_NUMBER_OF_DESKTOPS = XInternAtom(dpy, "_NET_NUMBER_OF_DESKTOPS", False);
  X_NET_DESKTOP_NAMES = XInternAtom(dpy, "_NET_DESKTOP_NAMES", False);
#endif
  X_NET_CLIENT_LIST = XInternAtom(dpy, "_NET_CLIENT_LIST", False);
  X_NET_WM_STATE_SKIP_PAGER = XInternAtom(dpy, "_NET_WM_STATE_SKIP_PAGER", False);
  X_NET_WM_STATE_SKIP_TASKBAR = XInternAtom(dpy, "_NET_WM_STATE_SKIP_TASKBAR", False);
}

- (void) applicationDidFinishLaunching: (NSNotification *) not
{
  NSRect rect = NSMakeRect(0, 0, 64, 64);
  iconWindow = [[XWindow alloc] initWithContentRect: rect
	                              styleMask: NSBorderlessWindowMask
				        backing: NSBackingStoreRetained
				          defer: NO];
  [iconWindow setDesktop: ALL_DESKTOP];
  [iconWindow skipTaskbarAndPager];

  workspaceView = [[AZWorkspaceView alloc] initWithFrame: [[iconWindow contentView] bounds]];
  [iconWindow setContentView: workspaceView];
  [iconWindow orderFront: self];

  /* Update workspace */
  [workspaceView setWorkspaceNames: [[iconWindow screen] namesOfWorkspaces]];
  [workspaceView setNumberOfWorkspaces: [[iconWindow screen] numberOfWorkspaces]];
  [workspaceView setCurrentWorkspace: [[iconWindow screen] currentWorkspace]];

  ASSIGN(store, [BKBookmarkStore sharedBookmarkWithDomain: BKRecentApplicationsBookmarkStore]);
  [workspaceView setApplicationBookmarkStore: store];

  /* Build up launched GNUstep application */
  NSArray *a = [workspace launchedApplications];
  int i, count = [a count];
  for (i = 0; i < count; i++)
  {
    [self addGNUstepAppNamed: [[a objectAtIndex: i] objectForKey: @"NSApplicationName"]];
  }

  /* Build up launched XWindow application */
  Window *win = NULL;
  Atom type_ret;
  int format_ret;
  unsigned long after_ret, ret_count;
  int result = XGetWindowProperty(dpy, root_win, X_NET_CLIENT_LIST,
                                  0, 0x7FFFFFFF, False, XA_WINDOW,
                                  &type_ret, &format_ret, &ret_count,
                                  &after_ret, (unsigned char **)&win);
  if ((result == Success) && (ret_count> 0) && (win != NULL)) 
  {
    NSLog(@"Got client list");
    for (i = 0; i < ret_count; i++)
    {
      [self addXWindowWithID: win[i]];
    }
  }

#if 0
  [self readClientList];

  /* Listen to NSConnectionDidDieNotification when AZDock terminate
   * applications */
  [[NSNotificationCenter defaultCenter]
                    addObserver: self
                    selector: @selector(connectionDidDie:)
                    name: NSConnectionDidDieNotification
	            object: nil];
  [[NSNotificationCenter defaultCenter]
                    addObserver: self
                    selector: @selector(applicationDidTerminate:)
                    name: AZApplicationDidTerminateNotification 
	            object: nil];
#endif
  [self organizeApplications];

  /* Listen to NSWorkspace for application launch and termination. */
  [[workspace notificationCenter]
                     addObserver: self
                     selector: @selector(gnustepAppWillLaunch:)
                     name: NSWorkspaceWillLaunchApplicationNotification
                     object: nil];
  [[workspace notificationCenter]
                     addObserver: self
                     selector: @selector(gnustepAppDidLaunch:)
                     name: NSWorkspaceDidLaunchApplicationNotification
                     object: nil];
  [[workspace notificationCenter]
                     addObserver: self
                     selector: @selector(gnustepAppDidTerminate:)
                     name: NSWorkspaceDidTerminateApplicationNotification
                     object: nil];
  /* From Azalea */
  [[workspace notificationCenter]
                     addObserver: self
                     selector: @selector(xwindowAppDidLaunch:)
                     name: @"AZXWindowDidLaunchNotification"
                     object: nil];
  [[workspace notificationCenter]
                     addObserver: self
                     selector: @selector(xwindowAppDidTerminate:)
                     name: @"AZXWindowDidTerminateNotification"
                     object: nil];
}

- (void) dealloc
{
  DESTROY(apps);
  DESTROY(blacklist);
  DESTROY(backup);
  DESTROY(workspaceView);
  DESTROY(store);
#if 0
  DESTROY(lastClientList);
  DESTROY(gnusteps);
#endif
  [super dealloc];
}

+ (AZDock *) sharedDock
{
  if (sharedInstance == nil)
    sharedInstance = [[AZDock alloc] init];
  return sharedInstance;
}

@end

