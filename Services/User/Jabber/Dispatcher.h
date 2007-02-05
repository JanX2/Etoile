//
//  Dispatcher.h
//  Jabber
//
//  Created by David Chisnall on Sun May 23 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRXML/TRXMLNode.h"
#import "Message.h"
#import "Iq.h"
#import "Presence.h"


@protocol MessageHandler <NSObject>
- (void) handleMessage:(Message*)aMessage;
@end
@protocol PresenceHandler <NSObject>
- (void) handlePresence:(Presence*)aPresence;
@end
@protocol IqHandler <NSObject>
- (void) handleIq:(Iq*)anIq;
@end


@interface Dispatcher : NSObject {
	NSMutableDictionary * iqHandlers;
	NSMutableDictionary * messageHandlers;
	NSMutableDictionary * presenceHandlers;
	id <IqHandler> defaultIqHandler;
	id <MessageHandler> defaultMessageHandler;
	id <PresenceHandler> defaultPresenceHandler;
}

+ (id) dispatcherWithDefaultIqHandler:(id <IqHandler>)iq 
					   messageHandler:(id <MessageHandler>)message 
					  presenceHandler:(id <PresenceHandler>)presence;
- (id) initWithDefaultIqHandler:(id <IqHandler>)iq 
				 messageHandler:(id <MessageHandler>)message 
				presenceHandler:(id <PresenceHandler>)presence;
- (id) addIqResultHandler:(id <IqHandler>)handler forID:(NSString*)iqID;
- (id) addMessageHandler:(id <MessageHandler>)handler ForJID:(NSString*)jid;
- (id) addPresenceHandler:(id <PresenceHandler>)handler ForJID:(NSString*)jid;
- (void) dispatchMessage:(Message*)aMessage;
- (void) dispatchPresence:(Presence*)aPresence;
- (void) dispatchIq:(Iq*)anIq;

@end
