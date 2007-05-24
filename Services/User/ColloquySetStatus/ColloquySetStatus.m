//
//  Test.m
//  distn
//
//  Created by David Chisnall on 20/05/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ColloquySetStatus.h"


@implementation ColloquySetStatus
- (void) statusChanged:(NSNotification*)aNotification
{
	NSString * message = [[aNotification userInfo] objectForKey:@"status"];
	unsigned char show = [[[aNotification userInfo] objectForKey:@"show"] unsignedCharValue];
	NSString * script = nil;
	/* Avoid duplicates */
	if(![lastStatus isEqualToString:message])
	{
		if(show > 20)
		{
			script = [NSString stringWithFormat:@"tell application \"Colloquy\" to repeat with con in every connection\nset away message of con to \"%@\"\nend repeat", message];
		}

		/* Log the last status */
		[lastStatus release];
		lastStatus = [message retain];
	}
	if(show < 30)
	{
			script = @"tell application \"Colloquy\" to repeat with con in every connection\nset away message of con to \"\"\nend repeat";
			[lastStatus release];
			lastStatus = nil;
	}
	[NSTask launchedTaskWithLaunchPath:@"/usr/bin/osascript"
							 arguments:[NSArray arrayWithObjects:
		@"-e",
		script,
		nil]];
	lastShow = show;
}
- (void) run
{
	/* Register for the notification */
	NSNotificationCenter * center = [NSDistributedNotificationCenter 
		defaultCenter];
	[center addObserver:self 
			   selector:@selector(statusChanged:) 
				   name:@"LocalPresenceChangedNotification" 
				 object:nil];
	/* Loop */
	NSRunLoop * loop = [NSRunLoop currentRunLoop];
	[loop run];
	NSLog(@"Exiting run loop...");
}
@end
