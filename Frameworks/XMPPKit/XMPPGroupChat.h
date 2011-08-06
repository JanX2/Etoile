//
//  XMPPGroupChat.h
//  Jabber
//
//  Created by David Chisnall on 22/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPConversation.h"
#import <EtoileXML/ETXMLNode.h>

/** 
 * Group chat class.  Not yet implemented.
 */
@interface XMPPGroupChat : XMPPConversation {
	
}
//+ (id) groupChatFromInvitation:(ETXMLNode*)_invitation;
//+ (id) groupChatOnServer:(JID*)_server;

@end
