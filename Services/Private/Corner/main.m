#include <stdio.h>
#include <unistd.h>
#import <Foundation/Foundation.h>
#import <Corner.h>

/* Number of seconds in a minute.  Change to small values while testing so that
 * you don't need to wait for ages for the notification to fire */
#define SECONDS_PER_MINUTE 60
/**
 * Small application that implements hot corners.
 */
int main(void)
{
	/* Set up an autorelease pool that is never destroyed. */
	[[NSAutoreleasePool alloc] init];
	/* Creates its own runloop */
	[[Corner alloc] init];
}
