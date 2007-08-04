/*  
 *  Busy
 *  Copyright (C) 2007 Yen-Ju Chen 
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSDisplayServer.h>
#import <X11/Xlib.h>

@interface Busy: NSObject
{
	GSDisplayServer *server;
	Display *dpy;
	int screen;
	Window root_win;

	Atom X_NET_CLIENT_LIST_STACKING;
	Atom X_NET_WM_STATE_SKIP_PAGER;
	Atom X_NET_WM_STATE_SKIP_TASKBAR;
	Atom X_WM_PROTOCOLS;
	Atom X_NET_WM_PING;

	Cursor busy_cursor;
	Cursor pointer_cursor;
	
	NSMutableDictionary *clients;
	NSTimer *checkTimer;
}

+ (Busy *) busy;

@end

