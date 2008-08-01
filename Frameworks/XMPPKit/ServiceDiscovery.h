//
//  ServiceDiscovery.h
//  Jabber
//
//  Created by David Chisnall on 18/02/2005.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Dispatcher.h"

@class XMPPAccount;
@class XMPPConnection;
/**
 * Service discovery handler class.  Handles XEP-0030 service discovery and
 * caching via XEP-0115 entity capabilities.
 */
@interface ServiceDiscovery : NSObject <IqHandler> {
	XMPPConnection * connection;
	Dispatcher * dispatcher;
	NSMutableDictionary * features;
	NSMutableDictionary * children;
	NSMutableDictionary * knownNodes;
	NSMutableDictionary * capabilitiesPerJID;
	NSMutableDictionary * featuresForCapabilities;
	NSMutableSet * myFeatures;
}
- (ServiceDiscovery*) initWithAccount:(XMPPAccount*)account;
/**
 * Sets XEP-00115 entitiy capabilities for a specified JID.
 */
- (void) setCapabilities:(NSString*)caps forJID:(JID*)aJid;
/**
 * Returns the identities associated with a given JID/node combination.
 * Returns nil if they have not been retrieved yet.  A DiscoFeaturesFound
 * notification will be posted when they have been with the jid field of the
 * userinfo dictionary set to the 
 * JID.
 */
- (NSArray*) identitiesForJID:(JID*)aJid node:(NSString*)aNode;
/**
 * Returns the features associated with a given JID/node combination.  Returns
 * nil if they have not been retrieved yet.  A DiscoFeaturesFound notification
 * will be posted when they have been with the jid field of the userinfo
 * dictionary set to the 
 * JID.
 */
- (NSArray*) featuresForJID:(JID*)aJid node:(NSString*)aNode;
/**
 * Returns the items associated with a given JID/node combination.  Returns nil
 * if they have not been retrieved yet.  A DiscoItemsFound notification will be
 * posted when they have been with the jid field of the userinfo dictionary set
 * to the JID.
 */
- (NSArray*) itemsForJID:(JID*)aJid node:(NSString*)aNode;
/**
 * Adds a feature to the list this client advertises.
 */
- (void) addFeature:(NSString*)aFeature;
@end
