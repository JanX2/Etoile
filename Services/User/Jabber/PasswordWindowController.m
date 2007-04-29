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
//TODO: Move this into the framework in a nice PasswordManager class
//TODO: Change this to a NOKEYCHAIN macro not GNUSTEP.
#ifdef GNUSTEP
void setPasswordForAccount(NSString * password, JID * account)
{
	NSMutableDictionary * passwords = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"XMPPPasswords"]];
	if(passwords == nil)
	{
		passwords = [NSMutableDictionary dictionary];
	}
	[passwords setObject:password forKey:[account jidString]];
	[[NSUserDefaults standardUserDefaults] setObject:passwords
	                                          forKey:@"XMPPPasswords"];
}
#else
#include <Security/Security.h>
void setPasswordForAccount(NSString * password, JID * account)
{
	SecKeychainAddInternetPassword(NULL, 
								   [[account domain] length],
								   [[account domain] UTF8String],
								   0,
								   NULL,
								   [[account node] length],
								   [[account node] UTF8String],
								   0,
								   NULL,
								   5222,
								   kSecProtocolTypeTelnet, //This is wrong, but there seems to be no correct answer.
								   kSecAuthenticationTypeDefault,
								   [password length],
								   [password UTF8String],
								   NULL);
}
#endif

@implementation PasswordWindowController
- (id) initWithWindowNibName:(NSString*)windowNibName forJID:(JID*)_jid
{
	myJID = [_jid retain];
	return [self initWithWindowNibName:windowNibName];
}

- (void)windowDidLoad
{
	[question setStringValue:[NSString stringWithFormat:@"%@%@",
		[question stringValue],
		[myJID jidStringWithNoResource]]];	
}

- (void) yes:(id)sender
{
	NSString * password = [passwordBox stringValue];
	setPasswordForAccount(password, myJID);
	[[self window] close];
	[NSApp stopModalWithCode:0];
}
- (void) no:(id)sender
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
