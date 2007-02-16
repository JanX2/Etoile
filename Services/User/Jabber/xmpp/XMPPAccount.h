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


@interface XMPPAccount : NSObject {
	NSString * name;
	JID * myJID;
	Roster * roster;
	XMPPConnection * connection;
}
- (void) reconnect;
- (JID*) jid;
- (Roster*) roster;
- (XMPPConnection*) connection;
@end
