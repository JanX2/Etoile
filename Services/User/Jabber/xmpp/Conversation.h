//
//  Conversation.h
//  Jabber
//
//  Created by David Chisnall on 17/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPAccount.h"
#import "ChatLog.h"

@protocol ConversationDelegate <XMPPPresenceDisplay>
- (void) conversation:(id)aConversation;
- (void) displayMessage:(Message*)_message incoming:(BOOL)_in;
- (BOOL) newRemoteJID:(JID*)jid;
- (void) activate:(id)_sender;
@end

//TODO: Add multiple account support to this class
@interface Conversation : NSObject <MessageHandler> {
	XMPPConnection * connection;
	NSString * name;
	JID * remoteJID;
	JabberPerson * remotePerson;
	id <NSObject,ConversationDelegate> delegate;
}
+ (id) conversationWithPerson:(JabberPerson*)corespondent forAccount:(XMPPAccount*)_account;
+ (id) conversationForPerson:(JabberPerson*)corespondent;
+ (void) releaseAllConversations;
+ (void) setViewClass:(Class)aClass;
- (void) sendPlainText:(NSString*)_message;
- (id<NSObject,ConversationDelegate>) delegate;
- (void) setDelegate:(id<NSObject,ConversationDelegate>)_delegate;
- (JID*) remoteJID;
- (void) setJID:(JID*)jid;
- (NSString*) name;
- (JabberPerson*) remotePerson;
@end
