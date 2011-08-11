//
//  XMPPMessage.h
//  Jabber
//
//  Created by David Chisnall on 20/08/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPTimestamp.h"
#import "JID.h"
#import "XMPPStanza.h"

typedef enum {in, out} MessageDirection;
typedef enum {MESSAGE_TYPE_CHAT, MESSAGE_TYPE_ERROR, MESSAGE_TYPE_MESSAGE, MESSAGE_TYPE_GROUPCHAT, MESSAGE_TYPE_SPECIAL} message_type_t;

@class XMPPError;
@class ETXMLWriter;

/**
 * The Message class represents a message stanza, one of the three types of XML
 * stanza embodying discrete elements within an XMPP connection.
 */
@interface XMPPMessage : XMPPStanza {
	JID * correspondent;
	MessageDirection direction;
	message_type_t type;
	NSString * subject;
	NSString * body;
	XMPPError * error;
	NSAttributedString * html;
	NSMutableArray * timestamps;
	NSMutableDictionary * unknownAttributes;
	BOOL shouldDisplay;
}
/**
 * Constructs a new (outgoing) message, ready for sending.  The subject is usually
 * nil for chat messages.  The type should be one of MESSAGE_TYPE_{CHAT,ERROR,
 * MESSAGE,GROUPCHAT}.  Only those of MESSAGE_TYPE_MESSAGE should (generally)
 * include a subject.
 */
+ (id) messageWithBody:(id)_body for:(JID*)_recipient withSubject:(NSString*)_subject type:(message_type_t)_type;
/**
 * Initialise a new message.
 */
- (id) initWithBody:(id)_body for:(JID*)_recipient withSubject:(NSString*)_subject type:(message_type_t)_type;
/**
 * Returns the JID of the sender (for incoming messages) or the recipient (for 
 * outgoing messages).
 */
- (JID*) correspondent;
/**
 * Returns the type of the message stanza.
 */
- (message_type_t) type;
/**
 * Returns the subject of the message.
 */
- (NSString*) subject;
/**
 * Returns the (plain text) body of the message.
 */
- (NSString*) body;
/**
 * Returns the rich text version of the body.
 */
- (NSAttributedString*) HTMLBody;
/**
 * Returns the oldest timestamp associated with this message (e.g. offline
 * storage).  May be broken (TEST).
 */
- (XMPPTimestamp*) timestamp;
/**
 * Returns the associated error, if one exists.
 */
- (XMPPError*) error;
/**
 * Sets a flag indicating that this message is destined for display.
 */
- (void) setShouldDisplay: (BOOL)aFlag;
/**
 * Indicates whether the message should be displayed.  Messages of supported
 * types where the plain text and HTML elements are purely for fall-back 
 * support should return NO here.
 */
- (BOOL) shouldDisplay;
/**
 * Returns YES for incoming messages, NO for outgoing.
 */
- (BOOL) in;
/**
 * Compare messages to determine their order of sending.
 */
- (NSComparisonResult) compareByTimestamp: (XMPPMessage*)_other;
/**
 * Writes the message in XML form to the specified XML writer.
 */
- (void )writeToXMLWriter: (ETXMLWriter*)xmlWriter;

/**
 * Only write the beginning of the message but don't send the closing tag.
 */
- (void) beginWritingToXMLWriter: (ETXMLWriter*)xmlWriter;

/**
 * Finish writing the message by sending the closing tag.
 */
 - (void) finishWritingToXMLWriter: (ETXMLWriter*)xmlWriter;
@end
