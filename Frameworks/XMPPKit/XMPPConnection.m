//
//  XMPPConnection.m
//  Jabber
//
//  Created by David Chisnall on Sun Apr 18 2004.
//  Copyright (c) 2004 David Chisnall. All rights reserved.
//

#include <netdb.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#import "XMPPConnection.h"
#import <EtoileFoundation/EtoileFoundation.h>
#import "StreamFeatures.h"
#import "DefaultHandler.h"
#import "Presence.h"
#import "XMPPAccount.h"


static NSMutableDictionary * connections = nil;

static NSDictionary * STANZA_CLASSES;
static NSDictionary * STANZA_KEYS;

#define SET_STATE(x) do { isa = [XMPP ## x ## Connection class]; NSLog(@"Entering state %s", #x); } while(0)

@interface NSObject( XMLLogging)
+ (void) logIncomingXML:(NSString*)xml;
+ (void) logOutgoingXML:(NSString*)xml;
@end

/**
 * Each state in the XMPPConnection state machine is represented by a custom
 * subclass.
 */
@interface XMPPConnectingConnection : XMPPConnection @end
@interface XMPPOfflineConnection : XMPPConnection @end
@interface XMPPConnectedConnection : XMPPConnectingConnection @end
@interface XMPPEncryptingConnection : XMPPConnectedConnection @end
@interface XMPPLoggingInConnection : XMPPConnectedConnection @end
@interface XMPPUnboundConnection : XMPPConnectedConnection @end
@interface XMPPNoSessionConnection : XMPPConnectedConnection @end
@interface XMPPLoggedInConnection : XMPPConnectedConnection @end

@interface XMPPConnection (Private)
- (void) legacyLogIn;
@end

@implementation XMPPConnection
+ (void) initialize
{
	//Create default handler classes
	STANZA_CLASSES = [[NSDictionary dictionaryWithObjectsAndKeys:
		[Message class], @"message",
		[Presence class], @"presence",
		[Iq class], @"iq", 
		[StreamFeatures class], @"stream:features",
		nil] retain];
	STANZA_KEYS = [[NSDictionary dictionaryWithObjectsAndKeys:
		@"message", @"message",
		@"presence", @"presence",
		@"iq", @"iq", 
		@"streamFeatures", @"stream:features",
		nil] retain];
	
	NSLog(@"Stanza delegate classes: %@", STANZA_CLASSES);
}

+ (id) connectionWithAccount:(NSString*)_account
{
	XMPPConnection * connection;
	if (connections == nil)
	{
		connections = [[NSMutableDictionary alloc] init];
	}
	
	connection = [connections objectForKey:_account];
	
	if (connection == nil)
	{
		connection = [XMPPConnection alloc];
		[connections setObject:connection forKey:_account];
		[connection initWithAccount:_account];
		[connection autorelease];
	}
	return connection;
}


- (id) initWithAccount:(id)_account
{
	if (![_account isKindOfClass:[XMPPAccount class]])
	{
		[self release];
		return nil;
	}

	SUPERINIT;
	ASSIGN(res, [[NSHost currentHost] name]);
	//Get the log class, if it has been built
	xmlLog = NSClassFromString(@"XMLLog");
	account = _account;
	roster = [(XMPPAccount*)account roster];
	
	DefaultHandler * defaultHandler = [[[DefaultHandler alloc] initWithAccount:account] autorelease];
	dispatcher = [[Dispatcher dispatcherWithDefaultIqHandler:roster
											 messageHandler:defaultHandler
											presenceHandler:roster]
		retain];
	return self;
}
- (void)resetKeepAlive
{
	[keepalive invalidate];
	[keepalive release];
	keepalive = [[NSTimer scheduledTimerWithTimeInterval: 50
	                                              target: self
												selector: @selector(sendKeepAlive:)
	                                            userInfo: nil
	                                             repeats: NO] retain];
}
- (void) reconnectToJabberServer
{
	NSLog(@"Connecting...");
	ASSIGN(socket, [ETSocket socketConnectedToRemoteHost: serverHost
	                                          forService: @"xmpp-client"]);
	if (nil == socket)
	{
		// Legacy service description for operating systems (e.g. OS X) that
		// haven't updated /etc/services to the standardised version.
		ASSIGN(socket, [ETSocket socketConnectedToRemoteHost: serverHost
												  forService: @"jabber-client"]);
		if (nil == socket)
		{
			NSLog(@"Connect failing\n");
			return;
		}
	}
	
	SET_STATE(Connecting);
	//Initialise the parser
	[parser release];
	parser = [[ETXMLParser alloc] init];
	[parser setContentHandler:self];
	[self resetKeepAlive];

	[socket setDelegate: self];
	[xmlWriter release];
	xmlWriter = [ETXMLSocketWriter new];
	[xmlWriter setSocket: socket];
	[self receivedData: nil fromSocket: nil];
}

//Connect to an XMPP server.
- (void) connectToJabberServer:(NSString*) jabberServer 
					   withJID:(JID*) aJID
					  password:(NSString*) password
{
	ASSIGN(user, [aJID node]);
	ASSIGN(server, [aJID domain]);
	ASSIGN(pass, [password retain]);
	if (jabberServer == nil)
	{
		ASSIGN(serverHost, server);
	}
	else
	{
		ASSIGN(serverHost, jabberServer);
	}
	NSLog(@"Connecting to %@ with username %@ and password %@", serverHost, user, pass);
	[self reconnectToJabberServer];
}

- (void) disconnect {}

- (void)characters:(NSString *)_chars
{
	NSLog(@"Unexpected CDATA encountered in <stream:stream /> tag:\n\%@", _chars);
}

- (void)sendString: (NSString*)aString
{
	NSLog(@"SENT: %@", aString);
	[self resetKeepAlive];
	[socket sendData: [aString dataUsingEncoding: NSUTF8StringEncoding]];
}
- (void)sendKeepAlive: (id)sender
{
	[self sendString: @" "];
}

- (void)receivedData: (NSData*)aData fromSocket: (ETSocket*)aSocket {}

- (NSString*) server
{
	return server;
}

- (void)startElement:(NSString *)aName
		  attributes:(NSDictionary *)_attributes
{
	NSLog(@"Parsing element: %@", aName);
	
	if ([aName isEqualToString:@"stream:stream"])
	{
		sessionID = [[_attributes objectForKey:@"id"] retain];
		[server release];
		server = [[_attributes objectForKey:@"from"] retain];
		if (![[_attributes objectForKey:@"version"] isEqualToString:@"1.0"])
		{
			[self legacyLogIn];
		}
	}
	else
	{
		NSString * childKey = [STANZA_KEYS objectForKey:aName];
		id <ETXMLParserDelegate> stanzaDelegate = [[[STANZA_CLASSES objectForKey:aName] alloc] initWithXMLParser:parser parent:self key:childKey];
		[stanzaDelegate startElement:aName
						  attributes:_attributes];
	}
}
- (void)logInWithMechansisms:(NSSet*) aFeatureSet
{
	//TODO: DIGEST-MD5 auth
	if ([aFeatureSet containsObject:@"PLAIN"])
	{
		NSMutableData * authData = [NSMutableData dataWithBytes:"\0" length:1];
		[authData appendData:[user dataUsingEncoding:NSUTF8StringEncoding]];
		[authData appendBytes:"\0" length:1];
		[authData appendData:[pass dataUsingEncoding:NSUTF8StringEncoding]];
		NSString * authstring = [authData base64String];
		//Send auth mechanism
		[xmlWriter startAndEndElement: @"auth"
		                   attributes: D(@"urn:ietf:params:xml:ns:xmpp-sasl",
		                                 @"xmlns", @"PLAIN", @"mechanism")
		                        cdata: authstring];
		SET_STATE(LoggingIn);
	}
	else
	{
		NSLog(@"No supported authentication mechanisms found.  Aborting.");
	}		
}

- (void) startSession
{
	NSString * sessionIqID = [self newMessageID];
	[xmlWriter startElement: @"iq"
	             attributes: D(@"set", @"type", sessionIqID, @"id")];
	[xmlWriter startAndEndElement: @"session"
	                   attributes: D(@"urn:ietf:params:xml:ns:xmpp-session",
	                                 @"xmlns")];
	[xmlWriter endElement]; // </iq>
	[dispatcher addIqResultHandler:self forID:sessionIqID];
}

- (void) bind
{
	//Bind to a resource
	//<iq type='set' id='bind_2'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'><resource>someresource</resource></bind></iq>
	NSString * bindID = [self newMessageID];
	[xmlWriter startElement: @"iq"
	             attributes: D(@"set", @"type", bindID, @"id")];
	[xmlWriter startElement: @"bind"
	             attributes: D(@"urn:ietf:params:xml:ns:xmpp-bind", @"xmlns")];
	[xmlWriter startAndEndElement: @"resource"];
	[xmlWriter endElement]; // </bind>
	[xmlWriter endElement]; // </iq>
	[dispatcher addIqResultHandler: self forID: bindID];
}

//Child stanza handlers
- (void) addmessage:(Message*)aMessage
{
	[dispatcher dispatchMessage:aMessage];
}

- (void) addiq:(Iq*)anIQ
{
	[dispatcher dispatchIq:anIQ];
}

- (void) addpresence:(Presence*)aPresence
{
	[dispatcher dispatchPresence:aPresence];
}
//END child stanza handlers

- (void)endElement:(NSString *)_Name
{
	if ([_Name isEqualToString:@"stream:stream"])
	{
			/*
		if(connectionState != loggedIn)
		{
			Jesse says: we need some other kind of solution here since we don't have
			a -connectionFailed method anymore... not sure what to do. I commented it
			out since it was causing XCode's build to fail.
			
			if([[NSApp delegate] respondsToSelector:@selector(connectionFailed:)])
			{
				[(JabberApp*)[NSApp delegate] connectionFailed:account];
			}
		}
		//If we have not manually disconnected, try to reconnect.
			*/
		[presenceDisplay setPresence:PRESENCE_OFFLINE withMessage:@"Disconnected"];
	}
	
}

- (void) setPresenceDisplay:(id<XMPPPresenceDisplay,NSObject>)_display
{
	[presenceDisplay release];
	presenceDisplay = [_display retain];
}

- (void) handleIq:(Iq*)anIq {}

- (NSString*) newMessageID
{
	unsigned int i = messageID++;
	return [NSString stringWithFormat:@"ETXMPP_%d", i];
}

- (void) XMPPSend: (NSString*) buffer
{
	[xmlLog logOutgoingXML:buffer];
	//If we are not connected, buffer the input until we are.
	if (unsentBuffer == nil)
	{
		unsentBuffer = [[NSMutableString alloc] init];
	}
	[unsentBuffer appendString:buffer];
}


- (void) setStatus:(unsigned char)aStatus withMessage:(NSString*)aMessage
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	if (aStatus == PRESENCE_OFFLINE)
	{
		[attributes setObject: @"unavailable" forKey: @"type"];
	}
	[xmlWriter startElement: @"presence"
	             attributes: attributes];

	if (aStatus != PRESENCE_ONLINE)
	{
		[xmlWriter startAndEndElement: @"show"
		                        cdata: [Presence xmppStringForPresence: aStatus]];
	}
	NSDictionary * presenceDictionary;
	if (aMessage != nil)
	{
		[xmlWriter startAndEndElement: @"status"
		                        cdata: aMessage];
		presenceDictionary = D([NSNumber numberWithChar:aStatus],@"show",
		                       aMessage,@"status");
	}
	else
	{
		presenceDictionary = D([NSNumber numberWithChar:aStatus], @"show");
	}
	[xmlWriter endElement];
	//Notify anyone who cares that our presence has changed
	NSNotificationCenter * local = [NSNotificationCenter defaultCenter];
	NSNotificationCenter * remote = [NSDistributedNotificationCenter defaultCenter];
	[local postNotificationName:@"LocalPresenceChangedNotification"
						 object:account
					   userInfo:presenceDictionary];
	[remote postNotificationName:@"LocalPresenceChangedNotification"
						  object:[account name]
						userInfo:presenceDictionary];
}

- (void) setParser:(id)aParser
{
	parser = aParser;
}
//Does nothing.  This should never be used, since we are the root element...
- (void) setParent:(id) newParent {}

- (Dispatcher*) dispatcher
{
	return dispatcher;
}
- (BOOL)isConnected
{
	return NO;
}
- (ETXMLSocketWriter*)xmlWriter
{
	return xmlWriter;
}

- (void) dealloc
{
	[res release];
	[user release];
	[server release];
	[pass release];
	[sessionID release];
	[unsentBuffer release];
	[serverHost release];
	[streamFeatures release];
	[socket release];
	[dispatcher release];
	[super dealloc];
}
@end

/**
 * Offline behaviour is implemented in the superclass, so this subclass doesn't
 * provide any methods.
 */
@implementation XMPPOfflineConnection @end
@implementation XMPPConnectedConnection
- (BOOL)isConnected
{
	return YES;
}
//Digest non-SASL auth.
- (void) legacyLogIn
{
	NSString * newMessageID = [self newMessageID];
	[dispatcher addIqResultHandler:self forID:newMessageID];

	[xmlWriter startElement: @"iq"
				 attributes: D(newMessageID, @"id", @"set", @"type", server, @"to")];
	NSString * sessionPassword = [sessionID stringByAppendingString:pass];

	NSData *data = [sessionPassword dataUsingEncoding: NSUTF8StringEncoding];
	NSString * digest = [data sha1];
	[xmlWriter startElement: @"query"
				 attributes: D(@"jabber:iq:auth", @"xmlns")];

	[xmlWriter startAndEndElement: @"username"
	                        cdata: user];

	[xmlWriter startAndEndElement: @"digest"
	                        cdata: digest];

	[xmlWriter startAndEndElement: @"resource"
	                        cdata: res];

	[xmlWriter endElement]; // </query>
	[xmlWriter endElement]; // </iq>
	
	SET_STATE(LoggingIn);
}
- (void)receivedData: (NSData*)aData fromSocket: (ETSocket*)aSocket
{
	[self resetKeepAlive];
	NSString *xml = 
		[[[NSString alloc] initWithData: aData
		                       encoding: NSUTF8StringEncoding] autorelease];
	NSLog(@"Received: '%@'", xml);
	[xmlLog logIncomingXML: xml];
	[parser parseFromSource: xml];
}
- (void) addstreamFeatures:(NSDictionary*) aFeatureSet
{
	NSLog(@"Stream features has retain count %lu", (unsigned long)[streamFeatures retainCount]);
	[streamFeatures release];
	streamFeatures = [aFeatureSet retain];
	//If we are connected, try logging in
	if ([[aFeatureSet objectForKey: @"starttls"] 
		isEqualToString: @"urn:ietf:params:xml:ns:xmpp-tls"])
	{
		[self sendString: @"<starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls'/>"];
		SET_STATE(Encrypting);
	}
	//Hack for broken servers
	else if ([[aFeatureSet objectForKey:@"auth"] isEqualToString:@"http://jabber.org/features/iq-auth"])
	{
		[self legacyLogIn];
	}
	else
	{
		[self logInWithMechansisms:[aFeatureSet objectForKey:@"mechanisms"]];
	}
}
@end
@implementation XMPPConnectingConnection
- (void) reconnectToJabberServer
{
	[self disconnect];
	SET_STATE(Offline);
	[self reconnectToJabberServer];
}
- (void)endElement:(NSString *)_Name
{
	if ([_Name isEqualToString:@"stream:stream"])
	{
		//If we have not manually disconnected, try to reconnect.
		[self reconnectToJabberServer];
	}
}
- (void) disconnect
{
	[self XMPPSend:@"</stream:stream>"];
	[socket release];
	socket = nil;
	SET_STATE(Offline);
}
- (void)receivedData: (NSData*)aData fromSocket: (ETSocket*)aSocket
{
	[self resetKeepAlive];
	[self sendString: [NSString stringWithFormat: 
		@"<?xml version='1.0' encoding='UTF-8' ?><stream:stream to='%@'"
		" xmlns='jabber:client' version='1.0' xmlns:stream="
		"'http://etherx.jabber.org/streams'>",
		server]];
	SET_STATE(Connected);
}
@end
@implementation XMPPLoggedInConnection
- (void)startElement:(NSString *)aName
		  attributes:(NSDictionary *)_attributes
{
	NSString * childKey = [STANZA_KEYS objectForKey:aName];
	id <ETXMLParserDelegate> stanzaDelegate = [[[STANZA_CLASSES objectForKey:aName] alloc] initWithXMLParser:parser parent:self key:childKey];
	[stanzaDelegate startElement:aName
					  attributes:_attributes];
}
- (void) handleIq:(Iq*)anIq
{
	if (([anIq type] == IQ_TYPE_RESULT))
	{
		NSString * newMessageID = [self newMessageID];
		[dispatcher addIqResultHandler:roster forID:newMessageID];
		[xmlWriter startElement: @"iq"
		             attributes: D(newMessageID, @"id", @"get", @"type")];
		[xmlWriter startElement: @"query"
					 attributes: D(@"jabber:iq:roster", @"xmlns")];

		[xmlWriter endElement];
		[xmlWriter endElement];
		
		SET_STATE(LoggedIn);
		
		[self XMPPSend:unsentBuffer];
		[unsentBuffer setString:@""];
	}
}
- (void) XMPPSend: (NSString*) buffer
{
	[xmlLog logOutgoingXML:buffer];
	if (unsentBuffer != nil)
	{
		[self sendString: unsentBuffer];
		[unsentBuffer release];
		unsentBuffer = nil;
	}
	[self sendString: buffer];
}
@end
@implementation XMPPUnboundConnection
- (void) addstreamFeatures:(NSDictionary*) aFeatureSet
{
	ASSIGN(streamFeatures, aFeatureSet);
	if ([aFeatureSet objectForKey:@"bind"] != nil)
	{
		[self bind];
	}
	else if ([aFeatureSet objectForKey:@"session"] != nil)
	{
		SET_STATE(NoSession);
		[self startSession];
	}
	else
	{
		SET_STATE(LoggedIn);
	}
}
- (void) handleIq:(Iq*)anIq
{
	if ([streamFeatures objectForKey:@"session"] != nil)
	{
		SET_STATE(NoSession);
		[self startSession];
	}
	else
	{
		SET_STATE(LoggedIn);
		[self handleIq: anIq];
	}
}
@end
@implementation XMPPEncryptingConnection
- (void)startElement:(NSString *)aName
		  attributes:(NSDictionary *)_attributes
{
	if ([aName isEqualToString: @"proceed"])
	{
		NSLog(@"SSL returned %d", [socket negotiateSSL]);
		SET_STATE(Connecting);
		// Reset the connection
		[self receivedData: nil fromSocket: nil];
	}
}
@end
@implementation XMPPLoggingInConnection 
- (void) handleIq:(Iq*)anIq
{
	SET_STATE(LoggedIn);
	[self handleIq: anIq];
}

- (void)startElement:(NSString *)aName
		  attributes:(NSDictionary *)_attributes
{
	if ([aName isEqualToString:@"success"])
	{
		//Once we're authenticated, re-initialise the stream...ha
		SET_STATE(Unbound);
		// FIXME: Move this to a method
		NSString * newStream = [NSString stringWithFormat:@"<stream:stream to='%@' xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams' version='1.0'>",
                                server];
		[self sendString: newStream];
	}
	// TODO: Handle failure.
}
@end
@implementation XMPPNoSessionConnection
- (void) handleIq:(Iq*)anIq
{
	SET_STATE(LoggedIn);
	[self handleIq: anIq];
}
@end
