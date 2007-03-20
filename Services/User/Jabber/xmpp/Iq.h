//
//  Iq.h
//  Jabber
//
//  Created by David Chisnall on 30/05/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TRXMLNullHandler.h"
#import "JID.h"

typedef enum {IQ_TYPE_SET,IQ_TYPE_GET,IQ_TYPE_RESULT,IQ_TYPE_ERROR} iq_type_t;
/**
 * An object encapsulating an info-query stanza.  Child elements are parsed by
 * objects retrieved from an IqStanzaFactory and stored in a dictionary.
 */
@interface Iq : TRXMLNullHandler {
	iq_type_t type;
	NSString * sequenceID;
	JID * jid;
	NSMutableDictionary * children;
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
 * Returns a dictionary containing the children.  The key under which each is
 * stored is defined in the IqStanzaFactory, as is the class used to parse it.
 */
- (NSDictionary*) children;
/**
 * Returns the Jabber ID of the sender.
 */
- (JID*) jid;
@end
