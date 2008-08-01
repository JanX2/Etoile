//
//  RosterController.h
//  Jabber
//
//  Created by David Chisnall on Mon Apr 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XMPPKit/Roster.h>
#import <XMPPKit/XMPPAccount.h>
#import <XMPPKit/Presence.h>

@interface RosterController : NSWindowController <RosterDelegate, XMPPPresenceDisplay> {
	unsigned char presence;
	Roster * roster;
	XMPPAccount * account;
	IBOutlet NSOutlineView * view;
	IBOutlet NSTableColumn * avatarColumn;
	IBOutlet NSTableColumn * column;
	IBOutlet NSPopUpButton * presenceBox;
	IBOutlet NSTextField * statusBox;
}
- (id) initWithNibName:(NSString*)_nib forAccount:(id)_account withRoster:(id)_roster;
- (void) updatePresence:(NSNotification*)_notification;
- (IBAction) click:(id)sender;
- (IBAction) changePresence:(id)sender;
- (IBAction) remove:(id)sender;
- (NSString*) currentStatusMessage;
@end
