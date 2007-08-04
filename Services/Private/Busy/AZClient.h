/*
 *  Busy
 *  Copyright (C) 2007 Yen-Ju Chen
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import <AppKit/AppKit.h>
#import <X11/Xlib.h>

@interface AZClient: NSObject
{
	Window xwindow;
	NSString *instance; /* name */
	NSString *class; /* group */
	BOOL supportingPing;
	int counter;
}

- (id) initWithXWindow: (Window) window;
- (Window) xwindow;

- (void) setInstance: (NSString *) instance;
- (void) setClass: (NSString *) class;

- (void) setSupportingPing: (BOOL) b;
- (BOOL) isSupportingPing;

- (void) setCounter: (int) count;
- (int) counter;
- (void) increaseCounter;
- (void) decreaseCounter;

@end

