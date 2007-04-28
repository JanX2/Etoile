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

- (void)windowDidLoad
{
	[yes setAction:@selector(yes)];
	[no setAction:@selector(no)];
	[yes setTarget:self];
	[no setTarget:self];
	
}

- (void) yes
{
	JID * myJID = [[JID alloc] initWithString:[jidBox stringValue]];
	NSString * myServer = [serverBox stringValue];
	[XMPPAccount setDefaultJID:myJID withServer:myServer];
	[[self window] close];
	[NSApp stopModalWithCode:0];
}
- (void) no
{
	[[self window] close];
	[NSApp stopModalWithCode:-1];
}

- (void) dealloc
{
	[super dealloc];
}
@end
