//
//  presence.h
//  Jabber
//
//  Created by David Chisnall on Sun Apr 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ETXMLNode.h"
#import "ETXMLNullHandler.h"
#import "JID.h"

/**
 * Constant representing a 'free for chat' online state.
 */
#define PRESENCE_CHAT 10
/**
 * Constant representing an 'online' online state.
 */
#define PRESENCE_ONLINE 20
/**
 * Constant representing an 'away' online state.
 */
#define PRESENCE_AWAY 30
/**
 * Constant representing an 'extended away' online state.
 */
#define PRESENCE_XA 40
/**
 * Constant representing a 'do not disturb' online state.
 */
#define PRESENCE_DND 50
/**
 * Constant representing an 'offline' online state.
 */
#define PRESENCE_OFFLINE 60
/**
 * Constant representing an unknown online state.
 */
#define PRESENCE_UNKNOWN 70

/**
 * Unicode characters representing various online states
 */
extern int PRESENCE_ICONS[];

/**
 * Protocol implemented by any UI component with a presence display.  This should
 * probably be replaced with a notification based system.
 */
@protocol XMPPPresenceDisplay 
- (void) setPresence:(unsigned char)_status withMessage:(NSString*)_message;
@end

/**
 * Types of presence stanzas.  The first two represent normal presence information
 * while the last four relate to manipulation of the roster.
 */
typedef enum {online, unavailable, subscribe, unsubscribe, subscribed, unsubscribed} PresenceType;

/**
 * The Presence class represents an XMPP presence stanza.  Because the XMPP spec is
 * now horribly bloated, and the designers didn't think to include a more generic
 * broadcast stanza form, presence is now used for a lot more things than presence
 * information.
 */
@interface Presence : ETXMLNullHandler {
	JID * from;
	PresenceType type;
	unsigned char onlineStatus;
	NSString * message;
	NSString * nickname;
	NSString * caps;
	int priority;
}
/**
 * Returns the (currently English; should be internationalised) display string for
 * a given presence.  For example, will return @"Online" when passed 
 * PRESENCE_ONLINE.
 */
+ (NSString*) displayStringForPresence:(unsigned char)_presence;
/**
 * Returns the string used by XMPP to represent a given online state.
 */
+ (NSString*) xmppStringForPresence:(unsigned char)_presence;
/**
 * Returns the online state represented by a given XMPP string.
 */
+ (unsigned char) presenceForXMPPString:(NSString*)_presence;
/**
 * Create a new presence stanza for a specified JID.
 */
- (id) initWithJID:(JID*)_jid;
/**
 * Returns the online status.  These are symbolic constants and are ordered such 
 * that A being less than B means A is more online than B.
 */
- (unsigned char) show;
/**
 * Returns the status message.
 */
- (NSString*) status;
/**
 * Returns the preferred nickname set by the remote user.
 */
- (NSString*) nickname;
/**
 * Returns the priority set for the stanza.
 */
- (int) priority;
/**
 * Returns the JID of the sender.
 */
- (JID*) jid;
/**
 * Returns the XEP-0115 entity capabilities ver string.
 */
- (NSString*) caps;
/**
 * Returns the presence type as described above.
 */
- (PresenceType) type;
/**
 * Compares two presence stanzas by their online state.
 */
- (NSComparisonResult) compare:(Presence*)_otherPresence;
@end
