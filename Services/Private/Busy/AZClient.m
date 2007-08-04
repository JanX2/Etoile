/*
 *  Busy
 *  Copyright (C) 2007 Yen-Ju Chen
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import "AZClient.h"
#import <XWindowServerKit/XFunctions.h>

@implementation AZClient
- (id) initWithXWindow: (Window) win
{
	self = [super init];
	xwindow = win;
	supportingPing = NO;
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (Window) xwindow
{
	return xwindow;
}

- (void) setInstance: (NSString *) i
{
	ASSIGN(instance, i);
}

- (void) setClass: (NSString *) c
{
	ASSIGN(class, c);
}

- (void) setSupportingPing: (BOOL) b
{
	supportingPing = b;
}

- (BOOL) isSupportingPing
{
	return supportingPing;
}

- (void) setCounter: (int) count
{
	counter = count;
}

- (int) counter
{
	return counter;
}

- (void) increaseCounter
{
	counter++;
}

- (void) decreaseCounter
{
	counter--;
}

- (NSString *) description
{
	return [NSString stringWithFormat: @"%@.%@", instance, class];
}

@end

