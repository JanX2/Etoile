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
		
		/* Construct the Jaiku API call */
		NSString * query = [NSString stringWithFormat:@"user=%@&personal_key=%@&method=presence.send&message=%@", 
			username, 
			password, 
			[message stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
		/* Send it. */
		[jaikuCall setHTTPBody:[query dataUsingEncoding:NSASCIIStringEncoding]];
		[[NSURLConnection alloc] initWithRequest:jaikuCall delegate:self];
	}

}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[connection release];
}
- (void) runWithUsername:(NSString*)aUsername password:(NSString*)aPassword
{
	/* Set username and password */
	username = [aUsername retain];
	password = [aPassword retain];
	
	/* Register for the notification */
	NSNotificationCenter * center = [NSDistributedNotificationCenter 
		defaultCenter];
	[center addObserver:self 
			   selector:@selector(statusChanged:) 
				   name:@"LocalPresenceChangedNotification" 
				 object:nil];
	/* Set up Jaiku Request */
	jaikuCall = [[NSMutableURLRequest alloc] init];
	[jaikuCall setURL:[NSURL URLWithString:@"http://api.jaiku.com/json"]];
	[jaikuCall setHTTPMethod:@"POST"];
	/* Loop */
	NSRunLoop * loop = [NSRunLoop currentRunLoop];
	[loop run];
	NSLog(@"Exiting run loop...");
}
@end
