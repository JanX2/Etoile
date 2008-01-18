#include <stdio.h>
#import <Foundation/Foundation.h>
#import "StatusAtom.h"

char * publish = NULL;

int main(int argc, char *argv[])
{
	[[NSAutoreleasePool alloc] init];
	if(argc > 1)
	{
		publish = argv[1];
	}
	id blogger = [[StatusAtom alloc] init];
	[blogger setFile:[NSFileHandle fileHandleForUpdatingAtPath:@"mublog.entries"]];
	NSNotificationCenter * center = [NSDistributedNotificationCenter
		defaultCenter];
	[center addObserver:blogger
			   selector:@selector(statusChanged:)
				   name:@"LocalPresenceChangedNotification"
				 object:nil];
	NSRunLoop * loop = [NSRunLoop currentRunLoop];
	[loop run];

	return 0;
}
