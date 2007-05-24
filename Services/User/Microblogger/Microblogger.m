//
//  Microblogger.m
//  A microblogging tool that reads the presence from StepChat
//  and pushes it out to microblogging sites, like Jaiku.
//
//  Created by Jesse Ross on 20/05/2007.
//  Copyright 2007 Jesse Ross. All rights reserved.
//

#import "Microblogger.h"


@implementation Microblogger
- (void) statusChanged:(NSNotification*)aNotification
{
	NSString * message = [[aNotification userInfo] objectForKey:@"status"];
	NSString * script = nil;
	/* Avoid duplicates */
	if(![lastStatus isEqualToString:message])
	{
		/* Log the last status */
		[lastStatus release];
		lastStatus = [message retain];
		
		script = [NSString stringWithFormat:@"user=%@&personal_key=%@&method=presence.send&message=%@", 
					username, 
					password, 
					[message stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
	}

	[NSTask launchedTaskWithLaunchPath:@"/usr/bin/curl"
							 arguments:[NSArray arrayWithObjects:
		@"api.jaiku.com/json",
		@"-d",
		script,
		nil]];
}
- (void) runWithUsername:(NSString*)aUsername password:(NSString*)aPassword
{
	/* Set username and password */
	username = aUsername;
	password = aPassword;
	
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
