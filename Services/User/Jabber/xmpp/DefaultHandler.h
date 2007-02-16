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

@interface DefaultHandler : NSObject <MessageHandler,PresenceHandler,IqHandler> {
	XMPPAccount * account;
}
- (id) initWithAccount:(XMPPAccount*)_account;
@end
