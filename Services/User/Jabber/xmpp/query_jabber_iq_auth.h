//
//  query_jabber_iq_auth.h
//  Jabber
//
//  Created by David Chisnall on Thu Apr 22 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRXMLNode.h"

@interface query_jabber_iq_auth : TRXMLNode {
	NSString * user;
	NSString * pass;
	NSString * res;
	NSString * sessionID;
}

+ (id) queryWithUsername: (NSString*) username password:(NSString*) password resource: (NSString*) resource;
- (id) initWithUsername: (NSString*) username password:(NSString*) password resource: (NSString*) resource;
- (void) setSessionID:(NSString*) streamID;
@end
