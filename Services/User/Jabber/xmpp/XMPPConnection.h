//
//  XMPPConnection.h
//  Jabber
//
//  Created by David Chisnall on Sun Apr 18 2004.
//  Copyright (c) 2004 David Chisnall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRXMLNullHandler.h"
#import "TRXMLNode.h"
#import "Dispatcher.h"
#import "Roster.h"
#import "Presence.h"

#include <openssl/ssl.h>

typedef enum _connectionState {connecting, connected, loggingIn, unbound, noSession, loggedIn, disconnecting, offline} ConnectionState;

@interface XMPPConnection : TRXMLNullHandler <IqHandler>
{
	//Socket
	int s;
	SSL_CTX * sslContext;
	SSL * ssl;
	BOOL SSLEnabled;
	unsigned int keepalive;
	NSLock * connectionMutex;

	NSLock * messageIDMutex;
	unsigned int messageID;
	
	//XML Parser
	//id parser;
	
	NSThread * connectThread;
	NSMutableString * unsentBuffer;
	//Current state of connection
	ConnectionState connectionState;
	NSDictionary * streamFeatures;
	//Current account details
	NSString * server;
	NSString * user;
	NSString * pass;
	NSString * res;
	NSString * serverID;
	//XML node currently being parsed
	id currentNode;
	//Timer which fires parseXMPP messages
	NSTimer * timer;
	//Roster
	Roster * roster;
	Dispatcher * dispatcher;
	id account;
	Class xmlLog;
	//Delegates
	id <XMPPPresenceDisplay,NSObject> presenceDisplay;
}
- (id) init;
- (id) initWithAccount:(id)_account;
- (void) connectToJabberServer:(NSString*) jabberServer user:(NSString*) userName password:(NSString*) password;
- (void) reconnectToJabberServer;
- (void) disconnect;
- (BOOL) parseXMPP:(id)sender;
- (void) XMPPSend: (NSString*) buffer;
- (NSString*) newMessageID;
- (void) setTimer:(NSTimer*)newTimer;
- (void) setStatus:(unsigned char)_status withMessage:(NSString*)_message;
- (ConnectionState) connected;
- (void) setPresenceDisplay:(id<XMPPPresenceDisplay,NSObject>)_display; 
- (Dispatcher*) dispatcher;
@end
