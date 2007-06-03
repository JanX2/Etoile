/*
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <AppKit/AppKit.h>

@class TerminalController;

@interface AppController: NSObject
{
	NSMutableArray *terminalControllers;
}

- (IBAction) newTerminal: (id) sender;

@end

