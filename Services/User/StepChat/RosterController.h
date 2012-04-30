//
//  RosterController.h
//  Jabber
//
//  Created by David Chisnall on Mon Apr 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XMPPKit/XMPPRoster.h>
#import <XMPPKit/XMPPAccount.h>
#import <XMPPKit/XMPPPresence.h>

@interface RosterController : NSWindowController <RosterDelegate, XMPPPresenceDisplay> {
	unsigned char presence;
	XMPPRoster * roster;
	XMPPAccount * account;
	__unsafe_unretained IBOutlet NSOutlineView * view;
	__unsafe_unretained IBOutlet NSTableColumn * avatarColumn;
	__unsafe_unretained IBOutlet NSTableColumn * column;
	__unsafe_unretained IBOutlet NSPopUpButton * presenceBox;
	__unsafe_unretained IBOutlet NSTextField * statusBox;
}
- (id) initWithNibName:(NSString*)_nib forAccount:(id)_account withRoster:(id)_roster;
- (void) updatePresence:(NSNotification*)_notification;
- (IBAction) click:(id)sender;
- (IBAction) changePresence:(id)sender;
- (IBAction) remove:(id)sender;
- (NSString*) currentStatusMessage;
@end
