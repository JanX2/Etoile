//
//  TRIdleTimer.h
//  Jabber
//
//  Created by David Chisnall on 09/01/2005.
//  Copyright 2005 David Chisnall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#ifdef MACOSX
#include <Carbon/Carbon.h>
#include <time.h>
#endif

@interface TRIdleTimer : NSObject {
	BOOL isValid;
	NSTimeInterval interval;
	NSInvocation * idle;
	NSInvocation * unidle;
#ifdef MACOSX
	EventLoopTimerRef timer;
	EventHandlerRef keyHandler;
	EventHandlerRef mouseHandler;
	time_t lastEvent;
	BOOL fired;
#endif
}
+ (TRIdleTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)seconds 
									 idleTarget:(id)idleTarget
								   idleSelector:(SEL)idleSelector
								   unidleTarget:(id)unidleTarget
								 unidleSelector:(SEL)unidleSelector;
- (id)initWithFireInterval:(NSTimeInterval)seconds
				idleTarget:(id)idleTarget
			  idleSelector:(SEL)idleSelector
			  unidleTarget:(id)unidleTarget
			unidleSelector:(SEL)unidleSelector;
- (void) fireIdleAction;
- (void) fireUnidleAction;
- (void)invalidate;
- (BOOL)isValid;
- (void)setInterval:(NSTimeInterval)seconds;
- (NSTimeInterval)timeInterval;
#ifdef MACOSX
- (void) idling;
#endif
@end
