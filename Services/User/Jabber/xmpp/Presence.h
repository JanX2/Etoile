//
//  presence.h
//  Jabber
//
//  Created by David Chisnall on Sun Apr 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRXMLNode.h"
#import "TRXMLNullHandler.h"
#import "JID.h"

#define PRESENCE_CHAT 10
#define PRESENCE_ONLINE 20
#define PRESENCE_AWAY 30
#define PRESENCE_XA 40
#define PRESENCE_DND 50
#define PRESENCE_OFFLINE 60
#define PRESENCE_UNKNOWN 70

@protocol XMPPPresenceDisplay 
- (void) setPresence:(unsigned char)_status withMessage:(NSString*)_message;
@end

typedef enum {online, unavailable, subscribe, unsubscribe, subscribed, unsubscribed} PresenceType;

@interface Presence : TRXMLNullHandler {
	JID * from;
	PresenceType type;
	unsigned char onlineStatus;
	NSString * message;
	int priority;
}
+ (NSString*) displayStringForPresence:(unsigned char)_presence;
+ (NSString*) xmppStringForPresence:(unsigned char)_presence;
+ (unsigned char) presenceForXMPPString:(NSString*)_presence;
- (id) initWithJID:(JID*)_jid;
- (unsigned char) show;
- (NSString*) status;
- (int) priority;
- (JID*) jid;
- (PresenceType) type;
- (NSComparisonResult) compare:(Presence*)_otherPresence;
@end
