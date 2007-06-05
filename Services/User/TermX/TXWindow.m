/*
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.
*/

#import "TXWindow.h"
#import "GNUstep.h"

@implementation TXWindow
- (void) setController: (id) c
{
	ASSIGN(controller, c);
}

- (id) controller
{
	return controller;
}

- (void) dealloc
{
	DESTROY(controller);
	[super dealloc];
}

@end
