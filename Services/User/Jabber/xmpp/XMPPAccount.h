//
//  XMPPAccount.h
//  Jabber
//
//  Created by David Chisnall on 21/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Roster.h"
#import "XMPPConnection.h"
#import "JID.h"

/**
 * The XMPPAccount class represents a single XMPP account.  The JID is retrieved
 * from the address book, and the password from the keychain (OS X) or user 
 * defaults (GNUstep).
 */
@interface XMPPAccount : NSObject {
	NSString * name;
	JID * myJID;
	Roster * roster;
	XMPPConnection * connection;
}
/**
 * Attempt to reconnect after disconnection.
 */
- (void) reconnect;
/**
 * Returns the JID associated with the account.
 */
- (JID*) jid;
/**
 * Returns the roster associated with the account.
 */
- (Roster*) roster;
/**
 * Returns the connection associated with the account.
 */
- (XMPPConnection*) connection;
@end
