//
//  TRIdleTimer.m
//  Jabber
//
//  Created by David Chisnall on 09/01/2005.
//  Copyright 2005 David Chisnall. All rights reserved.
//
#import "TRIdleTimer.h"
#ifdef MACOSX

//Helper functions to handle Carbon (yuck) event callbacks
pascal void TRIdleTimer_OSXHelper(EventLoopTimerRef inTimer,
								  EventLoopIdleTimerMessage inState, 
								  void * inUserData);
OSStatus eventReceived(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData);
#endif


@implementation TRIdleTimer
+ (TRIdleTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)seconds 
									 idleTarget:(id)idleTarget
								   idleSelector:(SEL)idleSelector
								   unidleTarget:(id)unidleTarget
								 unidleSelector:(SEL)unidleSelector
{
	return [[[TRIdleTimer alloc] initWithFireInterval:seconds
										   idleTarget:(id)idleTarget
										 idleSelector:(SEL)idleSelector
										 unidleTarget:(id)unidleTarget
									   unidleSelector:(SEL)unidleSelector] autorelease];
}

- (id) init
{
	self = [super init];
	if(self == nil)
	{
		return nil;
	}
	fired = NO;
	return self;
}

- (id)initWithFireInterval:(NSTimeInterval)seconds
				idleTarget:(id)idleTarget
			  idleSelector:(SEL)idleSelector
			  unidleTarget:(id)unidleTarget
			unidleSelector:(SEL)unidleSelector
{
	self = [self init];
	if(self == nil)
	{
		return nil;
	}
	NSMethodSignature * signature;
	signature = [idleTarget methodSignatureForSelector:idleSelector];
	if([signature numberOfArguments] != 3)
	{
		[self release];
		return nil;
	}
	idle = [NSInvocation invocationWithMethodSignature:signature];

	signature = [unidleTarget methodSignatureForSelector:unidleSelector];
	if([signature numberOfArguments] != 3)
	{
		[self release];
		return nil;
	}
	unidle = [NSInvocation invocationWithMethodSignature:signature];
	
	[self retain];

	//Ensure that one reference to this timer is retained until it is invalidated
	[unidle setSelector:idleSelector];
	[idle setSelector:idleSelector];
	
	[unidle setTarget:unidleTarget];
	[idle setTarget:idleTarget];
	
	[unidle setArgument:self atIndex:2];
	[idle setArgument:self atIndex:2];
	
	[unidle retainArguments];
	[idle retainArguments];
	[unidle retain];
	[idle retain];
	
	interval = seconds;
#ifdef MACOSX
	if(InstallEventLoopIdleTimer(GetMainEventLoop(),
								 seconds * kEventDurationSecond,
								 seconds * kEventDurationSecond,
								 NewEventLoopIdleTimerUPP(TRIdleTimer_OSXHelper),
								 self,
								 &timer) != noErr)
	{
		[self release];
		return nil;
	}
	//Request notification when the app gains and loses active status
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(appDeactivate:)
												 name:@"NSApplicationDidResignActiveNotification"
											   object:NSApp];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(appActivate:)
												 name:@"NSApplicationWillBecomeActiveNotification"
											   object:NSApp];
	NSLog(@"Timer set");
#else
	//Null (absence of) implementation - never fires.  Add GNUstep/X11/whatever code here.
#endif
	return self;
}

- (void) appDeactivate:(id)sender
{
	 EventTypeSpec eventType;
	 eventType.eventClass = kEventClassKeyboard;
	 eventType.eventKind = kEventRawKeyDown;
	 if(InstallEventHandler(GetEventMonitorTarget(), 
							NewEventHandlerUPP(eventReceived), 
							1,
							&eventType,
							self,
							&keyHandler) != noErr)
	 {
	 }
	 eventType.eventClass = kEventClassMouse;
	 eventType.eventKind = kEventMouseMoved;
	 if(InstallEventHandler(GetEventMonitorTarget(), 
							NewEventHandlerUPP(eventReceived), 
							1,
							&eventType,
							self,
							&mouseHandler) != noErr)
	 {
		 //		[self release];
		 //		return nil;
	 }
	 
}

- (void) idling
{
	if(difftime(time(NULL), lastEvent) >= interval)
	{
		if(!fired)
		{
			[self fireIdleAction];
		}
		fired = YES;
	}
}

- (void)invalidate
{
	if(isValid)
	{
		[self release];
		isValid = NO;
#ifdef MACOSX
		RemoveEventHandler(keyHandler);
		RemoveEventHandler(mouseHandler);
		RemoveEventLoopTimer(timer);
#endif
	}
}

- (void) fireIdleAction
{
	[idle invoke];
}

- (void) fireUnidleAction
{
	lastEvent = time(NULL);
	if(fired)
	{
		fired = NO;
		[unidle invoke];
	}
}

- (BOOL)isValid
{
	return isValid;
}

- (void)setInterval:(NSTimeInterval)seconds
{
	interval = seconds;
#ifdef MACOSX
	RemoveEventLoopTimer(timer);
	InstallEventLoopIdleTimer(GetCurrentEventLoop(),
							  seconds * kEventDurationSecond,
							  seconds * kEventDurationSecond,
							  NewEventLoopIdleTimerUPP(TRIdleTimer_OSXHelper),
							  self,
							  &timer);
#endif
}
- (NSTimeInterval)timeInterval
{
	return interval;
}

- (void) dealloc
{
	[self invalidate];
	[idle release];
	[unidle release];
#ifdef MACOSX
	CFRelease(timer);
#endif	
}
@end

#ifdef MACOSX
pascal void TRIdleTimer_OSXHelper(EventLoopTimerRef inTimer,
								  EventLoopIdleTimerMessage inState, 
								  void * inUserData)
{
	TRIdleTimer * idleTimer = (TRIdleTimer*) inUserData;
	switch(inState)
	{
		case kEventLoopIdleTimerStarted:
			NSLog(@"App idling");
		case kEventLoopIdleTimerIdling:
			[idleTimer idling];
			break;
		case kEventLoopIdleTimerStopped:
			NSLog(@"App not idling");
			[idleTimer fireUnidleAction];
	}
}

OSStatus eventReceived(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) 
{
	NSLog(@"Event received!\n");
	[(TRIdleTimer*)userData fireUnidleAction];
	return noErr;
	return CallNextEventHandler(nextHandler, theEvent);
}
#endif