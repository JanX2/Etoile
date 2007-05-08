/*  -*-objc-*-
 *
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import <AppKit/AppKit.h>

// predeclaration
@class HistoryManager;

@protocol HistoryManagerDelegate <NSObject>
-(BOOL) historyManager: (HistoryManager*) aHistoryManager
	 needsBrowseTo: (id) aLocation;
@end

@interface HistoryManager : NSObject
{
@private
  id<HistoryManagerDelegate> _delegate;
  NSMutableArray* history;
  BOOL listenMode;
  unsigned currentLocationIndex;
  unsigned futureLocationIndex;
}

-(id)init;
-(void)setDelegate: (id<HistoryManagerDelegate>)aDelegate;
-(id<HistoryManagerDelegate>)delegate;

-(void) browseToIndex: (unsigned) aNewIndex;
-(void) browseBack;
-(void) browseForward;
-(BOOL) canBrowseTo: (unsigned) aNewIndex;
-(BOOL) canBrowseBack;
-(BOOL) canBrowseForward;

-(void) browser: (id)aBrowser
    didBrowseTo: (id)aBrowsingLocation;


@end


