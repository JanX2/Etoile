//
//  JID.h
//  Jabber
//
//  Created by David Chisnall on Sun Apr 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum {invalidJID = 0, serverJID, serverResourceJID, userJID, resourceJID} JIDType;
/**
 * The JID class represents a Jabber ID of the form user@server/resource.  A JID
 * may have all three components, a user and a server but no resource, a server
 * and resource but no user, or just a server.
 *
 * Typically, two JIDs are referring to the same person (but not the same 
 * client) when they have the same user and server.  For this reason, it is 
 * possible to compare two JIDs either with or without their associated 
 * resources.  For example user@example.com/work and user@example.com/home would
 * likely be two clients in use by the same user, and so chat messages from 
 * either should go into the same dialogue window.
 *
 * JID objects are immutable, and may be used as keys in collection objects such
 * as dictionaries.
 */
@interface JID : NSObject {
	JIDType type;
	NSString * user;
	NSString * server;
	NSString * resource;
	NSString * stringRepresentation;
	NSString * stringRepresentationWithNoResource;
}
/**
 * Creates a new JID from the given string.
 */
+ (id) jidWithString:(NSString*)_jid;
/**
 * Creates a new JID by copying the passed JID.
 */
+ (id) jidWithJID:(JID*)_jid;
/**
 * Sets a newly +alloc'd JID to have the same value as an existing JID.
 */
- (id) initWithJID:(JID*)_jid;
/**
 * Initialises a new JID with a specified string
 */
- (id) initWithString:(NSString*)_jid;
/**
 * Returns the amount of information provided by this JID.
 *
 * invalidJID - Not a valid Jabber ID.
 *
 * serverJID - A Jabber ID with only a server component.
 *
 * serverResourceJID - A JID of the form server/resource.
 *
 * userJID - A Jabber ID with a server and user, but no resource.
 *
 * resourceJID - A Jabber ID with all three components set.
 */
- (JIDType) type;
/**
 * Compare two JIDs.
 */
- (NSComparisonResult) compare:(JID*)_other;
/**
 * Compare two JIDs excluding their resource component.  Any combination of
 * user@example.com/foo, user@example.com/bar and user@example.com will return
 * NSOrderedSame when used as receiver and argument for this comparison.
 */
- (NSComparisonResult) compareWithNoResource:(JID*)_other;
/**
 * Test for JID equality.  Returns YES if both JIDs have the same components and
 * all components are the same.
 */
- (BOOL) isEqualToJID:(JID*)aJID;
/**
 * Returns a new JID representing this JID with the resource stripped.
 */
- (JID*) rootJID;
/**
 * A string representation of this JID.  Should be renamed stringValue.
 */
- (NSString*) jidString;
/**
 * A string value of the root JID.  Semantically equivalent to calling
 * [[aJid rootJID] jidString], but more efficient.
 */
- (NSString*) jidStringWithNoResource;
/**
 * Returns the node; the component before the @, typically used to identify the 
 * user.
 */
- (NSString*) node;
/**
 * Returns the server (domain) name for this JID.
 */
- (NSString*) domain;
/** 
 * Returns the resource for this JID.
 */
- (NSString*) resource;
@end
