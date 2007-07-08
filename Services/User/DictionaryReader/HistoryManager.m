/*  -*-objc-*-
 *
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import "HistoryManager.h"
#import "GNUstep.h"

@implementation HistoryManager

- (id) init 
{
	self = [super init];
	listenMode = YES;
	currentLocationIndex = -1;
	ASSIGN(history, [NSMutableArray arrayWithCapacity: 20]);
	return self;
}

- (void) dealloc
{
	DESTROY(_delegate);
	DESTROY(history);
	[super dealloc];
}

- (void) setDelegate: (id) aDelegate 
{
	ASSIGN( _delegate, aDelegate );
}

- (id) delegate 
{
	return _delegate;
}

- (void) browseBack 
{
	[self browseToIndex: currentLocationIndex-1];
}

- (void) browseForward 
{
	[self browseToIndex: currentLocationIndex+1];
}

- (void) browseToIndex: (int) aNewIndex 
{
	if (listenMode == YES) 
	{
		listenMode = NO;
    
		if ([self canBrowseTo: aNewIndex] &&
		    [_delegate respondsToSelector: @selector(historyManager:needsBrowseTo:)])
		{
			// remember where we will go
			futureLocationIndex = aNewIndex;
			// try to browse there
			[_delegate historyManager: self
			            needsBrowseTo: [history objectAtIndex: aNewIndex]];
		}
		listenMode = YES;
	} 
	else 
	{ // listenMode == NO
		NSLog(@"Can't go back in go-back mode.");
	}
}


- (BOOL) canBrowseTo: (int) aNewIndex 
{
	return ((([history count] > aNewIndex) && (aNewIndex > -1)) ? YES : NO);
}

- (BOOL) canBrowseBack 
{
	return [self canBrowseTo: currentLocationIndex-1];
}

- (BOOL) canBrowseForward 
{
	return [self canBrowseTo: currentLocationIndex+1];
}

- (void) browser: (id) aBrowser didBrowseTo: (id) aBrowsingLocation 
{
	// When not in listen mode, we probably sent this browsing
	// request ourselves.
	if (listenMode == NO) 
	{
		// set the currentLocation to where we are supposed to go
		currentLocationIndex = futureLocationIndex;
		return;
	}

	NSRange range = NSMakeRange(currentLocationIndex+1,[history count]);
	range.length -= range.location;
	[history removeObjectsInRange: range];
	[history addObject: aBrowsingLocation];
  
	currentLocationIndex++;
}

@end


