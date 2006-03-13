
/*
 **  ITSessionMgr.h
 **
 **  Copyright (c) 2002, 2003
 **
 **  Author: Fabian, Ujwal S. Setlur
 **	     Initial code by Kiichi Kusama
 **
 **  Project: iTerm
 **
 **  Description: manages an array of sessions.
 **
 **  This program is free software; you can redistribute it and/or modify
 **  it under the terms of the GNU General Public License as published by
 **  the Free Software Foundation; either version 2 of the License, or
 **  (at your option) any later version.
 **
 **  This program is distributed in the hope that it will be useful,
 **  but WITHOUT ANY WARRANTY; without even the implied warranty of
 **  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 **  GNU General Public License for more details.
 **
 **  You should have received a copy of the GNU General Public License
 **  along with this program; if not, write to the Free Software
 **  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#import <Foundation/Foundation.h>

@class PTYSession;

@interface ITSessionMgr : NSObject 
{
    NSMutableArray *_sessionList;
    int _currentSessionIndex;
    PTYSession *_currentSession;
    NSLock *_threadLock;
}

- (int)currentSessionIndex;
- (void)setCurrentSessionIndex:(int)index;

- (PTYSession *)currentSession;
- (void)setCurrentSession:(PTYSession *)session;

- (unsigned)numberOfSessions;
- (PTYSession*)sessionAtIndex:(unsigned)index;
- (BOOL)containsSession:(PTYSession *)session;

- (void)removeSession:(PTYSession*)session;
- (void)insertSession:(PTYSession*)session atIndex:(int)index;
- (void)replaceSessionAtIndex:(int)index withSession:(PTYSession*)session;

- (void) acquireLock;
- (void) releaseLock;

- (NSArray*)sessionList;

@end
