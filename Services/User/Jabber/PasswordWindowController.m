//
//  PasswordWindowController.m
//  Jabber
//
//  Created by David Chisnall on 22/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "PasswordWindowController.h"
#import "JabberApp.h"
//Keychain OS X only at the moment
#ifndef GNUSTEP
#include <Security/Security.h>
#endif

@implementation PasswordWindowController
- (id) initWithWindowNibName:(NSString*)windowNibName forJID:(JID*)_jid
{
	myJID = [_jid retain];
	return [self initWithWindowNibName:windowNibName];
}

- (void)windowDidLoad
{
	[yes setAction:@selector(yes)];
	[no setAction:@selector(no)];
	[yes setTarget:self];
	[no setTarget:self];

	[question setStringValue:[NSString stringWithFormat:@"%@%@",
		[question stringValue],
		[myJID jidStringWithNoResource]]];
	
}

- (void) yes
{
	NSString * password = [passwordBox stringValue];
	SecKeychainAddInternetPassword(NULL, 
								   [[myJID domain] length],
								   [[myJID domain] UTF8String],
								   0,
								   NULL,
								   [[myJID node] length],
								   [[myJID node] UTF8String],
								   0,
								   NULL,
								   5222,
								   kSecProtocolTypeTelnet, //This is wrong, but there seems to be no correct answer.
								   kSecAuthenticationTypeDefault,
								   [password length],
								   [password UTF8String],
								   NULL);
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
	[myJID release];
	[super dealloc];
}
@end
