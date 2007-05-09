/*
	Controller.h

	Media player main controller class.

	Copyright (C) 2006 Yen-Ju Chen.
	
	Authors:  Yen-Ju Chen <yjchenx gmail>
	Date:  2006

	This program is free software; you can redistribute it and/or modify
	it under the terms of the MIT license. See COPYING.

 */

#import <AppKit/AppKit.h>

@interface Controller : NSObject
{
	NSMutableArray *players;
}

- (void) openFile: (id)sender;
- (void) openStream: (id)sender;

@end

