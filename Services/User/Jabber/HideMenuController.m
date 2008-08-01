//
//  HideMenuController.m
//  Jabber
//
//  Created by David Chisnall on 09/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <XMPPKit/Presence.h>
#import <XMPPKit/Roster.h>
#import "HideMenuController.h"
#import "TRUserDefaults.h"
#import "JabberApp.h"
#import "RosterController.h"

//TODO: Get rid of all of these messy [NSApp delegate] things.  

@implementation HideMenuController
- (IBAction) away:(id) sender
{
	[current setState:NSOffState];
	[sender setState:NSOnState];
	current = sender;
	[[NSUserDefaults standardUserDefaults] setPresence:PRESENCE_AWAY forKey:@"HiddenPresences"];
	[(RosterController*)[[[(JabberApp*)[NSApp delegate] account] roster] delegate] update:nil];
}
- (IBAction) xa:(id) sender
{
	[current setState:NSOffState];
	[sender setState:NSOnState];
	current = sender;
	[[NSUserDefaults standardUserDefaults] setPresence:PRESENCE_XA forKey:@"HiddenPresences"];
	[(RosterController*)[[[(JabberApp*)[NSApp delegate] account] roster] delegate] update:nil];
}
- (IBAction) dnd:(id) sender
{
	[current setState:NSOffState];
	[sender setState:NSOnState];
	current = sender;
	[[NSUserDefaults standardUserDefaults] setPresence:PRESENCE_DND forKey:@"HiddenPresences"];
	[(RosterController*)[[[(JabberApp*)[NSApp delegate] account] roster] delegate] update:nil];
}
- (IBAction) offline:(id) sender
{
	[current setState:NSOffState];
	[sender setState:NSOnState];
	current = sender;
	[[NSUserDefaults standardUserDefaults] setPresence:PRESENCE_OFFLINE forKey:@"HiddenPresences"];
	[(RosterController*)[[[(JabberApp*)[NSApp delegate] account] roster] delegate] update:nil];
}
- (IBAction) none:(id) sender
{
	[current setState:NSOffState];
	[sender setState:NSOnState];
	current = sender;
	[[NSUserDefaults standardUserDefaults] setPresence:PRESENCE_UNKNOWN + 10 forKey:@"HiddenPresences"];
	[(RosterController*)[[[(JabberApp*)[NSApp delegate] account] roster] delegate] update:nil];
}
@end
