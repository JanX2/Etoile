//
//  JabberApp.h
//  Jabber
//
//  Created by David Chisnall on Mon Apr 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XMPPKit/XMPPAccount.h>
#import "PreferenceWindowController.h"
#import "RosterController.h"
#import "CustomPresenceWindowController.h"
#import "AccountWindowController.h"

@interface JabberApp : NSObject {
	XMPPAccount * account;
	RosterController * rosterWindow;
	IBOutlet CustomPresenceWindowController * customPresenceWindow;
	IBOutlet NSMenuItem * debugMenu;
	IBOutlet NSTextView * xmlLogBox;  
	AccountWindowController * accountWindow;      
}
- (void) reconnect;
- (void) redrawRosters;
- (void) setPresence:(unsigned char)_presence withMessage:(NSString*)_message;
- (void) setCustomPresence:(id) sender;
- (void) applicationDidFinishLaunching:(NSNotification *)aNotification;
- (XMPPAccount*) account;
- (IBAction) showRosterWindow:(id)_sender;
- (NSTextView*) xmlLogBox;
@end
