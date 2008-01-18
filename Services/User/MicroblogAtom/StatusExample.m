//
//  Test.m
//  distn
//
//  Created by David Chisnall on 20/05/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "StatusExample.h"


@implementation StatusExample
- (void) statusChanged:(NSNotification*)aNotification
{
	NSString * message = [[aNotification userInfo] objectForKey:@"status"];
	/* Avoid duplicates */
	if(![lastStatus isEqualToString:message])
	{
		//Replace this with code to push the presence
		NSLog(@"userInfo: %@", message);

		/* Log the last status */
		[lastStatus release];
		lastStatus = [message retain];
	}
}
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	NSNotificationCenter * center = [NSDistributedNotificationCenter 
		defaultCenter];
	[center addObserver:self 
			   selector:@selector(statusChanged:) 
				   name:@"LocalPresenceChangedNotification" 
				 object:nil];
}
@end
