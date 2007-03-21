//
//  query_jabber_iq_auth.h
//  Jabber
//
//  Created by David Chisnall on Thu Apr 22 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRXMLNode.h"

/**
 * The query_jabber_iq_auth class is used to construct an auth request to send to 
 * the server.  This is part of the Jabber (pre-XMPP) non-SASL authentication code
 * and is no longer used.  It is retained in case anyone feels like adding non-SASL
 * auth support back in (some people might still want it...).
 */
@interface query_jabber_iq_auth : TRXMLNode {
	NSString * user;
	NSString * pass;
	NSString * res;
	NSString * sessionID;
}
/**
 * Create a query with the specified username, password and resource.
 */
+ (id) queryWithUsername: (NSString*) username password:(NSString*) password resource: (NSString*) resource;
/**
 * Create a query with the specified username, password and resource.
 */
- (id) initWithUsername: (NSString*) username password:(NSString*) password resource: (NSString*) resource;
/**
 * Sets the session ID, which should have been received from the server.
 */
- (void) setSessionID:(NSString*) streamID;
@end
