/*
 *  AZSwitch - A window switcher for GNUstep
 *  Copyright (C) 2007 Yen-Ju Chen
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import "AZClient.h"
#import <XWindowServerKit/XFunctions.h>

@implementation AZClient
- (void) show: (id) sender
{
	unsigned long s = XWindowState(xwindow);
	if (s == -1) 
	{
	} 
#if 0
	else if (s == IconicState) 
	{
		/* Iconified */
		XMapWindow(dpy, w);
	} 
#endif
	else 
	{
		//XRaiseWindow(dpy, w); // Not handled by OpenBox anymore
		XWindowSetActiveWindow(xwindow, None);
	}
}

- (NSString *) title
{
	return XWindowTitle(xwindow);
}

- (NSImage *) icon
{
	return XWindowIcon(xwindow);
}

- (id) initWithXWindow: (Window) win
{
	self = [super init];
	xwindow = win;
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (void) setInstance: (NSString *) i
{
	ASSIGN(instance, i);
}

- (void) setClass: (NSString *) c
{
	ASSIGN(class, c);
}

- (NSString *) description
{
	return [NSString stringWithFormat: @"%@.%@", instance, class];
}

@end

