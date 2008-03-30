//
//  DefaultHandler.m
//  Jabber
//
//  Created by David Chisnall on Sun May 23 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "DefaultHandler.h"
#import "Conversation.h"
#import "Roster.h"
//#import "MessageWindowController.h"

@implementation DefaultHandler
- (id) initWithAccount:(XMPPAccount*)_account
{
	self = [self init];
	if(self == nil)
	{
		return nil;
	}
	account = _account;
	return self;
}

- (id) init
{
	self = [super init];
	if(self == nil)
	{
		return nil;
	}
	account = nil;
	return self;
}

- (void) handleMessage:(Message*)aMessage
{
	JID * jid = [aMessage correspondent];
	JabberPerson * person = [[account roster] personForJID:jid];
	Conversation * conversation = [Conversation conversationForPerson:person];
	if(conversation == nil)
	{	
		//TODO: Stop this going wrong when person is not a person
		conversation = [Conversation conversationWithPerson:person
												 forAccount:account];
	//Notify the app that a new conversation has been created
	NSNotificationCenter * local = [NSNotificationCenter defaultCenter];
	[local postNotificationName:@"NewConversationStartedNotification"
	                      object:account
	                    userInfo:[NSDictionary dictionaryWithObject:conversation forKey:@"Conversation"]];
	}
	if(![[conversation remoteJID] isEqualToJID:jid])
	{
		[conversation setJID:jid];
	}
	[conversation handleMessage:aMessage];	
}
- (void) handlePresence:(Presence*)aPresence
{
	
}
- (void) handleIq:(Iq*)anIq
{
	
}

- (id) retain
{
	return [super retain];
}
@end
