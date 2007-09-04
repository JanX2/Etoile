//
//  ServiceDiscovery.h
//  Jabber
//
//  Created by David Chisnall on 18/02/2005.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XMPPAccount.h"
#import "Dispatcher.h"
#import "Capabilities.h"

/**
 * Service discovery handler class.  Not yet implemented.
 */
@interface ServiceDiscovery : NSObject <DispatchDelegate> {
	XMPPAccount * account;
	NSMutableDictionary * cache;
	NSMutableDictionary * knownNodes;
	NSMutableSet * capabilities;
}
- (ServiceDiscovery*) initWithAccount:(XMPPAccount*)xmppaccount;
- (void) getCapabilitiesForJID:(JID*)node notifyObject:(id)target withSelector:(SEL)selector;
- (void) handleNode:(ETXMLNode*)node fromDispatcher:(id)_dispatcher;
- (void) invalidateCacheForJID:(JID*)jid;

@end
