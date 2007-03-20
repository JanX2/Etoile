//
//  JabberIdentity.h
//  Jabber
//
//  Created by David Chisnall on 20/08/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JID.h"
#import "TRXMLNullHandler.h"
#import "Presence.h"
#import "Dispatcher.h"

/**
 * A JabberIdentity represents a unique endpoint in the Jabber network.  Each
 * person may have a collection of identities, corresponding to different client
 * or different means of accessing them (e.g. a pure Jabber ID and a 
 * legacy-protocol gateway Jabber ID both of which are used from the same 
 * client.
 *
 * This abstraction allows conversations to be tied to people, rather than to 
 * clients.  The roster will assume that entries in the same group with the same
 * name correspond to the same person.  Similarly, different resources of the 
 * same JID will be treated as different identities belonging to the same 
 * person.
 */
@interface JabberIdentity : TRXMLNullHandler {
	id person;
	JID * jid;
	NSString * subscription;
	NSString * group;
	NSString * name;
	Presence * presence;
	int priority;
	int basePriority;
}
/**
 * Create a new identity for the specified person.  The name and group should 
 * match that of the person.
 */
- (id) initWithJID:(JID*)_jid withName:(NSString*)_name inGroup:(NSString*)_group forPerson:(id)_person;
/**
 * Set the presence of the identity.  Used whenever a presence stanza is 
 * received.
 */
- (void) setPresence:(Presence*)_presence;
/**
 * Return the person with whom this identity is associated.
 */
- (id) person;
/**
 * Set the person with whom this identity is associated.
 */
- (void) person:(id)_person;
/**
 * Return the name of the identity.
 */
- (NSString*) name;
/**
 * Return the roster group of the identity.
 */
- (NSString*) group;
/**
 * Return the Jabber ID of the identity.
 */
- (JID*) jid;
/**
 * Return the current presence of the identity.
 */
- (Presence*) presence;
/**
 * Return the priority associated with the current presence of the identity.
 */
- (int) priority;
/**
 * Compare two identities by their priority.  Used to determine which should
 * be the default recipient of messages.
 */
- (NSComparisonResult) compareByPriority:(JabberIdentity*)_other;
/**
 * Compare two identities by their JID.  Commonly used to sort identities for 
 * display in a UI.
 */
- (NSComparisonResult) compareByJID:(JabberIdentity*)_other;
@end
