/*  
 *  Busy
 *  Copyright (C) 2007 Yen-Ju Chen 
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import "Busy.h"
#import "AZClient.h"
#import <X11/Xatom.h>
#import <X11/Xutil.h>
#import <X11/cursorfont.h>
#import <XWindowServerKit/XFunctions.h>

/* Client has to reponse in this seconds. Otherwise, it counts as busy */
#define DELAY_SECONDS 10  

static Busy *sharedInstance;

@interface GSDisplayServer (AZPrivate) 	 
 - (void) processEvent: (XEvent *) event; 	 
@end

@interface Busy (Private)
- (void) updateClientList: (id) sender;
@end

@implementation Busy

/* Private */
- (BOOL) supportPing: (Window) win
{
	BOOL supporting = NO;
	Atom *protocols = NULL;
	unsigned long count;
	int i;

	Atom type_ret;
	int format_ret;
	unsigned long after_ret;
	int result = XGetWindowProperty(dpy, win, X_WM_PROTOCOLS,
                                    0, 0x7FFFFFFF, False, XA_ATOM,
                                    &type_ret, &format_ret, &count,
                                    &after_ret, (unsigned char **)&protocols);
	if ((result != Success) || (count < 1) || (protocols == NULL)) 
	{
		supporting = NO;
	}
	else
	{
		for (i = 0; i < count; i++)
		{
			if (protocols[i] == X_NET_WM_PING)
			{
				supporting = YES;
				break;
			}
		}
	}
	return supporting;
}


/* End of Private */
- (void) checkAlive: (id) sender
{
	NSLog(@"checkAlive");
	int i;
	NSArray *allClients = [clients allValues];
	for (i = 0; i < [allClients count]; i++)
	{
		AZClient *client = [allClients objectAtIndex: i];
		if ([client isSupportingPing] == NO)
			continue;
		if (([client counter] > 0) && ([client date] != nil) && ([NSDate timeIntervalSinceReferenceDate] - [[client date] timeIntervalSinceReferenceDate] > DELAY_SECONDS))
		{
			//Opacity from 0 (transparent) to 0xffffffff (opaque)
			unsigned int opacity = 0x60000000;
			NSLog(@"Client does not respond: %@", client);
			XDefineCursor(dpy, [client xwindow], busy_cursor);
			Window window = [client xwindow];
			while(window != 0)
			{
				XChangeProperty(dpy,
						window,
						X_NET_WM_WINDOW_OPACITY,
						XA_CARDINAL,
						32,
						PropModeReplace,
						(unsigned char*)&opacity,
						1L);
				Window parent;
				int format_ret;
				unsigned int num;
				Window *data = NULL;
				if (XQueryTree(dpy, window, (Window*)&format_ret, &parent, &data, (unsigned int*)&num) == False)
				{
					break;
				}
				if (data)
				{
					XFree(data);
					data = NULL;
				}
				window = parent;
			}
		}
//		NSLog(@"Check %@ %d", client, [client xwindow]);
		XClientMessageEvent *xev = calloc(1, sizeof(XClientMessageEvent));
		xev->type = ClientMessage; 
		xev->display = dpy;
		xev->window = [client xwindow];
		xev->message_type = X_WM_PROTOCOLS;
		xev->format = 32;
		xev->data.l[0] = X_NET_WM_PING;
		xev->data.l[1] = CurrentTime;
		xev->data.l[2] = [client xwindow];
		xev->data.l[3] = 0;
		xev->data.l[4] = 0;
		xev->data.l[5] = 0;
		XSendEvent(dpy, [client xwindow], False, NoEventMask, (XEvent *)xev);
		XFlush(dpy);
		XFree(xev);
		[client increaseCounter];
		if ([client date] == nil)
		{
			[client setDate: [NSDate date]];
		}
	}
}

- (void) updateClientList: (id) sender
{
	NSMutableDictionary *oldClients = nil;
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

	/* Let's stop timer before updating clients */
	if (checkTimer)
	{
		[checkTimer invalidate];
		DESTROY(checkTimer);
	}

	CREATE_AUTORELEASE_POOL(x);

	oldClients = [[NSMutableDictionary alloc] initWithDictionary: clients];
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

		/* Do we have the same window in old list ? */
		NSNumber *winID = [NSNumber numberWithInt: win[i]];
		AZClient *client = [oldClients objectForKey: winID];
		if (client == nil)
		{
			client = [[AZClient alloc] initWithXWindow: win[i]];
			[client setInstance: wm_instance];
			[client setClass: wm_class];
			[client setSupportingPing: [self supportPing: win[i]]];
			AUTORELEASE(client);
		}
		[clients setObject: client forKey: winID];
	}
	free(win);
	DESTROY(oldClients);
	DESTROY(x);

	if (checkTimer == nil)
	{
		ASSIGN(checkTimer, [NSTimer scheduledTimerWithTimeInterval: 600
		                            target: self
		                            selector: @selector(checkAlive:)
		                            userInfo: nil
		                            repeats: YES]);
		/* We check alive once before the timer kicks in */
		[self checkAlive: self];
	}
}

- (void) handleClientMessage: (XEvent *) event
{
//	NSLog(@"%@ %@", self, NSStringFromSelector(_cmd));
	Atom atom = event->xclient.data.l[0];
	if (atom == X_NET_WM_PING)
	{
		Window win = event->xclient.data.l[2];
		if (win)
		{
			AZClient *client = [clients objectForKey: [NSNumber numberWithInt: win]];
			if (client == nil)
			{
				NSLog(@"Internal Error: no client for %d", win);
			}
			if ([client counter] > 0)
			{
//				XDefineCursor(dpy, [client xwindow], pointer_cursor);
				XUndefineCursor(dpy, [client xwindow]);
				Window window = [client xwindow];
				while(window != 0)
				{
					XDeleteProperty(dpy, window, X_NET_WM_WINDOW_OPACITY);
					Window parent;
					int format_ret;
					unsigned int num;
					Window *data = NULL;
					if (XQueryTree(dpy, window, (Window*)&format_ret, &parent, &data, (unsigned int*)&num) == False)
					{
						break;
					}
					if (data)
					{
						XFree(data);
						data = NULL;
					}
					window = parent;
				}
				[client setCounter: 0]; // Reset counter
				[client setDate: nil];
			}
		}
	}
}

- (void) handlePropertyNotify: (XEvent *) event
{
// NSLog(@"%@ %@", self, NSStringFromSelector(_cmd));
	Window win = event->xproperty.window;  
	Atom atom = event->xproperty.atom;

	if (win == root_win)
	{
		if (atom == X_NET_CLIENT_LIST_STACKING) 
		{
//			NSLog(@"X_NET_CLIENT_LIST_STACKING");
			[self updateClientList: self];
		}
#if 0 // NOT_USED
		else if (atom == X_NET_WM_PING)
		{
			NSLog(@"Ping received");
		}
#endif
	}
}

- (void) handleXEvent
{
	XEvent event;
	while (XPending(dpy)) 
	{
		XNextEvent (dpy, &event);

		switch (event.type) 
		{
			case PropertyNotify:
				[self handlePropertyNotify: &event];
				break;
			case ClientMessage:
				[self handleClientMessage: &event];
				break;
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

- (void)receivedEvent:(void *)data
                 type:(RunLoopEventType)type
                extra:(void *)extra
              forMode:(NSString *)mode
{
	[self handleXEvent];
}

- (void) applicationWillFinishLaunching: (NSNotification *) not
{
	server = GSCurrentServer();
	dpy = (Display *)[server serverDevice];
	screen = [[NSScreen mainScreen] screenNumber];
	root_win = RootWindow(dpy, screen);

	/* Get key */
	//NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	clients = [[NSMutableDictionary alloc] init];

#if 1 // NOT_USED
	/* Listen event */
	NSRunLoop *loop = [NSRunLoop currentRunLoop];
	int xEventQueueFd = XConnectionNumber(dpy);

	[loop addEvent: (void*)(gsaddr)xEventQueueFd
	          type: ET_RDESC
	       watcher: (id<RunLoopEvents>)self
	       forMode: NSDefaultRunLoopMode];
#endif

	X_NET_CLIENT_LIST_STACKING = XInternAtom(dpy, "_NET_CLIENT_LIST_STACKING", False);
	X_NET_WM_STATE_SKIP_PAGER = XInternAtom(dpy, "_NET_WM_STATE_SKIP_PAGER", False);
	X_NET_WM_STATE_SKIP_TASKBAR = XInternAtom(dpy, "_NET_WM_STATE_SKIP_TASKBAR", False);
	X_NET_WM_WINDOW_OPACITY = XInternAtom(dpy, "_NET_WM_WINDOW_OPACITY", False);

	X_WM_PROTOCOLS = XInternAtom(dpy, "WM_PROTOCOLS", False);
	X_NET_WM_PING = XInternAtom(dpy, "_NET_WM_PING", False);

	busy_cursor = XCreateFontCursor(dpy, XC_watch);
	pointer_cursor = XCreateFontCursor(dpy, XC_left_ptr);

	/* Listen to root window*/
	XSelectInput(dpy, root_win, PropertyChangeMask|StructureNotifyMask|SubstructureNotifyMask);
//	XSelectInput(dpy, root_win, PropertyChangeMask);
}

- (void) applicationDidFinishLaunching: (NSNotification *) not
{
	[self updateClientList: self];
	[self handleXEvent];
}

- (void) applicationWillTerminate: (NSNotification *) not
{
}

- (void) dealloc
{
	if (checkTimer)
	{
		[checkTimer invalidate];
		DESTROY(checkTimer);
	}
	DESTROY(clients);
	[super dealloc];
}

+ (Busy *) busy 
{
	if (sharedInstance == nil)
		sharedInstance = [[Busy alloc] init];
	return sharedInstance;
}

@end

