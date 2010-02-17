//
//  XMPPAccount.h
//  Jabber
//
//  Created by David Chisnall on 21/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPConnection.h"
#import "JID.h"

#define XMPPNOJIDEXCEPTION @"NoJIDinAB"
#define XMPPNOPASSWORDEXCEPTION @"NoPasswordForJid"

@class Roster;

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
 * Sets the default JID (stored in address book)
 */
+ (void) setDefaultJID:(JID*) aJID;
/**
 * Sets the default JID along with a server to use for connection.
 */
+ (void) setDefaultJID:(JID*) aJID withServer:(NSString*) aServer;
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
/**
 * Returns the name of the current account.
 */
- (NSString*) name;
@end
