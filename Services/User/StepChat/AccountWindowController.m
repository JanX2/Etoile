//
//  AccountWindowController.m
//  Jabber
//
//  Created by David Chisnall on 22/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AccountWindowController.h"
#import <XMPPKit/XMPPAccount.h>

@implementation AccountWindowController

- (IBAction) yes:(id)sender
{
	JID *myJID = [JID jidWithString:[jidBox stringValue]];
	NSString * myServer = [serverBox stringValue];
	SCAccountInfoManager *manager;
        
	if(myServer != nil && ![myServer isEqualToString:@""])
	{
		[XMPPAccount setDefaultJID:myJID withServer:myServer];
		manager = [[SCAccountInfoManager alloc] init];
		NSString *newJid = [manager composeNewJIDWithOldJID:myJID
                                                 withServer:myServer];
		JID *newJID = [JID jidWithString:newJid];
		[manager writeJIDToFile:newJID atPath:[manager filePath]];
	}
	else
	{
		[XMPPAccount setDefaultJID:myJID];
		manager = [[SCAccountInfoManager alloc] init];
		[manager writeJIDToFile:myJID atPath:[manager filePath]];
	}
	[[self window] close];
	[NSApp stopModalWithCode:0];
}
- (IBAction) no:(id)sender
{
	[[self window] close];
	[NSApp stopModalWithCode:-1];
	exit(0);  //Slex: with NSAPP -terminate the App did close but did stay still in memory
}
@end
