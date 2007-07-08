/*  -*-objc-*-
 *
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import <AppKit/AppKit.h>

@interface HistoryManager : NSObject
{
	@private
	id _delegate;
	NSMutableArray* history;
	BOOL listenMode;
	int currentLocationIndex;
	int futureLocationIndex;
}

- (void) setDelegate: (id) aDelegate;
- (id) delegate;

- (void) browseToIndex: (int) aNewIndex;
- (void) browseBack;
- (void) browseForward;
- (BOOL) canBrowseTo: (int) aNewIndex;
- (BOOL) canBrowseBack;
- (BOOL) canBrowseForward;

- (void) browser: (id) aBrowser didBrowseTo: (id) aBrowsingWord;

@end

/* Delegate should implement this one */
@interface NSObject (HistoryManagerDelegate)
- (BOOL) historyManager: (HistoryManager *) aHistoryManager
          needsBrowseTo: (id) word;
@end

