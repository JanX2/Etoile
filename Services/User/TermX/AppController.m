/*
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import "AppController.h"
#import "TerminalController.h"
#import "GNUstep.h"

@implementation AppController
- (IBAction) newTerminal: (id) sender
{
	TerminalController *controller = [[TerminalController alloc] init];
	[controller showWindow: self];
	DESTROY(controller);
}

- (void) awakeFromNib
{
}

/* NSApplication */
- (void) applicationWillFinishLaunching: (NSNotification *) not
{
}

- (void) applicationDidFinishLaunching: (NSNotification *) not
{
	[self newTerminal: self];
}

- (NSApplicationTerminateReply) applicationShouldTerminate: (NSApplication *) app
{
	return NSTerminateNow;
}

- (id) init
{
	self = [super init];
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

@end

