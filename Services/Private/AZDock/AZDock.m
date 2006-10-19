#import "AZDock.h"
#import "AZDockApp.h"
#import "AZWorkspaceView.h"
#import <GNUstepGUI/GSDisplayServer.h>
#import <X11/Xatom.h>
#import <X11/Xutil.h>
#import <XWindowServerKit/XFunctions.h>
#import <BookmarkKit/BookmarkKit.h>

@interface GSDisplayServer (AZPrivate)
- (void) processEvent: (XEvent *) event;
@end

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

- (void) removeApplicationWithoutWindow
{
  /* Remove emtpy dock app */
  int m;
  BOOL remove;
  for (m = [apps count]-1; m > -1; m--) {
    remove = NO;
    AZDockApp *app = [apps objectAtIndex: m];
    if ([app numberOfXWindows] == 0) {
      if ([app type] == AZDockGNUstepApplication) {
        /* Check for GNUstep. Only remove when group window is 0
	 * because it can be hiden, in which case, it has no windows
	 * but group window. */
	if ([app groupWindow] == 0) {
	  remove = YES;
	}
      } else {
	/* For any other application, remove it when it has no windows */
	remove = YES;
      }
      if (remove)  {
        /* Do not use -close because it trigger another _net_client_list event */
        [[app window] orderOut: self];
        [apps removeObjectAtIndex: m];
      }
    }
  }
}

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

- (void) connectionDidDie: (NSNotification *) not
{
  /* An application terminates. Try to find out which one */
  NSArray *array = [[NSWorkspace sharedWorkspace] launchedApplications];
  NSMutableArray *ma = [[NSMutableArray alloc] init];
  int i;
  for (i = 0; i < [array count]; i++) {
    [ma addObject: [(NSDictionary *)[array objectAtIndex: i] objectForKey: @"NSApplicationName"]];
  }

  AZDockApp *app;
  for (i = 0; i < [apps count]; i++) {
    app = [apps objectAtIndex: i];
    if ([app type] == AZDockGNUstepApplication) {
      if ([ma containsObject: [app command]] == NO) {
	[[app window] orderOut: self];
	[apps removeObjectAtIndex: i];
	break;
      }
    } 
  }
  [self organizeApplications];
  DESTROY(ma);
}


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
    NSLog(@"Error: cannot get client list");
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
      if ([[apps objectAtIndex: k] removeXWindow: [[lastClientList objectAtIndex: m] unsignedLongValue]])
      {
        break;
      }
    }
  }
  [self removeApplicationWithoutWindow];

  [lastClientList removeAllObjects];

  for (i = 0; i < count; i++)
  {
    BOOL skip = NO;

    /* Do not manage my own window (AZDock.GNUstep) */
    if ([self isMyWindow: win[i]] == YES)
      skip = YES;

    /* Avoid _NET_WM_STATE_SKIP_PAGER and _NET_WM_STATE_SKIP_TASKBAR */
    if (win[i]) {
      unsigned long k, kcount;
      Atom *states = XWindowNetStates(win[i], &kcount);
      for (k = 0; k < kcount; k++) {
        if ((states[k] == X_NET_WM_STATE_SKIP_PAGER) ||
	    (states[k] == X_NET_WM_STATE_SKIP_TASKBAR)) {
	  skip = YES;
	  break;
        }
      }
    }

    /* Avoid transcient window */
    {
      Window tr = None;
      if (XGetTransientForHint(dpy, win[i], &tr)) {
	skip = YES;
      }
    }

    /* Go through all apps to see which one want to accept it */
    for (j = 0; j < [apps count]; j++)
    {
      app = [apps objectAtIndex: j];
      if ([app acceptXWindow: win[i]]) {
	/* Cache xwindow */
	[lastClientList addObject: [NSNumber numberWithUnsignedLong: win[i]]];
	//[self addBookmark: app];
	skip = YES;
	break;
      }
    }

    if (skip)
      continue;

    /* No one takes it. Create new dock apps */
    /* Cache xwindow */
    [lastClientList addObject: [NSNumber numberWithUnsignedLong: win[i]]];
    app = [[AZDockApp alloc] initWithXWindow: win[i]];
    [apps addObject: app];
    [self addBookmark: app];
    DESTROY(app);

    /* Listen to change on client */
#if 0
    XSelectInput(dpy, win[i], 
		 (PropertyChangeMask|StructureNotifyMask));
#endif
  }
  DESTROY(x);
}

- (void) handleReparentNotify: (XEvent *) event
{
  NSLog(@"Window %d, Parent %d", event->xreparent.window, event->xreparent.parent);
}

- (void) handleCreateNotify: (XEvent *) event
{
  NSString *c, *i;
  if (XWindowClassHint(event->xcreatewindow.window, &c, &i)) {
    NSLog(@"%@, %@", c, i);
  }
  NSLog(@"Create: %d", event->xcreatewindow.window);
}

- (void) handleMapNotify: (XEvent *) event
{
  NSLog(@"Map: %d", event->xmap.window);
}

- (void) handleUnmapNotify: (XEvent *) event
{
  NSLog(@"Unmap: %d", event->xunmap.window);
}

- (void) handleDestroyNotify: (XEvent *) event
{
  int i;
  for (i = 0; i < [apps count]; i++) {
    if ([[apps objectAtIndex: i] removeXWindow: event->xdestroywindow.window]) {
      break; /* Save time */
    }
  }
  /* Need to remove empty application here because it will not trigger
   * an event for readClientList */
  [self removeApplicationWithoutWindow];
  [self organizeApplications];
}

- (void) handleClientMessage: (XEvent *) event
{
  Atom atom = event->xclient.message_type;
  if (atom == X_NET_NUMBER_OF_DESKTOPS) {
    [workspaceView setNumberOfWorkspaces: event->xclient.data.l[0]];
  }
}

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
    }
    return;
  }
}

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
	/* This is only for AZTaskbar.
	 * Make sure main window is focused (appicon may has the focus).
	 */
	[server processEvent: &event];
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
	 * and will not show up in client_list by window manager.
	 * In that case, AZDock will not remove it from the dock.
	 * Only when the group window is destroyed, the GNUstep application
	 * will be removed from the dock */
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

- (void) applicationWillFinishLaunching:(NSNotification *)aNotification
{
  apps = [[NSMutableArray alloc] init];
  lastClientList = [[NSMutableArray alloc] init];

  server = GSCurrentServer();
  dpy = (Display *)[server serverDevice];
  screen = [[NSScreen mainScreen] screenNumber];
  root_win = RootWindow(dpy, screen);

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
  X_NET_CLIENT_LIST = XInternAtom(dpy, "_NET_CLIENT_LIST", False);
  X_NET_WM_STATE_SKIP_PAGER = XInternAtom(dpy, "_NET_WM_STATE_SKIP_PAGER", False);
  X_NET_WM_STATE_SKIP_TASKBAR = XInternAtom(dpy, "_NET_WM_STATE_SKIP_TASKBAR", False);
}

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
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

  [self readClientList];
  [self organizeApplications];

  /* Listen to NSConnectionDidDieNotification when AZDock terminate
   * applications */
  [[NSNotificationCenter defaultCenter]
                    addObserver: self
                    selector: @selector(connectionDidDie:)
                    name: NSConnectionDidDieNotification
	            object: nil];
}

- (void) dealloc
{
  DESTROY(apps);
  DESTROY(lastClientList);
  DESTROY(workspaceView);
  DESTROY(store);
  [super dealloc];
}

+ (AZDock *) sharedDock
{
  if (sharedInstance == nil)
    sharedInstance = [[AZDock alloc] init];
  return sharedInstance;
}

@end

