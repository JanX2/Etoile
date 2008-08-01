//
//  JabberResource.h
//  Jabber
//
//  Created by David Chisnall on 02/08/2005.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JabberIdentity.h"

/**
 * A JabberResource is a special kind of Jabber Identity representing an variant 
 * of and identity which is already stored in the system as a bare JID.  
 *
 * See also JabberRootIdentity.
 */
@interface JabberResource : JabberIdentity {
	JabberIdentity * root;
}
/**
 * Returns the identity on which this is based.  If this is foo@example.com/bar, 
 * then this will return the identity representing foo@example.com.
 */
- (JabberIdentity*) root;
/**
 * Set the root identity for this identity.  The identity set here will be returned
 * when -root is called.
 */
- (void) setRoot:(JabberIdentity*)identity;
@end
