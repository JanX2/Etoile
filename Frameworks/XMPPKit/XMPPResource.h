//
//  XMPPResource.h
//  Jabber
//
//  Created by David Chisnall on 02/08/2005.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XMPPIdentity.h"

/**
 * A XMPPResource is a special kind of Jabber Identity representing an variant 
 * of and identity which is already stored in the system as a bare JID.  
 *
 * See also JabberRootIdentity.
 */
@interface XMPPResource : XMPPIdentity {
	XMPPIdentity * root;
}
/**
 * Returns the identity on which this is based.  If this is foo@example.com/bar, 
 * then this will return the identity representing foo@example.com.
 */
- (XMPPIdentity*) root;
/**
 * Set the root identity for this identity.  The identity set here will be returned
 * when -root is called.
 */
- (void) setRoot:(XMPPIdentity*)identity;
@end
