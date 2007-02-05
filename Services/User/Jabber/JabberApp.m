//
//  JabberApp.m
//  Jabber
//
//  Created by David Chisnall on Mon Apr 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "JabberApp.h"
#import "PasswordWindowController.h"

@implementation JabberApp

- (void) test:(id)timer
{
	NSLog(@"Idle timer fired");
}
- (NSTextView*) xmlLogBox
{
	return xmlLogBox;
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	//TODO: Make this a user defaults thing.
#ifdef NDEBUG
	[[debugMenu menu] removeItem:debugMenu];
#endif
	account = [[XMPPAccount alloc] init];
	rosterWindow = [[RosterController alloc] initWithNibName:@"RosterWindow"
												  forAccount:account
												  withRoster:[account roster]];
	[[account roster] setDelegate:rosterWindow];
	[[account connection] setPresenceDisplay:rosterWindow];
	[rosterWindow showWindow:self];
}

- (id) init
{
	return [super init];
}

- (void) reconnect
{
	account = [[XMPPAccount alloc] init];
}

- (void) redrawRosters
{
	[rosterWindow update:nil];
}

- (void) setPresence:(unsigned char)_presence withMessage:(NSString*)_message
{
	if(_presence == PRESENCE_OFFLINE)
	{
		[[account connection] disconnect];
		[[account roster] offline];
		[rosterWindow update:nil];
	}
	else
	{
		if([[account connection] connected] == loggedIn)
		{
			[[account connection] setStatus:_presence withMessage:_message];
		}
		else
		{
			[[account roster] setInitialStatus:_presence withMessage:_message];
			if([[account connection] connected] == offline)
			{	
				[account reconnect];
			}
		}
	}
}

- (void) connectionFailed:(XMPPAccount*)_account
{
	PasswordWindowController * passwordWindow = [[PasswordWindowController alloc] initWithWindowNibName:@"PasswordBox" forJID:[_account jid]];
	if([NSApp runModalForWindow:[passwordWindow window]] == 0)
	{
		[_account release];
		account = [[XMPPAccount alloc] init];
	}
	else
	{
		[_account release];
	}
}

- (IBAction) showRosterWindow:(id)_sender
{
	[rosterWindow showWindow:_sender];
}

- (void) setCustomPresence:(id) sender
{
	[customPresenceWindow showWindow:sender];
}

- (XMPPAccount*) account
{
	return account;
}

- (void) dealloc
{
	[account release];
	[super dealloc];
}
@end
