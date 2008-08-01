//
//  JabberRootIdentity.h
//  Jabber
//
//  Created by David Chisnall on 02/08/2005.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JabberIdentity.h"

/**
 * A root identity; one which may have additional identities for individual 
 * resources associated with it.
 */
@interface JabberRootIdentity : JabberIdentity {
	NSMutableDictionary * resources;
	NSMutableArray * resourceList;
}
/**
 * Adds a new resource, specified by a full JID.
 */
- (void) addResource:(JID*)_jid;
/**
 * Returns an array of all resources associated with this identity.
 */
- (NSArray*) resources;
/**
 * Returns the identity associated with a specific resource.
 */
- (JabberIdentity*) identityForResource:(NSString*)resource;
@end
