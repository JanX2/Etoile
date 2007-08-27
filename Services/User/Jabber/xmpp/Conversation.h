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
/**
 * The ConversationDelegate formal protocol should be implemented by any user
 * interface representing a conversation.  Events in the associated conversation
 * class will cause messages defined by this interface to be sent.
 */
@protocol ConversationDelegate <XMPPPresenceDisplay>
/**
 * Sets the conversation with which this delegate is associated.
 */
- (void) conversation:(id)aConversation;
/**
 * Instructs the delegate to display a new message.  The incoming parameter 
 * is used to indicate the direction of the message.  Messages originating with
 * the local user will have this set to NO, while those from outside will have
 * it set to YES.
 */
- (void) displayMessage:(Message*)_message incoming:(BOOL)_in;
/**
 * Used to indicate that the active client on the remote end has changed.  This
 * happens, for example, when the remote user switches clients.  This may
 * indicate a new resource, or an entirely new JID (for example switching from a
 * Jabber client to a legacy client being used over a gateway). 
 */
- (BOOL) newRemoteJID:(JID*)jid;
/**
 * Used to tell the UI that an event has occurred that should cause it to 
 * become visible (or some analogue of visible).  (Deprecated?)
 */
- (void) activate:(id)_sender;
@end

/**
 * The Conversation class is an encapsulation of an abstract conversation.  This
 * is a dialogue between two parties; the local user and some other person.  The
 * remote person is not a client, but some abstraction of a person which may 
 * span multiple identities.  
 *
 * The same abstraction can be used for group chats, where the remote 'person'
 * will be the chat room, and each identity will be a user within that room.
 */
@interface Conversation : NSObject <MessageHandler> {
	XMPPConnection * connection;
	NSString * name;
	JID * remoteJID;
	JabberPerson * remotePerson;
	id <NSObject,ConversationDelegate> delegate;
}
/**
 * Create a new conversation with the specified person, associated with a given 
 * account.  If a conversation with the specified person already exists, a copy
 * will be returned.
 */
+ (id) conversationWithPerson:(JabberPerson*)corespondent forAccount:(XMPPAccount*)_account;
/**
 * Create a new conversation with the specified person associated with the 
 * default account.
 */
+ (id) conversationForPerson:(JabberPerson*)corespondent;
/**
 * Release all conversations.  The class maintains a reference to all created
 * conversations.  This is used to clean-up all references.  After calling this
 * method, existing conversations should not be used; requesting a conversation
 * may cause two conversations with the same person to exist, which could 
 * confuse the user.
 */
+ (void) releaseAllConversations;
/**
 * Sets the class of the object used to create a view for each conversation.
 * This should probably be moved out into the application code and removed from 
 * here.
 */
+ (void) setViewClass:(Class)aClass;
/**
 * Send a string as a message to the remote party.
 */
- (void) sendText:(id)_message;
/**
 * Returns the delegate.
 */
- (id<NSObject,ConversationDelegate>) delegate;
/**
 * Sets the delegate.
 */
- (void) setDelegate:(id<NSObject,ConversationDelegate>)_delegate;
/**
 * Returns the currently active JID of the remote party.  This may change for a
 * variety of reasons.
 */
- (JID*) remoteJID;
/**
 * Overrides the automatic JID selection, and forces messages to be sent to that
 * JID.  
 */
- (void) setJID:(JID*)jid;
/**
 * Returns the name of the remote user.
 */
- (NSString*) name;
/**
 * Returns the remote user.
 */
- (JabberPerson*) remotePerson;
@end
