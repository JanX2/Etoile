/* =============================================================================
    PROJECT:    Filie
    FILE:       UKMainThreadActionQueue.m
    
    COPYRIGHT:  (c) 2004 by M. Uli Kusterer, all rights reserved.
    
    AUTHORS:    M. Uli Kusterer - UK
    
    LICENSES:   GNU GPL, Modified BSD
    
    REVISIONS:
        2004-11-23  UK  Created.
   ========================================================================== */

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import "UKMainThreadActionQueue.h"
#include <unistd.h>


@implementation UKMainThreadActionQueue

// -----------------------------------------------------------------------------
//	initWithMessage:
//		Create a new queue and specify the message it will send to each object
//      in the queue.
//
//	REVISIONS:
//		2004-12-22	UK	Documented.
// -----------------------------------------------------------------------------

-(id)   initWithMessage: (SEL)msg
{
    self = [self init];
    if( !self )
        return nil;
    
    [self setMessage: msg];
    objectsToMessage = [[NSMutableArray alloc] init];
    [NSThread detachNewThreadSelector: @selector(sendMessages:) toTarget: self withObject: nil];
    newestFirst = YES;
    
    return self;
}

-(void)	dealloc
{
	[objectsToMessage release];
	[super dealloc];
}


// -----------------------------------------------------------------------------
//	release:
//		Since NSThread retains its target, we need this method to terminate the
//      thread when we reach a retain-count of two.
//
//	REVISIONS:
//		2004-11-12	UK	Created.
// -----------------------------------------------------------------------------

-(void) release
{
    if( [self retainCount] == 2 && threadRunning )
        threadRunning = NO;
    
    [super release];
}


// -----------------------------------------------------------------------------
//	addObject:
//		Append a new object to the queue.
//
//	REVISIONS:
//		2004-12-22	UK	Documented.
// -----------------------------------------------------------------------------

-(void) addObject: (id)obj
{
    @synchronized( self )
    {
        [objectsToMessage addObject: obj];
    }
}


// -----------------------------------------------------------------------------
//	setMessage:
//		Change the message to be sent to objects in the queue. This will also
//      change the message for all objects still in the queue.
//
//	REVISIONS:
//		2004-12-22	UK	Documented.
// -----------------------------------------------------------------------------

-(void) setMessage: (SEL)msg
{
    message = msg;
}


// -----------------------------------------------------------------------------
//	message:
//		Return the message that'll be sent to objects in the queue.
//
//	REVISIONS:
//		2004-12-22	UK	Documented.
// -----------------------------------------------------------------------------

-(SEL)  message
{
    return message;
}


// -----------------------------------------------------------------------------
//	sendMessages:
//		Thread action that keeps looping and processes the queue in batches.
//
//	REVISIONS:
//		2004-12-22	UK	Documented.
// -----------------------------------------------------------------------------

-(void)	sendMessages: (id)sender
{
    threadRunning = YES;
    
	while( threadRunning )
    {
        while( threadRunning && (!objectsToMessage || [objectsToMessage count] <= 0) )
        {
            usleep(1000);
        }
        
        NSAutoreleasePool*  pool = [[NSAutoreleasePool alloc] init];
        NSArray*    msgs = nil;
        
        @synchronized( self )
        {
            msgs = [objectsToMessage autorelease];
            objectsToMessage = [[NSMutableArray alloc] init];
        }
        
        NSEnumerator*   enny;
        if( newestFirst )
            enny = [msgs reverseObjectEnumerator];
        else
            enny = [msgs objectEnumerator];
        
        id      obj;
        int     x = 0;
        
        NSAutoreleasePool*  pool2 = [[NSAutoreleasePool alloc] init];
        
        while( (obj = [enny nextObject]) )
        {
            if( (x & 0x0000000F) == 0x0F )  // Release this every 16 items.
            {
                [pool2 release];
                pool2 = [[NSAutoreleasePool alloc] init];
            }
            NS_DURING
                //[obj performSelectorOnMainThread: message withObject: nil waitUntilDone: YES];    // Quick fix for Filie.
                [obj performSelector: message];
            NS_HANDLER
                NSLog(@"Exception during queued message '%@': %@", NSStringFromSelector(message),localException);
            NS_ENDHANDLER
            x++;
        }
        [pool2 release];
        [pool release];
    }
}


@end
