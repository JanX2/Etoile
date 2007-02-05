//
//  AddContactWindowController.m
//  Jabber
//
//  Created by David Chisnall on 07/12/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AddContactWindowController.h"
#import "Roster.h"
#import "JabberApp.h"
#import "JID.h"

@implementation AddContactWindowController
- (IBAction) addPerson:(id)_sender
{
	NSString * rosterName = [name stringValue];
	NSString * rosterGroup = [group stringValue];
	JID * newJID = [JID jidWithString:[jid stringValue]];
	if([rosterName isEqualToString:@""])
	{
		return;
	}
	if(newJID == nil)
	{
		return;
	}
	[[[(JabberApp*)[NSApp delegate] account] roster] subscribe:newJID 
													  withName:rosterName
													   inGroup:rosterGroup];
	[[self window] performClose:self];
}

- (IBAction) cancel:(id)_sender
{
	[[self window] performClose:self];
}

- (IBAction) showWindow:(id)_sender
{
	[super showWindow:_sender];
}
@end
