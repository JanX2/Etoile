//
//  JabberApp.h
//  Jabber
//
//  Created by David Chisnall on Mon Apr 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPAccount.h"
#import "PreferenceWindowController.h"
#import "RosterController.h"
#import "CustomPresenceWindowController.h"

@interface JabberApp : NSObject {
	XMPPAccount * account;
	RosterController * rosterWindow;
	IBOutlet CustomPresenceWindowController * customPresenceWindow;
	IBOutlet NSMenuItem * debugMenu;
	IBOutlet NSTextView * xmlLogBox;	
}
- (void) connectionFailed:(XMPPAccount*)_account;
- (void) reconnect;
- (void) redrawRosters;
- (void) setPresence:(unsigned char)_presence withMessage:(NSString*)_message;
- (void) setCustomPresence:(id) sender;
- (void) applicationDidFinishLaunching:(NSNotification *)aNotification;
- (XMPPAccount*) account;
- (IBAction) showRosterWindow:(id)_sender;
- (NSTextView*) xmlLogBox;
@end
