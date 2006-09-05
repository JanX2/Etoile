#import "AZDock.h"
#import "AZDockApp.h"
#import "AZWorkspaceView.h"
#import <GNUstepGUI/GSDisplayServer.h>
#import <X11/Xatom.h>
#import <X11/Xutil.h>
#import <XWindowServerKit/XFunctions.h>

@interface GSDisplayServer (AZPrivate)
- (void) processEvent: (XEvent *) event;
@end

static AZDock *sharedInstance;

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
/** End of private */

- (void) organizeApplications
{
  NSWindow *win;
  int i, x, y, w, h;

  /* Calculate the position */
  NSSize size = [[NSScreen mainScreen] frame].size;
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

- (void) readClientList
{
  CREATE_AUTORELEASE_POOL(x);
  Window *win = NULL;
  unsigned long count;
  int i, j, k, m;
  AZDockApp *app;

  Atom prop = XInternAtom(dpy, "_NET_CLIENT_LIST", False);
  Atom skip_pager = XInternAtom(dpy, "_NET_WM_STATE_SKIP_PAGER", False);
  Atom skip_taskbar = XInternAtom(dpy, "_NET_WM_STATE_SKIP_TASKBAR", False);
  Atom type_ret;
  int format_ret;
  unsigned long after_ret;
  int result = XGetWindowProperty(dpy, root_win, prop,
	                        0, 0x7FFFFFFF, False, XA_WINDOW,
			        &type_ret, &format_ret, &count,
			        &after_ret, (unsigned char **)&win);
  if ((result != Success) || (count < 1) || (win == NULL)) {
    NSLog(@"Error: cannot get client list");
    return;
  }

#if 0
  {
    /* Query window */
    Window root_return;
    Window parent_return;
    Window *children_return;
    unsigned int nchildren_return;
    NSString *y, *z;
    XQueryTree(dpy, root_win, &root_return, &parent_return, &children_return, &nchildren_return);
    {
      NSLog(@"Total windows = %d", nchildren_return);
      int x;
      XWMHints *wmHints;
      for (x = 0; x < nchildren_return; x++) 
      {
	if (XWindowClassHint(children_return[x], &y, &z)) {
	  NSLog(@"%d %@.%@", children_return[x], z, y);
	  wmHints = XGetWMHints(dpy, children_return[x]);
	  if (wmHints) {
	    NSLog(@"group %d, state %d", wmHints->window_group, wmHints->initial_state);
	    XFree(wmHints);
	  }
	}
      }
    }
  }
#endif


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
    //NSLog(@"%d", win[i]);
    BOOL skip = NO;

    /* Do not manage my own window (AZDock.GNUstep) */
    if ([self isMyWindow: win[i]] == YES)
      skip = YES;

    /* Avoid _NET_WM_STATE_SKIP_PAGER and _NET_WM_STATE_SKIP_TASKBAR */
    if (win[i]) {
      unsigned long k, kcount;
      Atom *states = XWindowNetStates(win[i], &kcount);
      for (k = 0; k < kcount; k++) {
        if ((states[k] == skip_pager) ||
	    (states[k] == skip_taskbar)) {
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

- (void) handlePropertyNotify: (XEvent *) event
{
  Window win = event->xproperty.window;  
  Atom atom = event->xproperty.atom;
  Atom client_list = XInternAtom(dpy, "_NET_CLIENT_LIST", False);

  if (win == root_win)
  {
    if ((atom == client_list)/* || (atom == AZ_NET_CURRENT_DESKTOP)*/)
    {
      [self readClientList];
      [self organizeApplications];
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
  NSString *wm_class, *wm_instance;
  BOOL result;

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

  //GNUstepIconView *view = [[GNUstepIconView alloc] initWithFrame: [[iconWindow contentView] bounds]];
  AZWorkspaceView *view = [[AZWorkspaceView alloc] initWithFrame: [[iconWindow contentView] bounds]];
  [iconWindow setContentView: view];

#if 0 /* Contextual menu */
  NSMenu *menu = [[NSMenu alloc] initWithTitle: @"Test"];
  [menu addItemWithTitle: @"Menu11" action: NULL keyEquivalent: nil];
  [menu addItemWithTitle: @"Menu12" action: NULL keyEquivalent: nil];
  [menu addItemWithTitle: @"Menu13" action: NULL keyEquivalent: nil];
  [menu addItemWithTitle: @"Menu14" action: NULL keyEquivalent: nil];
  [view setMenu: menu];
  DESTROY(view);
#endif

  [iconWindow orderFront: self];

  [self readClientList];
  [self organizeApplications];
}

- (void) dealloc
{
  DESTROY(apps);
  DESTROY(lastClientList);
  [super dealloc];
}

+ (AZDock *) sharedDock
{
  if (sharedInstance == nil)
    sharedInstance = [[AZDock alloc] init];
  return sharedInstance;
}

@end

