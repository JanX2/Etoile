//
//  iq.h
//  Jabber
//
//  Created by David Chisnall on Thu Apr 22 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPNode.h"

@interface iq : XMPPNode {
	enum _iqtype { error, set, get, result } type;
	NSString * XMPPID;
	NSString * to;
	NSString * from;
}
+ (id) iqWithID:(NSString*) nodeID;
- (id) initWithID:(NSString*) nodeID;
- (void) setIQType:(NSString*) newType;
- (void) setDestination:(NSString*) destination;
- (NSString*) getDestingation;
- (void) setOrigin:(NSString*) origin;
- (NSString*) getOrigin;
- (NSString*) getIQType;
- (NSString*)getID;
@end
