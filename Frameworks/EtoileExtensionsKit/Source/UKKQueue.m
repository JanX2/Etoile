/* =============================================================================
	FILE:		UKKQueue.m
	PROJECT:	Filie
    
    COPYRIGHT:  (c) 2003 M. Uli Kusterer, all rights reserved.
    
	AUTHORS:	M. Uli Kusterer - UK
    
    LICENSES:   GPL, Modified BSD

	REVISIONS:
		2003-12-21	UK	Created.
   ========================================================================== */

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import "UKKQueue.h"
#import "UKMainThreadProxy.h"
#import <unistd.h>
#import <fcntl.h>
#import <sys/time.h>


@implementation UKKQueue

// -----------------------------------------------------------------------------
//	* CONSTRUCTOR:
//		Creates a new KQueue and starts that thread we use for our
//		notifications.
//
//	REVISIONS:
//      2004-11-12  UK  Doesn't pass self as parameter to watcherThread anymore,
//                      because detachNewThreadSelector retains target and args,
//                      which would cause us to never be released.
//		2004-03-13	UK	Documented.
// -----------------------------------------------------------------------------

-(id)   init
{
	self = [super init];
	if( self )
	{
		queueFD = kqueue();
		if( queueFD == -1 )
		{
			[self release];
			return nil;
		}
		
		watchedPaths = [[NSMutableArray alloc] init];
		watchedFDs = [[NSMutableArray alloc] init];
		
		// Start new thread that fetches and processes our events:
		[NSThread detachNewThreadSelector:@selector(watcherThread:) toTarget:self withObject:nil];
	}
	
	return self;
}


// -----------------------------------------------------------------------------
//	release:
//		Since NSThread retains its target, we need this method to terminate the
//      thread when we reach a retain-count of two. The thread is terminated by
//      getting rid of the kqueue and setting queueFD to -1.
//
//	REVISIONS:
//		2004-11-12	UK	Created.
// -----------------------------------------------------------------------------

-(oneway void) release
{
    // FIXME: @synchronized
	//@synchronized(self)
    //{
        //NSLog(@"%@ (%d)", self, [self retainCount]);
        if( [self retainCount] == 2 && queueFD != -1 )
        {
            int q = queueFD;
            queueFD = -1;
            if( close( q ) == -1 )
                NSLog(@"release: Couldn't close main kqueue (%d)", errno);
        }
    //}
    
    [super release];
}
    
// -----------------------------------------------------------------------------
//	* DESTRUCTOR:
//		Releases the kqueue again.
//
//	REVISIONS:
//		2004-03-13	UK	Documented.
// -----------------------------------------------------------------------------

-(void) dealloc
{
	delegate = nil;
	[delegateProxy release];
	
	// Close all our file descriptors so the files can be deleted:
	NSEnumerator*	enny = [watchedFDs objectEnumerator];
	NSNumber*		fdNum;
	while( (fdNum = [enny nextObject]) )
	{
    	if( close( [fdNum intValue] ) == -1 )
            NSLog(@"dealloc: Couldn't close file descriptor (%d)", errno);

    }
	
	if( queueFD != -1 )
	{
		int		oldKQ = queueFD;
		queueFD = -1;
        if( close( oldKQ ) == -1 )
            NSLog(@"dealloc: Couldn't close main kqueue (%d)", errno);
	}
	
	[watchedPaths release];
	watchedPaths = nil;
	[watchedFDs release];
	watchedFDs = nil;
	
	[super dealloc];
    
    //NSLog(@"kqueue released.");
}


// -----------------------------------------------------------------------------
//	queueFD:
//		Returns a Unix file descriptor for the KQueue this uses. The descriptor
//		is owned by this object. Do not close it!
//
//	REVISIONS:
//		2004-03-13	UK	Documented.
// -----------------------------------------------------------------------------

-(int)  queueFD
{
	return queueFD;
}


// -----------------------------------------------------------------------------
//	addPathToQueue:
//		Tell this queue to listen for all interesting notifications sent for
//		the object at the specified path. If you want more control, use the
//		addPathToQueue:notifyingAbout: variant instead.
//
//	REVISIONS:
//		2004-03-13	UK	Documented.
// -----------------------------------------------------------------------------

-(void) addPathToQueue: (NSString*)path
{
	[self addPathToQueue: path notifyingAbout: UKKQueueNotifyAboutRename
												| UKKQueueNotifyAboutWrite
												| UKKQueueNotifyAboutDelete
												| UKKQueueNotifyAboutAttributeChange];
}


// -----------------------------------------------------------------------------
//	addPathToQueue:notfyingAbout:
//		Tell this queue to listen for the specified notifications sent for
//		the object at the specified path.
//
//	REVISIONS:
//		2004-03-13	UK	Documented.
// -----------------------------------------------------------------------------

-(void) addPathToQueue: (NSString*)path notifyingAbout: (u_int)fflags
{
	struct timespec		nullts = { 0, 0 };
	struct kevent		ev;
	int					fd = open( [path fileSystemRepresentation], O_RDONLY, 0 );
	
    if( fd >= 0 )
    {
        EV_SET( &ev, fd, EVFILT_VNODE, 
				EV_ADD | EV_ENABLE | EV_CLEAR,
				fflags, 0, (void*)path );
		
		[watchedPaths addObject: path];
		[watchedFDs addObject: [NSNumber numberWithInt: fd]];
    }
	
	kevent( queueFD, &ev, 1, NULL, 0, &nullts );
}


// -----------------------------------------------------------------------------
//	removePathFromQueue:
//		Stop listening for changes to the specified path. This removes all
//		notifications. Use this to balance both addPathToQueue:notfyingAbout:
//		as well as addPathToQueue:.
//
//	REVISIONS:
//		2004-03-13	UK	Documented.
// -----------------------------------------------------------------------------

-(void) removePathFromQueue: (NSString*)path
{
	int		index = [watchedPaths indexOfObject: path];
	
	if( index == NSNotFound )
		return;
	
	int			fd = [[watchedFDs objectAtIndex: index] intValue];
	
	[watchedFDs removeObjectAtIndex: index];
	[watchedPaths removeObjectAtIndex: index];
	
	if( close( fd ) == -1 )
        NSLog(@"removePathFromQueue: Couldn't close file descriptor (%d)", errno);

}


// -----------------------------------------------------------------------------
//	watcherThread:
//		This method is called by our NSThread to loop and poll for any file
//		changes that our kqueue wants to tell us about. This sends separate
//		notifications for the different kinds of changes that can happen.
//		All messages are sent via the postNotification:forFile: main bottleneck.
//
//		This also calls sharedWorkspace's noteFileSystemChanged.
//
//      To terminate this method (and its thread), set kqueueFD to -1.
//
//	REVISIONS:
//		2004-11-12	UK	Fixed docs to include termination criterion, added
//                      timeout to make sure the bugger gets disposed.
//		2004-03-13	UK	Documented.
// -----------------------------------------------------------------------------

-(void)		watcherThread: (id)sender
{
	int					n;
    struct kevent		ev;
    struct timespec     timeout = { 5, 0 }; // 5 seconds timeout.
    
    while( queueFD != -1 )
    {
		NSAutoreleasePool*  pool = [[NSAutoreleasePool alloc] init];
		
		NS_DURING
			n = kevent( queueFD, NULL, 0, &ev, 1, &timeout );
			if( n > 0 )
			{
				if( ev.filter == EVFILT_VNODE )
				{
					if( ev.fflags )
					{
						NSString*		fpath = (NSString *)ev.udata;
						//NSLog(@"UKKQueue: Detected file change: %@", fpath);
						[[NSWorkspace sharedWorkspace] noteFileSystemChanged: fpath];
						
						if( (ev.fflags & NOTE_RENAME) == NOTE_RENAME )
							[self postNotification: UKKQueueFileRenamedNotification forFile: fpath];
						if( (ev.fflags & NOTE_WRITE) == NOTE_WRITE )
							[self postNotification: UKKQueueFileWrittenToNotification forFile: fpath];
						if( (ev.fflags & NOTE_DELETE) == NOTE_DELETE )
							[self postNotification: UKKQueueFileDeletedNotification forFile: fpath];
						if( (ev.fflags & NOTE_ATTRIB) == NOTE_ATTRIB )
							[self postNotification: UKKQueueFileAttributesChangedNotification forFile: fpath];
						if( (ev.fflags & NOTE_EXTEND) == NOTE_EXTEND )
							[self postNotification: UKKQueueFileSizeIncreasedNotification forFile: fpath];
						if( (ev.fflags & NOTE_LINK) == NOTE_LINK )
							[self postNotification: UKKQueueFileLinkCountChangedNotification forFile: fpath];
						if( (ev.fflags & NOTE_REVOKE) == NOTE_REVOKE )
							[self postNotification: UKKQueueFileAccessRevocationNotification forFile: fpath];
					}
				}
			}
		NS_HANDLER
			NSLog(@"Error in UKKQueue watcherThread: %@",localException);
		NS_ENDHANDLER
		
		[pool release];
    }
    
    //NSLog(@"exiting kqueue watcher thread.");
}


// -----------------------------------------------------------------------------
//	postNotification:forFile:
//		This is the main bottleneck for posting notifications. If you don't want
//		the notifications to go through NSWorkspace, override this method and
//		send them elsewhere.
//
//	REVISIONS:
//		2004-10-31	UK	Helloween fun: Make this use a mainThreadProxy and
//						allow sending the notification even if we have a
//						delegate.
//		2004-03-13	UK	Documented.
// -----------------------------------------------------------------------------

-(void) postNotification: (NSString*)nm forFile: (NSString*)fp
{
	if( delegateProxy )
		[delegateProxy kqueue: self receivedNotification: nm forFile: fp];
	
	if( !delegateProxy || alwaysNotify )
		[[[NSWorkspace sharedWorkspace] notificationCenter] postNotificationName: nm object: fp];
	//NSLog(@"Notification: %@ (%@)", nm, fp);
}

-(id)	delegate
{
    return delegate;
}

-(void)	setDelegate: (id)newDelegate
{
	id	oldProxy = delegateProxy;
	delegate = newDelegate;
	delegateProxy = [delegate copyMainThreadProxy];
	[oldProxy release];
}

// -----------------------------------------------------------------------------
//	Flag to send a notification even if we have a delegate:
// -----------------------------------------------------------------------------

-(BOOL)	alwaysNotify
{
	return alwaysNotify;
}


-(void)	setAlwaysNotify: (BOOL)n
{
	alwaysNotify = n;
}


// -----------------------------------------------------------------------------
//	description:
//		This method can be used to help in debugging. It provides the value
//      used by NSLog & co. when you request to print this object using the
//      %@ format specifier.
//
//	REVISIONS:
//		2004-11-12	UK	Created.
// -----------------------------------------------------------------------------

-(NSString*)	description
{
	return [NSString stringWithFormat: @"%@ { watchedPaths = %@, alwaysNotify = %@ }", NSStringFromClass([self class]), watchedPaths, (alwaysNotify? @"YES" : @"NO") ];
}



@end
