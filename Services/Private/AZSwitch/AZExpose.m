/*  
 *  AZExpose - A window switcher for GNUstep
 *  Copyright (C) 2007 Yen-Ju Chen 
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import "AZExpose.h"
#import "AZClient.h"
#import <X11/Xatom.h>
#import <X11/Xutil.h>
#import <XWindowServerKit/XFunctions.h>

static NSString *AZUserDefaultModifierKey = @"ModifierKey";
static NSString *AZUserDefaultModifierMask = @"ModifierMask";
static NSString *AZUserDefaultSwitchKey = @"SwitchKey";

static AZExpose *sharedInstance;

@interface GSDisplayServer (AZPrivate) 	 
 - (void) processEvent: (XEvent *) event; 	 
@end

@implementation AZExpose

- (void) updateClientList
{
	CREATE_AUTORELEASE_POOL(x);
	Window *win = NULL;
	unsigned long count;
	int i;

	Atom type_ret;
	int format_ret;
	unsigned long after_ret;
	int result = XGetWindowProperty(dpy, root_win, X_NET_CLIENT_LIST_STACKING,
                                    0, 0x7FFFFFFF, False, XA_WINDOW,
                                    &type_ret, &format_ret, &count,
                                    &after_ret, (unsigned char **)&win);
	if ((result != Success) || (count < 1) || (win == NULL)) 
	{
		return;
	}

	[clients removeAllObjects];
	for (i = 0; i < count; i++)
	{
		NSString *wm_class, *wm_instance;
		BOOL skip = NO;

		/* Avoid _NET_WM_STATE_SKIP_PAGER and _NET_WM_STATE_SKIP_TASKBAR */
		unsigned long k, kcount;
		Atom *states = XWindowNetStates(win[i], &kcount);
		for (k = 0; k < kcount; k++) 
		{
			if ((states[k] == X_NET_WM_STATE_SKIP_PAGER) ||
			    (states[k] == X_NET_WM_STATE_SKIP_TASKBAR)) 
			{
				skip = YES;
				break;
			}
		}

		if (skip)
			continue;

		/* Avoid transcient window */
		{
			Window tr = None;
			if (XGetTransientForHint(dpy, win[i], &tr)) 
			{
				continue;
			}
		}
		BOOL result = XWindowClassHint(win[i], &wm_class, &wm_instance);
		if (result) 
		{
			/* Avoid anything in blacklist */
			if ([blacklist containsObject: [NSString stringWithFormat: @"%@", wm_instance]] == YES) 
				continue;

			if ([wm_class isEqualToString: @"GNUstep"]) 
			{
				/* Check windown level */
				int level;
				if (XGNUstepWindowLevel(win[i], &level)) 
				{
					if ((level == NSDesktopWindowLevel) ||
					    (level == NSFloatingWindowLevel) ||
					    (level == NSSubmenuWindowLevel) ||
					    (level == NSTornOffMenuWindowLevel) ||
					    (level == NSMainMenuWindowLevel) ||
						(level == NSStatusWindowLevel) ||
					    (level == NSModalPanelWindowLevel) ||
					    (level == NSPopUpMenuWindowLevel) ||
						(level == NSScreenSaverWindowLevel))
					{
						continue;
					}
				}
			} 
		}
		AZClient *client = [[AZClient alloc] initWithXWindow: win[i]];
		[client setInstance: wm_instance];
		[client setClass: wm_class];
		[clients insertObject: client atIndex: 0]; /* reverse order */
	}
	free(win);
	DESTROY(x);
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

		switch (event.type) 
		{
			case KeyPress:
				if ((event.xkey.keycode == switchKey) &&
				         (event.xkey.state & mask) &&
				         (isSwitching == NO))
				{
					NSLog(@"Start");
					XGrabKeyboard(dpy, root_win, True, 
					              GrabModeAsync, GrabModeAsync, CurrentTime);
					isSwitching = YES;
					[self updateClientList];
					[window setClients: clients];
					[window makeKeyAndOrderFront: self];
					break;
				}
				else if ((event.xkey.keycode == switchKey) &&
				         (isSwitching == YES))
				{
					NSLog(@"Switch");
					if (event.xkey.state & ShiftMask)
					{
						[window previous: self];
					}
					else
					{
						[window next: self];
					}
					break;
				}
			case KeyRelease:
				if ((event.xkey.keycode == modifierKey) &&
				    (isSwitching == YES))
				{
					XUngrabKeyboard(dpy, CurrentTime);
					isSwitching = NO;
					[window orderOut: self];
					AZClient *client = [clients objectAtIndex: [window indexOfSelectedClient]];
					[client show: self];
					break;
				}
#if 0 // Cannot have modifier key and button at the same time !!
			case ButtonPress:
			case ButtonRelease:
				/* We remove modifier key here */
				NSLog(@"1");
				if (event.xbutton.state & Mod1Mask)
				{
					event.xbutton.state &= ~Mod1Mask;
					NSLog(@"Here");
				}
				/* Let it fall back to GNUstep */
#endif
			default:
				if (event.xany.window != root_win)
				{
					/* We only listen to root window.  So if it is not 
					   for root window, it must for us */
					[server processEvent: &event];
				}
		}
	}
}

- (void) applicationWillFinishLaunching: (NSNotification *) not
{
	server = GSCurrentServer();
	dpy = (Display *)[server serverDevice];
	screen = [[NSScreen mainScreen] screenNumber];
	root_win = RootWindow(dpy, screen);

	isSwitching = NO;

	/* Get key */
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *key = nil;
	KeySym keysym;

	key = [defaults stringForKey: AZUserDefaultModifierKey];
	if (key == nil)
		key = @"Alt_L";
	/* This must match AltMask */
	keysym = XStringToKeysym([key UTF8String]);
	if (keysym == NoSymbol)
	{
		NSLog(@"Cannot get modifier key code: %@", key);
		[NSApp terminate: nil];
	}
	modifierKey = XKeysymToKeycode(dpy, keysym);

	key = [defaults stringForKey: AZUserDefaultSwitchKey];
	if (key == nil)
		key = @"Tab";
	keysym = XStringToKeysym([key UTF8String]);
	if (keysym == NoSymbol)
	{
		NSLog(@"Cannot get switch key code: %@", key);
		[NSApp terminate: nil];
	}
	switchKey = XKeysymToKeycode(dpy, keysym);

	mask = Mod1Mask;
	if ([defaults objectForKey: AZUserDefaultModifierMask])
	{
		mask = [defaults integerForKey: AZUserDefaultModifierMask];
	}

	/* Hard-coded blacklist for now */
	blacklist = [[NSMutableArray alloc] init];
	[blacklist addObject: @"EtoileMenuServer"];
	[blacklist addObject: @"AZDock"];
	[blacklist addObject: @"Azalea"];
	[blacklist addObject: @"AZBackground"];
	[blacklist addObject: @"etoile_system"];
	[blacklist addObject: @"TrashCan"];

	clients = [[NSMutableArray alloc] init];

	/* Listen event */
	NSRunLoop *loop = [NSRunLoop currentRunLoop];
	int xEventQueueFd = XConnectionNumber(dpy);

	[loop addEvent: (void*)(gsaddr)xEventQueueFd
	          type: ET_RDESC
	       watcher: (id<RunLoopEvents>)self
	       forMode: NSDefaultRunLoopMode];

	/* Listen to root window*/
	XSelectInput(dpy, root_win, PropertyChangeMask);

	/* Grab key */
#if 0
	XGrabKey(dpy, modifierKey, AnyModifier, root_win, False,
	         GrabModeAsync, GrabModeAsync);
#endif
	XGrabKey(dpy, switchKey, mask, root_win, False,
	         GrabModeAsync, GrabModeAsync);

	/* Setup Atom */
#if 0
	X_NET_CURRENT_DESKTOP = XInternAtom(dpy, "_NET_CURRENT_DESKTOP", False);
	X_NET_NUMBER_OF_DESKTOPS = XInternAtom(dpy, "_NET_NUMBER_OF_DESKTOPS", False);
	X_NET_DESKTOP_NAMES = XInternAtom(dpy, "_NET_DESKTOP_NAMES", False);
#endif
	X_NET_CLIENT_LIST_STACKING = XInternAtom(dpy, "_NET_CLIENT_LIST_STACKING", False);
	X_NET_WM_STATE_SKIP_PAGER = XInternAtom(dpy, "_NET_WM_STATE_SKIP_PAGER", False);
	X_NET_WM_STATE_SKIP_TASKBAR = XInternAtom(dpy, "_NET_WM_STATE_SKIP_TASKBAR", False);

	NSRect rect = NSMakeRect(200, 200, 500, 500);
	window = [[AZSwitchingWindow alloc] initWithContentRect: rect
	                                    styleMask: NSBorderlessWindowMask
	                                    backing: NSBackingStoreRetained
	                                    defer: NO];
	[window setDelegate: self];
}

- (void) applicationDidFinishLaunching: (NSNotification *) not
{
}

- (void) applicationWillTerminate: (NSNotification *) not
{
}

- (void) dealloc
{
	DESTROY(clients);
	DESTROY(blacklist);
	DESTROY(window);
	[super dealloc];
}

+ (AZExpose *) expose 
{
	if (sharedInstance == nil)
		sharedInstance = [[AZExpose alloc] init];
	return sharedInstance;
}

@end

