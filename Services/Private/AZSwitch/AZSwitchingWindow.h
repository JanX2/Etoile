/*
 *  AZSwitch - A window switcher for GNUstep
 *  Copyright (C) 2007 Yen-Ju Chen
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import <AppKit/AppKit.h>

@interface AZSwitchingWindow: NSWindow
{
	NSMatrix *matrix;
	NSArray *clients;
	int selectedIndex;
}

- (void) setClients: (NSArray *) clients;

- (void) next: (id) sender;
- (void) previous: (id) sender;

- (int) indexOfSelectedClient;

@end

