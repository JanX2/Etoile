//
//  GroupChat.h
//  Jabber
//
//  Created by David Chisnall on 22/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Conversation.h"
#import "TRXML/TRXMLNode.h"

@interface GroupChat : Conversation {
	
}
//+ (id) groupChatFromInvitation:(TRXMLNode*)_invitation;
//+ (id) groupChatOnServer:(JID*)_server;

@end
