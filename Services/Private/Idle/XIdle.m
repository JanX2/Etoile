#include <stdio.h>
#include <X11/Xlib.h>
#include <X11/extensions/scrnsaver.h>
#include <unistd.h>
#import <Foundation/Foundation.h>

/* Number of seconds in a minute.  Change to small values while testing so that
 * you don't need to wait for ages for the notification to fire */
#define SECONDS_PER_MINUTE 60
/**
 * Small application that sends user-idle notifications every
 * minute that the user is idle.
 */
int main(void)
{
	/* Get X display and root window */
	Display *dpy = XOpenDisplay(NULL);
	Window root = DefaultRootWindow(dpy);
	XScreenSaverInfo *info = XScreenSaverAllocInfo();
	/* Set up an autorelease pool that is never destroyed. */
	[[NSAutoreleasePool alloc] init];
	/* Center to use for sending the distributed notifications */
	NSNotificationCenter* center = 
		[NSDistributedNotificationCenter defaultCenter];

	while(1)
	{
		/* Get idle time */
		XScreenSaverQueryInfo(dpy,root, info);
		unsigned int idleSeconds = info->idle / 1000;
		NSLog(@"Idle for %d seconds\n", idleSeconds);
		/* Send the notification if a fixed number of minutes have elapsed */
		if(idleSeconds >= SECONDS_PER_MINUTE)
		{
			/* Per-loop autorelease pool */
			NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
			/* Construct the notification */
			NSNumber * idleMinutes = 
				[NSNumber numberWithUnsignedInt:idleSeconds / SECONDS_PER_MINUTE];
			NSDictionary * userInfo = 
				[NSDictionary dictionaryWithObject:idleMinutes
				                            forKey:@"Minutes"];
			/* Send it */
			//NSLog(@"Sending notification with userinfo: %@", userInfo);
			[center postNotificationName:@"UserIdleNotification"
			                      object:@"EtoileIdleTimer"
			                    userInfo:userInfo];
			/* Clean up */
			[pool release];
		}
		/* Sleep until a complete minute will have elapsed */
		//NSLog(@"Sleeping for %d seconds",
		//SECONDS_PER_MINUTE - (idleSeconds % SECONDS_PER_MINUTE));
		sleep(SECONDS_PER_MINUTE - (idleSeconds % SECONDS_PER_MINUTE));
	}
}
