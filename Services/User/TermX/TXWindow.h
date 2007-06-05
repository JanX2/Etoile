/*
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.
*/

#import <AppKit/AppKit.h>

@interface TXWindow: NSWindow
{
	/* The purpose to have controller is that when window is released,
	   the controller will also released */
	id controller;
}

- (void) setController: (id) controller;
- (id) controller;

@end
