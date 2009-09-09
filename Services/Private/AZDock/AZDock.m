#import "AZDock.h"
#import "AZXWindowApp.h"
#import "AZGNUstepApp.h"
#import "AZDockletApp.h"
#import "AZWorkspaceView.h"
#import <X11/Xatom.h>
#import <X11/Xutil.h>
#import <XWindowServerKit/XFunctions.h>
#ifdef USE_BOOKMARK
#import <BookmarkKit/BookmarkKit.h>
#endif

static NSString *AZUserDefaultDockType = @"Type";
static NSString *AZUserDefaultDockCommand = @"Command";
static NSString *AZUserDefaultDockCounter = @"Counter";
static NSString *AZUserDefaultDockWMInstance = @"WMInstance"; // For xwindow
static NSString *AZUserDefaultDockWMClass = @"WMClass"; // For xwindow
static NSString *AZUserDefaultDockedApp = @"DockedApplications";
static NSString *AZUserDefaultDockAutoHidden = @"AutoHidden";
static NSString *AZUserDefaultDockMaxApps = @"MaxApps";
static NSString *AZUserDefaultDockSize = @"DockSize";

static AZDock *sharedInstance;
static BOOL do_not_display = NO; // block display when resizing

int autoHiddenSpace = 1; /* Must larger than 0 */

@interface GSDisplayServer (AZPrivate) 	 
 - (void) processEvent: (XEvent *) event; 	 
@end

#ifdef USE_BOOKMARK
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
#endif

@implementation AZDock

/** Private **/
- (void) reserveSpaceForWindow: (XWindow *) window
{
	/* Finally, we occupy a strip of screen so that full-screen window
	   will not be covered. Ideally we should update the space according
	   to the real area of docks. But for now, we occupy the whole side
	   of screen. */
	int size = NSWidth([iconWindow frame]);
	switch(position)
	{
		case AZDockBottomPosition:
			[window reserveScreenAreaOn: XScreenBottomSide 
			        width: (isHidden) ? autoHiddenSpace : size 
			        start: NSMinX(dockFrame) end: NSMaxX(dockFrame)];
			break;
		case AZDockRightPosition:
			[window reserveScreenAreaOn: XScreenRightSide 
			        width: (isHidden) ? autoHiddenSpace : size 
			        start: NSMinY(dockFrame) end: NSMaxY(dockFrame)];
			break;
		case AZDockLeftPosition:
		default:
			[window reserveScreenAreaOn: XScreenLeftSide 
			        width: (isHidden) ? autoHiddenSpace : size 
			        start: NSMinY(dockFrame) end: NSMaxY(dockFrame)];
	}
}

- (BOOL) isGNUstepAppAlive: (NSString *) name
{
  NSConnection *conn = nil;
  ASSIGN(conn, [NSConnection connectionWithRegisteredName: name host: @""]);
  if (conn) {
    /* It is reported that an exception is raised.
     * It could be the connection dies suddenly.
     * In that case, it is not alive.
     * We catch the exception here and only return YES when
     * there is no exception */
    NS_DURING
      [conn invalidate];
      DESTROY(conn);
      NS_VALUERETURN(YES, BOOL);
    NS_HANDLER
      /* Make sure it is released */
      DESTROY(conn);
    NS_ENDHANDLER
  }
  return NO;
}

- (void) checkAlive: (id) sender
{
	//NSLog(@"checkAlive %@", sender);
	if ([[sender userInfo] isKindOfClass: [AZGNUstepApp class]])
	{
		/* Connect to application */
		AZGNUstepApp *app = (AZGNUstepApp *)[sender userInfo];
		if ([self isGNUstepAppAlive: [app applicationName]]) 
		{
		}
		else 
		{
			[app setState: AZDockAppNotRunning];
			if ([app isKeptInDock] == YES) 
			{
				return;
			}
			[[app window] orderOut: self];
			[apps removeObject: app];
		}
	} 
}

- (AZGNUstepApp *) addGNUstepAppNamed: (NSString *) name 
{
	if ([blacklist containsObject: name])
		return nil;

	/* Check existence of GNUstep application */
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
				return app;
			}
		}
	}

	/* New GNUstep application */
	app = [[AZGNUstepApp alloc] initWithApplicationName: name];
	[app setState: AZDockAppNotRunning]; 
	[apps addObject: app];
#ifdef USE_BOOKMARK
	[self addBookmark: app];
#endif
	[self reserveSpaceForWindow: [app window]];
//	[[app window] orderFront: self];
	return AUTORELEASE(app);
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
        /* We have to change their state to 'not running'
           so that we can correctly detect abnormal termination */
        [app setState: AZDockAppNotRunning];
        [self removeDockApp: app];
      }
    }
  }
  /* Do not organize applications here 
     because it will be called multiple times from other method. */
}

- (void) addGNUstepAppWithXWindowID: (Window) wid 
                           instance: (NSString *) wm_inst 
{
  /* We have a xwindow for GNUstep.
     If it comes before GNUstep application launched,
     create a dock for GNUstep and mark as launching.
     If it comes after GNUstep application lauched,
     add the xwindow. */
  AZGNUstepApp *app = [self addGNUstepAppNamed: wm_inst];
  if ([app state] == AZDockAppNotRunning) {
    [app setState: AZDockAppLaunching];
  } else {
    /* Do nothing if launching or running.
       We do not change the state from launching to running here.
       Only notification from NSWorkspace can do that. */
  } 
  /* We keep a record of xwindow here. */
  [app acceptXWindow: wid];
}

- (AZXWindowApp *) addXWindowWithCommand: (NSString *) cmd
                   instance: (NSString *) instance class: (NSString *) class
{
  AZXWindowApp *app = [[AZXWindowApp alloc] initWithCommand: cmd 
                                            instance: instance class: class];
  [apps addObject: app];
#ifdef USE_BOOKMARK
  [self addBookmark: app];
#endif
  [self reserveSpaceForWindow: [app window]];
//  [[app window] orderFront: self];
  return AUTORELEASE(app);
}

- (void) addXWindowWithID: (int) wid
{
	/* Avoid transcient window */
	{
		Window tr = None;
		if (XGetTransientForHint(dpy, wid, &tr)) 
		{
			return;
		}
	}

	/* We check GNUstep application early because main menu
	   and app icon has SKIP_PAGER and SKIP_TASKBAR hints. */
	NSString *wm_class, *wm_instance;
	BOOL result = XWindowClassHint(wid, &wm_class, &wm_instance);
	if (result) 
	{
		/* Avoid anything in blacklist */
		if ([blacklist containsObject: wm_instance] == YES) 
		{
			return;
		}

		if ([wm_class isEqualToString: @"GNUstep"]) 
		{
			/* We let GNUstep app to hanel it */
			[self addGNUstepAppWithXWindowID: wid instance: wm_instance];
			return;
		}
	}

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
				[app setState: AZDockAppRunning];
				[app increaseCounter];
				return;
			}
		}
	}
   
	/* No one takes it. Create new dock apps */
	app = [[AZXWindowApp alloc] initWithXWindow: wid];
	[app setState: AZDockAppRunning];
	[apps addObject: app];
#ifdef USE_BOOKMARK
  [self addBookmark: app];
#endif
	[self reserveSpaceForWindow: [app window]];
//	[[app window] orderFront: self];
	DESTROY(app);
}

- (void) removeXWindowWithID: (int) wid 
{
  AZXWindowApp *app = nil;
  int k;
  for (k = 0; k < [apps count]; k++) 
  {
    app = [apps objectAtIndex: k];
    if ([app removeXWindow: wid])
    {
      if ([app type] == AZDockXWindowApplication) 
      {
        if ([app numberOfXWindows] == 0)
        {
          /* Change state just in case */
          [app setState: AZDockAppNotRunning];
          [self removeDockApp: app];
        }
        return;
      }
      else if ([app type] == AZDockGNUstepApplication) 
      {
//        NSLog(@"here");
#if 0
        if ([app numberOfXWindows] == 0)
        {
          [self removeDockApp: app];
        }
        return;
#endif
      }
    }
  }
}

- (AZDockletApp *) addDockletWithCommand: (NSString *) cmd
                   instance: (NSString *) instance class: (NSString *) class
{
  AZDockletApp *app = [[AZDockletApp alloc] initWithCommand: cmd 
                                            instance: instance class: class];
  [apps addObject: app];
#ifdef USE_BOOKMARK
  [self addBookmark: app];
#endif
  [self reserveSpaceForWindow: [app window]];
//  [[app window] orderFront: self];
  return AUTORELEASE(app);
}

- (void) addDockletWithID: (int) wid 
{
  /* Let's see whether any dockapp will take it.
     We cannot use addXWindowWithID: because docklet's window is not mapped
     yet. And Azalea does not send docklet as regular xwindow. */
  AZDockletApp *app = nil;
  int j;
  for (j = 0; j < [apps count]; j++)
  {
    app = [apps objectAtIndex: j];
    if ([app type] == AZDockWindowMakerDocklet) 
    {
      if ([(AZDockletApp *)app acceptXWindow: wid]) 
      {
        [app setState: AZDockAppRunning];
        return;
      }
    }
  }

  //NSLog(@"addDockletWithID %d", wid);
  app = [[AZDockletApp alloc] initWithXWindow: wid];
  [app setState: AZDockAppRunning];
  [apps addObject: app];
#ifdef USE_BOOKMARK
  [self addBookmark: app];
#endif
  [self reserveSpaceForWindow: [app window]];
//  [[app window] orderFront: self];
  DESTROY(app);
}

/* Notification from Azalea */
- (void) gnustepAppWillLaunch: (NSNotification *) not
{
//  Not working ?
//  NSLog(@"will launch %@", not);
}

- (void) gnustepAppDidLaunch: (NSNotification *) not
{
  NSString *name = [[not userInfo] objectForKey: @"NSApplicationName"];
  AZGNUstepApp *app = [self addGNUstepAppNamed: name];
  [app setState: AZDockAppRunning];
  [self organizeApplications];
}

- (void) gnustepAppDidTerminate: (NSNotification *) not
{
  NSString *name = [[not userInfo] objectForKey: @"NSApplicationName"];
  [self removeGNUstepAppNamed: name];
  [self organizeApplications];
}

- (void) xwindowAppDidLaunch: (NSNotification *) not
{
  [self addXWindowWithID: 
           [[[not userInfo] objectForKey: @"AZXWindowID"] intValue]];
  [self organizeApplications];
}

- (void) xwindowAppDidTerminate: (NSNotification *) not
{
NSLog(@"XWindow app did terminate %@", not);
  [self removeXWindowWithID:
           [[[not userInfo] objectForKey: @"AZXWindowID"] intValue]];
  [self organizeApplications];
}

- (void) dockletAppDidLaunch: (NSNotification *) not
{
//NSLog(@"docklet did launch");
  [self addDockletWithID: 
           [[[not userInfo] objectForKey: @"AZXWindowID"] intValue]];
  [self organizeApplications];
}

#ifdef USE_BOOKMARK
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
#endif

/** End of private */
- (int) minimalCountToStayInDock
{
	/* Return the counter of last object */
	int ctr, index, count = [apps count];
	if (count > 0)
	{
		if (maxApps < count)
		{
			index = maxApps -1;
		}
		else
		{
			index = count-1;
		}
		ctr = [[apps objectAtIndex: index] counter];
		return ctr;
	}
	return 0;
}

- (void) removeDockApp: (AZDockApp *) app
{
  if ([app isKeptInDock] == YES) 
  {
    [app setState: AZDockAppNotRunning];
  }
  else
  {
    [[app window] orderOut: self];
    [apps removeObject: app];
    /* Do not organize applications here */
  }
}

- (void) resizeDocksToSize: (int) s
{
	int i;
	NSSize size = NSMakeSize(s, s);
	[iconWindow setContentSize: size];
	for (i = 0; i < [apps count]; i++)
	{
		[[(AZDockApp *)[apps objectAtIndex: i] window] setContentSize: size];
	}
}

- (void) organizeApplications
{
	if (do_not_display == YES)
		return;

	NSScreen *screen = [iconWindow screen];
	NSWindow *win;
	int i, x, y, w, h;

	/* Calculate size */
	NSRect area = [screen workAreaOfDesktop: -1];
	if ((area.size.width == 0) || (area.size.height == 0))
	{
		/* Fail to get work area. Use screen frame as default */
		area = [screen frame];
	}

	switch (position) 
	{
		case AZDockBottomPosition:
			w = NSWidth(area)/(1+[apps count]);
			break;
		default:
			w = NSHeight(area)/(1+[apps count]);
	}

	if (w > 64)
		w = 64;
	else if (w > 56)
		w = 56;
	else if (w > 48)
		w = 48;
	else if (w > 32)
		w = 32;
	else if (w > 24)
		w = 24;
	else 
		w = 16;

	if (w > maxDockSize)
		w = maxDockSize;

	[self resizeDocksToSize: w];

	/* Calculate the position */
	w = NSWidth([iconWindow frame]);
	h = 0;

	switch (position) 
	{
		case AZDockBottomPosition:
#if 1
			w += NSWidth([iconWindow frame])*[apps count];
#else
			for (i = 0; i < [apps count]; i++)
			{
				w += NSWidth([[(AZDockApp *)[apps objectAtIndex: i] window] frame]);
			}
#endif
			x = ((NSWidth(area)-w)/2) + NSMinX(area);
			y = (isHidden) ? -NSHeight([iconWindow frame])+autoHiddenSpace : 0;
			break;
		case AZDockRightPosition:
#if 1
			h += NSHeight([iconWindow frame])*[apps count];
#else
			for (i = 0; i < [apps count]; i++)
			{
				h += NSHeight([[(AZDockApp *)[apps objectAtIndex: i] window] frame]);
			}
#endif
			x = (isHidden) ? NSWidth(area)-autoHiddenSpace : NSWidth(area)-w;
			y = ((NSHeight(area)+h)/2) - (NSMaxY([screen frame])-NSMaxY(area));
			break;
		case AZDockLeftPosition:
		default:
#if 1
			h += NSHeight([iconWindow frame])*[apps count];
#else
			for (i = 0; i < [apps count]; i++)
			{
				h += NSHeight([[(AZDockApp *)[apps objectAtIndex: i] window] frame]);
			}
#endif
			x = (isHidden) ? -w+autoHiddenSpace : 0;
			y = (NSHeight(area)+h)/2 - (NSMaxY([screen frame])-NSMaxY(area));
			break;
	}

	[iconWindow setFrameOrigin: NSMakePoint(x, y)];
	NSRect rect = [iconWindow frame];
	dockFrame = NSUnionRect(dockFrame, rect);

	switch (position)
	{
		case AZDockBottomPosition:
			x = NSMaxX(rect);
			y = NSMinY(rect);

			for (i = 0; i < [apps count]; i++)
			{
				win = [(AZDockApp *)[apps objectAtIndex: i] window];
				[win setFrameOrigin: NSMakePoint(x, y)];
				rect = [win frame];
				dockFrame = NSUnionRect(dockFrame, rect);
				x += NSWidth(rect);
			}
			break;
		case AZDockRightPosition:
		case AZDockLeftPosition:
		default:
			x = NSMinX(rect);
			y = NSMinY(rect)-NSHeight(rect);

			for (i = 0; i < [apps count]; i++)
			{
				win = [(AZDockApp *)[apps objectAtIndex: i] window];
				[win setFrameOrigin: NSMakePoint(x, y)];
				rect = [win frame];
				dockFrame = NSUnionRect(dockFrame, rect);
				y -= NSHeight(rect);
			}
			break;
	}

//	if (do_not_display == NO)
	{
		if ([iconWindow isVisible] == NO)
			[iconWindow orderFront: self];
		for (i = 0; i < [apps count]; i++)
		{
			win = [(AZDockApp *)[apps objectAtIndex: i] window];
			if ([win isVisible] == NO)
				[win orderFront: self];
		}
	}
}

#if 0
- (void) applicationDidTerminate: (NSNotification *) not
{
  NSLog(@"applicationDidTerminate");
  AZDockApp *app = [not object];
  [app setState: AZDockAppNotRunning];
  if ([app isKeptInDock] == YES) {
    return;
  }
  [[app window] orderOut: self];
  [apps removeObject: app];
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

- (void) handleEnterNotify: (XEvent *) event
{
  if (autoHidden == YES)
  {
    if (isHidden == NO)
      return;
    isHidden = NO;
    [self organizeApplications];
  }
}

- (void) handleLeaveNotify: (XEvent *) event
{
  if (autoHidden == YES)
  {
    if (isHidden == YES)
      return;
    /* Are we still in the range of the whole dock ? */
    //NSLog(@"(%d, %d) <%d, %d>", event->xcrossing.x, event->xcrossing.y, event->xcrossing.x_root, event->xcrossing.y_root);
    NSPoint p;
    p.x = event->xcrossing.x_root;
    p.y = event->xcrossing.y_root;
    /* convert from X to GNUstep */
    p.y = [[NSScreen mainScreen] frame].size.height - p.y;
    switch(position) {
      case AZDockBottomPosition:
      case AZDockRightPosition:
      case AZDockLeftPosition:
      default:
        if (NSPointInRect(p, dockFrame))
          return;
    }
    //NSLog(@"%@ in %@", NSStringFromPoint(p), NSStringFromRect(dockFrame));
    isHidden = YES;
    [self organizeApplications];
  }
}

- (void) handlePropertyNotify: (XEvent *) event
{
  Window win = event->xproperty.window;  
  Atom atom = event->xproperty.atom;

  if (win == root_win)
  {
    if (atom == X_NET_CURRENT_DESKTOP) {
      [workspaceView setCurrentWorkspace: [[iconWindow screen] currentWorkspace]];
    } else if (atom == X_NET_DESKTOP_NAMES) {
      [workspaceView setWorkspaceNames: [[iconWindow screen] namesOfWorkspaces]];
    } else if (atom == X_NET_NUMBER_OF_DESKTOPS) {
      [workspaceView setNumberOfWorkspaces: [[iconWindow screen] numberOfWorkspaces]];
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

  while (XPending(dpy)) 
  {
    XNextEvent (dpy, &event);

#if 0
    if ([self isMyWindow: event.xany.window])
    {
      [server processEvent: &event];
      continue;
    }
#endif

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
      case ClientMessage:
	[self handleClientMessage: &event];
	break;
      case DestroyNotify:
	/* We need to track the destroy notify only for GNUstep application
	 * because if GNUstep application is hiden, all windows is unmaped
	 * and will not show up in client_list by window manager. */
	[self handleDestroyNotify: &event];
	break;
#endif
      case EnterNotify:
	[self handleEnterNotify: &event];
 	break;
      case LeaveNotify:
	[self handleLeaveNotify: &event];
 	break;
      case PropertyNotify:
	[self handlePropertyNotify: &event];
	break;
      default:
        if (event.xany.window != root_win)
        {
          /* We only listen to root window.  So if it is not for root window,
             it must for us */
 	  [server processEvent: &event];
        }
    }
  }
}

- (void) applicationWillFinishLaunching: (NSNotification *) not
{
	do_not_display = YES;

	defaults = [NSUserDefaults standardUserDefaults];
	isHidden = NO;
	dockFrame = NSZeroRect;

	apps = [[NSMutableArray alloc] init];
	blacklist = [[NSMutableArray alloc] init];

	server = GSCurrentServer();
	dpy = (Display *)[server serverDevice];
	int screen = [[NSScreen mainScreen] screenNumber];
	root_win = RootWindow(dpy, screen);
	workspace = [NSWorkspace sharedWorkspace];

	/* Hard-coded blacklist for now */
	[blacklist addObject: @"EtoileMenuServer"];
	[blacklist addObject: @"AZDock"];
	[blacklist addObject: @"Azalea"];
	[blacklist addObject: @"AZBackground"];
	[blacklist addObject: @"etoile_system"];
	[blacklist addObject: @"TrashCan"];
	[blacklist addObject: @"AZSwitch"];
	[blacklist addObject: @"Corner"];
	[blacklist addObject: @"Idle"];

	/* Listen event */
	NSRunLoop     *loop = [NSRunLoop currentRunLoop];
	int xEventQueueFd = XConnectionNumber(dpy);

	[loop addEvent: (void*)(gsaddr)xEventQueueFd
                        type: ET_RDESC
                     watcher: (id<RunLoopEvents>)self
                     forMode: NSDefaultRunLoopMode];

	/* Listen to window closing and opening */
	XSelectInput(dpy, root_win, PropertyChangeMask|StructureNotifyMask|SubstructureNotifyMask);

	/* Setup Atom */
	X_NET_CURRENT_DESKTOP = XInternAtom(dpy, "_NET_CURRENT_DESKTOP", False);
	X_NET_NUMBER_OF_DESKTOPS = XInternAtom(dpy, "_NET_NUMBER_OF_DESKTOPS", False);
	X_NET_DESKTOP_NAMES = XInternAtom(dpy, "_NET_DESKTOP_NAMES", False);
	X_NET_CLIENT_LIST = XInternAtom(dpy, "_NET_CLIENT_LIST", False);
	X_NET_WM_STATE_SKIP_PAGER = XInternAtom(dpy, "_NET_WM_STATE_SKIP_PAGER", False);
	X_NET_WM_STATE_SKIP_TASKBAR = XInternAtom(dpy, "_NET_WM_STATE_SKIP_TASKBAR", False);

	/* user defaults */
	position = [defaults integerForKey: AZUserDefaultDockPosition];
	autoHidden = [defaults  boolForKey: AZUserDefaultDockAutoHidden];
	if (autoHidden == YES)
		isHidden = YES;

	maxApps = [defaults boolForKey: AZUserDefaultDockMaxApps];
	if (maxApps == 0)
		maxApps = 9;

	/* Build icon window (Etoile icon) */
    maxDockSize = [defaults integerForKey: AZUserDefaultDockSize];
	if (maxDockSize == 0)
		maxDockSize = 64;
	NSRect rect = NSMakeRect(0, 0, maxDockSize, maxDockSize);
	iconWindow = [[XWindow alloc] initWithContentRect: rect
	                              styleMask: NSBorderlessWindowMask
				        backing: NSBackingStoreRetained
				          defer: NO];
	[iconWindow setDesktop: ALL_DESKTOP];
	[iconWindow skipTaskbarAndPager];
	[self reserveSpaceForWindow: iconWindow];
	[iconWindow setLevel: NSNormalWindowLevel+1];

	workspaceView = [[AZWorkspaceView alloc] initWithFrame: [[iconWindow contentView] bounds]];
	[iconWindow setContentView: workspaceView];
//	[iconWindow orderFront: self];

	/* Put up docked application */
	NSArray *array = [defaults objectForKey: AZUserDefaultDockedApp];
	int i, count = [array count];
	AZDockType type;
	NSString *cmd;
	int ctr;
	NSDictionary *dict;
	AZDockApp *app = nil;
	/* Path to cached icon */
	NSString *path = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
	if (path)
	{
		path = [path stringByAppendingPathComponent: [[NSProcessInfo processInfo] processName]];
	}

	for (i = 0; i < count; i++) 
	{
		dict = [array objectAtIndex: i];
		type = [[dict objectForKey: AZUserDefaultDockType] intValue];
		cmd = [dict objectForKey: AZUserDefaultDockCommand];
		ctr = [[dict objectForKey: AZUserDefaultDockCounter] intValue];
		if (type == AZDockGNUstepApplication)
		{
			app = [self addGNUstepAppNamed: cmd];
		}
		else if (type == AZDockXWindowApplication)
		{
			NSString *inst = [dict objectForKey: AZUserDefaultDockWMInstance];
			NSString *clas = [dict objectForKey: AZUserDefaultDockWMClass];
			app = [self addXWindowWithCommand: cmd instance: inst class: clas];
			/* See whether we have icon cached */
			NSFileManager *fm = [NSFileManager defaultManager];
			if ([fm fileExistsAtPath: path])
			{
				NSString *p = [NSString stringWithFormat: @"%@_%@.tiff", inst, clas];
				p = [path stringByAppendingPathComponent: p];
				//NSLog(@"load from %@", p);
				NSImage *image = [[NSImage alloc] initWithContentsOfFile: p];
				if (image) 
				{
					[app setIcon: AUTORELEASE(image)];
				}
				else 
				{
					NSLog(@"No image");
				}
			}
		}
		else if (type == AZDockWindowMakerDocklet)
		{
			NSString *inst = [dict objectForKey: AZUserDefaultDockWMInstance];
			NSString *clas = [dict objectForKey: AZUserDefaultDockWMClass];
			app = [self addDockletWithCommand: cmd instance: inst class: clas];
		}
		else
		{
		}
		if (ctr == 0)
		{
			/* First time */
			[app setCounter: (count-i)*20];
		}
		else
		{
			[app setCounter: ctr];
		}
		[app setState: AZDockAppNotRunning];
		[app setKeptInDock: YES];
	}
#ifdef AUTOORGANIZE
	/* Sort apps */
	[apps sortUsingSelector: @selector(compareCounter:)];
#endif
}

- (void) applicationDidFinishLaunching: (NSNotification *) not
{
	/* Update workspace */
	[workspaceView setWorkspaceNames: [[iconWindow screen] namesOfWorkspaces]];
	[workspaceView setNumberOfWorkspaces: [[iconWindow screen] numberOfWorkspaces]];
	[workspaceView setCurrentWorkspace: [[iconWindow screen] currentWorkspace]];

#ifdef USE_BOOKMARK
	ASSIGN(store, [BKBookmarkStore sharedBookmarkWithDomain: BKRecentApplicationsBookmarkStore]);
	[workspaceView setApplicationBookmarkStore: store];
#endif

	/* Build up launched GNUstep application */
	AZDockApp *app;
	NSArray *a = [workspace launchedApplications];
	int i, count = [a count];
	for (i = 0; i < count; i++)
	{
		NSString *name = [[a objectAtIndex: i] objectForKey: @"NSApplicationName"];
		/* We need to check the existance of application with NSConnection
		   because NSWorkspace is not realiable */
		if ([self isGNUstepAppAlive: name]) 
		{
			app = [self addGNUstepAppNamed: name];
			[app setState: AZDockAppRunning];
			[app increaseCounter];
		}
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
		for (i = 0; i < ret_count; i++)
		{
			[self addXWindowWithID: win[i]];
		}
	}

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
	[[workspace notificationCenter]
                     addObserver: self
                     selector: @selector(dockletAppDidLaunch:)
                     name: @"AZDockletDidLaunchNotification"
                     object: nil];

	/* We start docklet here */
	for (i = 0; i < [apps count]; i++)
	{
		AZDockletApp *app = [apps objectAtIndex: i];
		if ([app type] == AZDockWindowMakerDocklet)
		{
			[app showAction: self];
		}
	}
	do_not_display = NO;
	[self organizeApplications];
}

- (void) applicationWillTerminate: (NSNotification *) not
{
	[[workspace notificationCenter] removeObserver: self];

	/* We need to cache icon for xwindow applications.
	   Prepare the directory first */
	NSString *path = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
	if (path) 
	{
		NSFileManager *fm = [NSFileManager defaultManager];
		BOOL isDir = NO;
		if ([fm fileExistsAtPath: path isDirectory: &isDir] == NO)
		{
			[fm createDirectoryAtPath: path attributes: nil];
		}

		path = [path stringByAppendingPathComponent: [[NSProcessInfo processInfo] processName]];
		if ([fm fileExistsAtPath: path isDirectory: &isDir] == NO)
		{
			//NSLog(@"create path %@", path);
			if([fm createDirectoryAtPath: path attributes: nil] == NO)
			{
				//NSLog(@"Internal Erro: cannot create path at %@", path);
				path = nil;
			}
		}
	}

#ifdef AUTOORGANIZE
	/* Sort before save */
	[apps sortUsingSelector: @selector(compareCounter:)];
#endif

	/* Remember the application on dock */
	NSMutableArray *array = [[NSMutableArray alloc] init];
	NSDictionary *dict = nil;
	int i, count = [apps count];
	AZDockApp *app;

#ifndef AUTOORGANIZE
	for (i = 0; (i < count) && (i < maxApps); i++) 
	{
		app = [apps objectAtIndex: i];
#else
	for (i = 0; i < count; i++) 
	{
		app = [apps objectAtIndex: i];
		NSLog(@"bip");
		if ([app isKeptInDock]) 
#endif
		{
			if ([app type] == AZDockXWindowApplication) 
			{
				AZXWindowApp *xapp = (AZXWindowApp *) app;
				dict = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSString stringWithFormat: @"%d", [app type]], 
					AZUserDefaultDockType,
					[NSString stringWithFormat: @"%d", [app counter]], 
					AZUserDefaultDockCounter,
					[xapp command], AZUserDefaultDockCommand,
					[xapp wmInstance], AZUserDefaultDockWMInstance,
					[xapp wmClass], AZUserDefaultDockWMClass,
					nil];
				/* We also need to cache the icon because we cannot get icon
				   without a window running */
				if (path)
				{
					NSImage *icon = [xapp icon];
					NSData *data = [icon TIFFRepresentation];
					NSString *p = [NSString stringWithFormat: @"%@_%@.tiff", [xapp wmInstance], [xapp wmClass]];
					p = [path stringByAppendingPathComponent: p];
					//NSLog(@"Write to %@", p);
					[data writeToFile: p atomically: YES];
				}
			} 
			else if ([app type] == AZDockGNUstepApplication) 
			{
				dict = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSString stringWithFormat: @"%d", [app type]], 
					AZUserDefaultDockType,
					[NSString stringWithFormat: @"%d", [app counter]], 
					AZUserDefaultDockCounter,
					[(AZGNUstepApp *)app applicationName], 
					AZUserDefaultDockCommand,
					nil];
			}
			else if ([app type] == AZDockWindowMakerDocklet) 
			{
				AZDockletApp *xapp = (AZDockletApp *) app;
				dict = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSString stringWithFormat: @"%d", 
					[app type]], AZUserDefaultDockType,
					[xapp command], AZUserDefaultDockCommand,
					[xapp wmInstance], AZUserDefaultDockWMInstance,
					[xapp wmClass], AZUserDefaultDockWMClass,
					nil];
			}
			[array addObject: dict];
		}
	}
	[defaults setObject: array forKey: AZUserDefaultDockedApp];
}

- (void) dealloc
{
	DESTROY(apps);
	DESTROY(blacklist);
	DESTROY(workspaceView);
#ifdef USE_BOOKMARK
	DESTROY(store);
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

