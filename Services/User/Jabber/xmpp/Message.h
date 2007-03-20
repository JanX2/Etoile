//
//  Message.h
//  Jabber
//
//  Created by David Chisnall on 20/08/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Timestamp.h"
#import "JID.h"
#import "TRXMLNullHandler.h"
#import "TRXMLNode.h"

typedef enum {in, out} MessageDirection;
typedef enum {MESSAGE_TYPE_CHAT, MESSAGE_TYPE_ERROR, MESSAGE_TYPE_MESSAGE, MESSAGE_TYPE_GROUPCHAT, MESSAGE_TYPE_SPECIAL} message_type_t;
/**
 * The Message class represents a message stanza, one of the three types of XML
 * stanza embodying discrete elements within an XMPP connection.
 */
@interface Message : TRXMLNullHandler {
	JID * correspondent;
	MessageDirection direction;
	message_type_t type;
	NSString * subject;
	NSString * body;
	NSAttributedString * html;
	NSMutableArray * timestamps;
	NSMutableDictionary * unknownAttributes;
}
/**
 * Constructs a new (outgoing) message, ready for sending.  The subject is usually
 * nil for chat messages.  The type should be one of MESSAGE_TYPE_{CHAT,ERROR,
 * MESSAGE,GROUPCHAT}.  Only those of MESSAGE_TYPE_MESSAGE should (generally)
 * include a subject.
 */
+ (id) messageWithBody:(NSString*)_body for:(JID*)_recipient withSubject:(NSString*)_subject type:(message_type_t)_type;
- (id) initWithBody:(NSString*)_body for:(JID*)_recipient withSubject:(NSString*)_subject type:(message_type_t)_type;

- (JID*) correspondent;
- (NSString*) subject;
- (NSString*) body;
- (NSAttributedString*) HTMLBody;
- (Timestamp*) timestamp;
- (BOOL) in;

- (NSComparisonResult) compareByTimestamp:(Message*)_other;

- (TRXMLNode*) xml;
@end
