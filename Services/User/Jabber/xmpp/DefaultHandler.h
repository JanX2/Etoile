//
//  DefaultHandler.h
//  Jabber
//
//  Created by David Chisnall on Sun May 23 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Dispatcher.h"
#import "XMPPAccount.h"

/** 
 * Default stanza handler class.  Every Message, Iq and Presence stanza will
 * be passed to this class if it is not handled elsewhere.
 */
@interface DefaultHandler : NSObject <MessageHandler,PresenceHandler,IqHandler> {
	XMPPAccount * account;
}
/**
 * Create a default handler for the specified account.
 */
- (id) initWithAccount:(XMPPAccount*)_account;
@end
