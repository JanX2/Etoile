//
//  XMPPDefaultHandler.m
//  Jabber
//
//  Created by David Chisnall on Sun May 23 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "XMPPDefaultHandler.h"
#import "XMPPConversation.h"
#import "XMPPRoster.h"
//#import "MessageWindowController.h"

@implementation XMPPDefaultHandler
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

- (void) handleMessage:(XMPPMessage*)aMessage
{
        JID * jid = [aMessage correspondent];
        XMPPPerson * person = [[account roster] personForJID:jid];
        XMPPConversation * conversation = [XMPPConversation conversationForPerson:person];
        if(conversation == nil)
        {        
                //TODO: Stop this going wrong when person is not a person
                conversation = [XMPPConversation conversationWithPerson:person
                                                                                                 forAccount:account];
        //Notify the app that a new conversation has been created
        NSNotificationCenter * local = [NSNotificationCenter defaultCenter];
        [local postNotificationName:@"XMPPNewConversationStartedNotification"
                              object:account
                            userInfo:[NSDictionary dictionaryWithObject:conversation forKey:@"XMPPConversation"]];
        }
        if(![[conversation remoteJID] isEqualToJID:jid])
        {
                [conversation setJID:jid];
        }
        [conversation handleMessage:aMessage];        
}
- (void) handlePresence:(XMPPPresence*)aPresence
{
        
}
- (void) handleInfoQuery:(XMPPInfoQueryStanza*)anIq
{
        
}
@end
