//
//  XMPPConnection.h
//  Jabber
//
//  Created by David Chisnall on Sun Apr 18 2004.
//  Copyright (c) 2004 David Chisnall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import "Dispatcher.h"
#import "Roster.h"
#import "Presence.h"

/**
 * The XMPPConnection class represents a connection to an XMPP server.  It is the 
 * root parser owner.  All XML received from the server is parsed by this class (or
 * delegated to others by this class).  All sending of XML data goes via this 
 * class.
 */
@interface XMPPConnection : ETXMLNullHandler <IqHandler>
{
	//Socket
	ETSocket *socket;
	ETXMLSocketWriter *xmlWriter;
	NSTimer *keepalive;

	unsigned int messageID;
	NSString* sessionID;
	
	NSMutableString * unsentBuffer;
	NSDictionary * streamFeatures;
	//Current account details
	NSString * serverHost;
	NSString * server;
	NSString * user;
	NSString * pass;
	NSString * res;
	NSString * serverID;
	//XML node currently being parsed
	id currentNode;
	//Roster
	Roster * roster;
	Dispatcher * dispatcher;
	id account;
	Class xmlLog;
	//Delegates
	id <XMPPPresenceDisplay,NSObject> presenceDisplay;
}
/**
 * Initialise the connection for a specified account.
 */
- (id) initWithAccount:(id)_account;
/**
 * Connect to the specified Jabber server as the specified user, with the given
 * password.  
 *
 * This needs changing for cases where the server is not that specified by the 
 * client's JID.
 */
- (void) connectToJabberServer:(NSString*) jabberServer 
					   withJID:(JID*) aJID
					  password:(NSString*) password;
/**
 * Reconnect after disconnection.
 */
- (void) reconnectToJabberServer;
/**
 * Disconnect from the Jabber server.
 */
- (void) disconnect;
/**
 * Send the passed XML to the server.
 */
- (void) XMPPSend: (NSString*) buffer;
/**
 * Returns a new connection-unique ID to be used with iq set/get stanzas.
 */
- (NSString*) newMessageID;
/**
 * Returns YES if connected to the server.
 */
- (BOOL)isConnected;
/**
 * Set the current status.  
 */
- (void) setStatus:(unsigned char)_status withMessage:(NSString*)_message;
/**
 * Sets the UI component used to display the presence.  This should definitely be 
 * replaced with a notification based system.
 */
- (void) setPresenceDisplay:(id<XMPPPresenceDisplay,NSObject>)_display; 
/**
 * Returns the dispatcher associated with the connection.
 */
- (Dispatcher*) dispatcher;
/**
 * Returns the server name.
 */
- (NSString*) server;
/**
 * Returns the XML writer which can be used to send XML to the stream.
 */
- (ETXMLSocketWriter*)xmlWriter;
@end
