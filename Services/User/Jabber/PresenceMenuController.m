//
//  PresenceMenuController.m
//  Jabber
//
//  Created by David Chisnall on 09/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "PresenceMenuController.h"
#import "Presence.h"
#import "JabberApp.h"
#import "CustomPresenceWindowController.h"

@implementation PresenceMenuController
#define SELECT_MENU_ITEM 	[current setState:NSOffState]; [sender setState:NSOnState]; current = sender;
- (IBAction) chat:(id) sender
{
	SELECT_MENU_ITEM;
	[(JabberApp*)[NSApp delegate] setPresence:PRESENCE_CHAT withMessage:nil];
}
- (IBAction) online:(id) sender
{
	SELECT_MENU_ITEM;
	[(JabberApp*)[NSApp delegate] setPresence:PRESENCE_ONLINE withMessage:nil];
}
- (IBAction) away:(id) sender
{
	SELECT_MENU_ITEM;
	[(JabberApp*)[NSApp delegate] setPresence:PRESENCE_AWAY withMessage:nil];
}
- (IBAction) xa:(id) sender
{
	SELECT_MENU_ITEM;
	[(JabberApp*)[NSApp delegate] setPresence:PRESENCE_XA withMessage:nil];
}
- (IBAction) dnd:(id) sender
{
	SELECT_MENU_ITEM;
	[(JabberApp*)[NSApp delegate] setPresence:PRESENCE_DND withMessage:nil];
}
- (IBAction) offline:(id) sender
{
	SELECT_MENU_ITEM;
	[(JabberApp*)[NSApp delegate] setPresence:PRESENCE_OFFLINE withMessage:nil];
}
#undef SELECT_MENU_ITEM
@end
