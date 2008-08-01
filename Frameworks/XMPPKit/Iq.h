//
//  Iq.h
//  Jabber
//
//  Created by David Chisnall on 30/05/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Stanza.h"
#import "JID.h"

typedef enum {IQ_TYPE_SET,IQ_TYPE_GET,IQ_TYPE_RESULT,IQ_TYPE_ERROR} iq_type_t;
/**
 * An object encapsulating an info-query stanza.  Child elements are parsed by
 * objects retrieved from an IqStanzaFactory and stored in a dictionary.
 */
@interface Iq : Stanza {
	iq_type_t type;
	NSString * sequenceID;
	JID * jid;
	NSString * queryxmlns;
}
/**
 * Returns the type of the iq stanza.  This is IQ_TYPE_{SET,GET,RESULT,ERROR}, 
 * for set, get, result and error types, respectively.
 */
- (iq_type_t) type;
/**
 * Returns the ID of the iq stanza.  Each set or get iq should have a 
 * corresponding error or result stanza with the same ID, however this ID 
 * should be unique for each pair of correspondents.
 */
- (NSString*) sequenceID;
/**
 * Returns the Jabber ID of the sender.
 */
- (JID*) jid;
/**
 * Returns the namespace of the query node, if there is one.
 */
- (NSString*) queryNamespace;
@end
