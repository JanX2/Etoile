//
//  AccountWindowController.m
//  Jabber
//
//  Created by David Chisnall on 22/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AccountWindowController.h"
#import "JabberApp.h"

@implementation AccountWindowController
- (IBAction) yes:(id)sender
{
	JID * myJID = [JID jidWithString:[jidBox stringValue]];
	NSString * myServer = [serverBox stringValue];
	if(myServer != nil && ![myServer isEqualToString:@""])
	{
		[XMPPAccount setDefaultJID:myJID withServer:myServer];
	}
	else
	{
		[XMPPAccount setDefaultJID:myJID];
	}
	[[self window] close];
	[NSApp stopModalWithCode:0];
}
- (IBAction) no:(id)sender
{
	[[self window] close];
	[NSApp stopModalWithCode:-1];
}
@end
