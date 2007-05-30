/*
 *  AZSwitch - A window switcher for GNUstep
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
}

- (id) initWithXWindow: (Window) window;
- (void) setInstance: (NSString *) instance;
- (void) setClass: (NSString *) class;

- (NSString *) title;
- (NSImage *) icon;

- (void) show: (id) sender; /* Show in front */

@end

