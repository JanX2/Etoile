/*  
 *  AZSwitch - A window switcher for GNUstep
 *  Copyright (C) 2007 Yen-Ju Chen 
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSDisplayServer.h>
#import <X11/Xlib.h>
#import "AZSwitchingWindow.h"

@interface AZSwitch: NSObject
{
	GSDisplayServer *server;
	Display *dpy;
	int screen;
	Window root_win;

	BOOL isSwitching;
	AZSwitchingWindow *window;

	KeyCode switchKey; /* Key to start expose */
	KeyCode modifierKey; /* Key to start expose */
	unsigned int mask; /* Must match modifier key */
#if 0
  Atom X_NET_CURRENT_DESKTOP;
  Atom X_NET_NUMBER_OF_DESKTOPS;
  Atom X_NET_DESKTOP_NAMES;
#endif
	Atom X_NET_CLIENT_LIST_STACKING;
	Atom X_NET_WM_STATE_SKIP_PAGER;
	Atom X_NET_WM_STATE_SKIP_TASKBAR;
	
	NSMutableArray *clients;
	NSMutableArray *blacklist;
}

+ (AZSwitch *) switch;

@end

