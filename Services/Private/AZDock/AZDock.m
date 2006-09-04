#import "AZDock.h"
#import "AZDockApp.h"
#import <GNUstepGUI/GSDisplayServer.h>
#import <X11/Xatom.h>
#import <X11/Xutil.h>
#import <XWindowServerKit/XFunctions.h>

@interface GSDisplayServer (AZPrivate)
- (void) processEvent: (XEvent *) event;
@end

static AZDock *sharedInstance;

/* To display on AZDock's icon window*/
@interface GNUstepIconView: NSView
{
  NSImage *GNUstepIcon;
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
/** End of private */

- (void) organizeApplications
{
  NSWindow *win;
  int i, x, y, w;

  /* Calculate the position */
  NSSize size = [[NSScreen mainScreen] frame].size;
  w = [iconWindow frame].size.width;
  for (i = 0; i < [apps count]; i++)
  {
    w += [[(AZDockApp *)[apps objectAtIndex: i] window] frame].size.width;
  }
  x = (size.width-w)/2;
  y = 0;
  [iconWindow setFrameOrigin: NSMakePoint(x, y)];

  NSRect rect = [iconWindow frame];
  x = rect.origin.x+rect.size.width;
  y = rect.origin.y;

  for (i = 0; i < [apps count]; i++)
  {
    /* Only do it horizontallly */
    win = [(AZDockApp *)[apps objectAtIndex: i] window];
    [win setFrameOrigin: NSMakePoint(x, y)];
    rect = [win frame];
    x += rect.size.width;
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
  /* Remove emtpy dock app */
  for (m = [apps count]-1; m > -1; m--) {
    if ([[apps objectAtIndex: m] numberOfXWindows] == 0) {
      /* Do not use -close because it trigger another _net_client_list event */
      [[(AZDockApp *)[apps objectAtIndex: m] window] orderOut: self];
      [apps removeObjectAtIndex: m];
    }
  }

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
#if 0
  NSLog(@"%d", event->xany.window);
  NSLog(@"%d", event->xdestroywindow.event);
  int i;
  for (i = 0; i < [apps count]; i++) {
    if ([[apps objectAtIndex: i] removeXWindow: event->xdestroywindow.window]) {
      break; /* Save time */
    }
  }
  NSLog(@"Destroy: %d", event->xdestroywindow.window);
  [self organizeApplications];
#endif
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
      case DestroyNotify:
	[self handleDestroyNotify: &event];
	break;
#endif
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

  GNUstepIconView *view = [[GNUstepIconView alloc] initWithFrame: [[iconWindow contentView] bounds]];
  [iconWindow setContentView: view];
  DESTROY(view);

  [iconWindow orderFront: self];
#if 0
  NSString *c, *i;
  BOOL result = XWindowClassHint(iconXWindow, &c, &i);
  if (result)
    NSLog(@"%@ %@", c, i);
#endif
  /* Setup user interface */
#if 0
  NSRect rect = NSMakeRect(0, 0, 500, 50);
  panelView = [[AZTaskbarView alloc] initWithFrame: rect];
  panelWindow = [[AZTaskbarWindow alloc] initWithContentRect: rect
	                     styleMask: NSTitledWindowMask|NSClosableWindowMask
		             backing: NSBackingStoreBuffered
			     defer: YES];
  [panelWindow setContentView: panelView];
  [panelWindow setTitle: @"AZTaskbar"];
  [panelWindow orderFront: self];

  /* Cache main window because if it is closed (destroyed),
   * any attempt to get xwindow from main window (NSWindow) 
   * causes segment fault.
   */
  mainXWindow = [panelWindow xwindow];
  if (mainXWindow == 0)
  {
    NSLog(@"Internal Error: cannot get mainXWindow");
  }

  /* stay in all desktops */
  [panelWindow becomeSticky];

#endif
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

@implementation GNUstepIconView
- (id) initWithFrame: (NSRect) rect
{
  self = [super initWithFrame: rect];
  ASSIGN(GNUstepIcon, [NSImage imageNamed: @"GNUstep.tiff"]);
  return self;
}

- (void) drawRect: (NSRect) rect
{
  [super drawRect: rect];
  if (GNUstepIcon) {
    NSRect source = NSMakeRect(0, 0, 64, 64);
    NSRect dest = NSMakeRect(8, 8, 48, 48);
    source.size = [GNUstepIcon size];
    [self lockFocus];
    [GNUstepIcon drawInRect: dest
	     fromRect: source
	    operation: NSCompositeSourceAtop
	     fraction: 1];
    [self unlockFocus];
  }
}

- (void) dealloc
{
  DESTROY(GNUstepIcon);
  [super dealloc];
}

@end
