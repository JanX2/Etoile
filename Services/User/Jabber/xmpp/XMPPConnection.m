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
#include <openssl/sha.h>

#import "XMPPConnection.h"
#import "ETXMLParser.h"
#import "query_jabber_iq_auth.h"
#import "StreamFeatures.h"
#import "DefaultHandler.h"
#import "Presence.h"
#import "XMPPAccount.h"
//TODO: Remove this
#import "../JabberApp.h"
//#import "XMLLog.h"
#import "NSData+Base64.h"


static NSMutableDictionary * connections = nil;

static NSDictionary * STANZA_CLASSES;
static NSDictionary * STANZA_KEYS;

// Only bother with locking if we are in thread-safe mode.
#ifdef THREAD_SAFE
#define LOCK(x) [x lock]
#define UNLOCK(x) [x unlock]
#else
#define LOCK(x)
#define UNLOCK(x)
#endif

@protocol XMLLogging
+ (void) logIncomingXML:(NSString*)xml;
+ (void) logOutgoingXML:(NSString*)xml;
@end

@implementation XMPPConnection
+ (void) initialize
{
	//Initialise OpenSSL
	SSL_library_init();
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
	
}

+ (id) connectionWithAccount:(NSString*)_account
{
	XMPPConnection * connection;
	if(connections == nil)
	{
		connections = [[NSMutableDictionary alloc] init];
	}
	
	connection = [connections objectForKey:_account];
	
	if(connection == nil)
	{
		connection = [XMPPConnection alloc];
		[connections setObject:connection forKey:_account];
		[connection initWithAccount:_account];
		[connection autorelease];
	}
	return connection;
}


- (id) init
{
	connectionState = offline;
	unsentBuffer = [[NSMutableString alloc] init];
	//TODO: Make this more sensible
	res = @"StepChat";
	keepalive = 0;
	connectionMutex = [[NSLock alloc] init];
	messageIDMutex = [[NSLock alloc] init];
	//Get the log class, if it has been built
	xmlLog = NSClassFromString(@"XMLLog");
	return [super init];
}

- (id) initWithAccount:(id)_account
{
	account = _account;
	if(![account isKindOfClass:[XMPPAccount class]])
	{
		[self release];
		return nil;
	}
	roster = [(XMPPAccount*)account roster];
	
	DefaultHandler * defaultHandler = [[[DefaultHandler alloc] initWithAccount:account] autorelease];
	dispatcher = [[Dispatcher dispatcherWithDefaultIqHandler:roster
											 messageHandler:defaultHandler
											presenceHandler:roster]
		retain];
	return [self init];
}

- (void) reconnectToJabberServerInNewThread:(id)_nil
{
	[[NSAutoreleasePool alloc] init];
	connectThread = [NSThread currentThread];
	NSLog(@"Connecting");
	if(connectionState != offline)
	{
		[self disconnect];
	}
	
	struct hostent * host;
	struct sockaddr_in serverAddress;
	
	
	host = gethostbyname([server UTF8String]);
	if(host == NULL)
	{
		NSLog(@"gethostbyname gave error %d.  Connect failing\n", h_errno);
		return;
	}
	serverAddress.sin_family = AF_INET;
	serverAddress.sin_addr.s_addr = ((struct in_addr *)host->h_addr_list[0])->s_addr;
	serverAddress.sin_port = htons(5223);
	
	sslContext = SSL_CTX_new(SSLv23_client_method());
	ssl = SSL_new(sslContext);
	//Initialise the socket
	s = socket(PF_INET, SOCK_STREAM, 0);
	
	//Connect
	if(connect(s, (struct sockaddr*) &serverAddress, sizeof(serverAddress)))
	{
		NSLog(@"Connection error: %d", errno);
		[[NSException exceptionWithName:@"Socket Error" reason:@"Error Connecting" userInfo:nil] raise];
	}
	else
	{
		SSL_set_fd(ssl,s);
		if(SSL_connect(ssl) == 1)
		{
			
		}
		NSLog(@"Connected");
		connectionState = connected;
		[self XMPPSend:
			[NSString stringWithFormat:@"<?xml version='1.0' encoding='UTF-8' ?><stream:stream to='%@' xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>",
				server]];
	}
	while(connectionState != loggedIn)
	{
		[self parseXMPP:self];
	}
	connectThread = nil;
	[NSThread exit];
}

- (void) reconnectToJabberServer
{
	NSLog(@"Connecting...");
	if(connectionState != offline)
	{
		[self disconnect];
	}
	
	struct hostent * host;
	struct sockaddr_in serverAddress;
	
	NSLog(@"Looking up host %@,(%s)", serverHost, [serverHost UTF8String]);
	host = gethostbyname([serverHost UTF8String]);
	//host = gethostbyname("66.116.97.186");
	if(host == NULL)
	{
		NSLog(@"gethostbyname gave error %d.  Connect failing\n", h_errno);
		return;
	}
	serverAddress.sin_family = AF_INET;
	serverAddress.sin_addr.s_addr = ((struct in_addr *)host->h_addr_list[0])->s_addr;
	serverAddress.sin_port = htons(5223);
	
	sslContext = SSL_CTX_new(SSLv23_client_method());
	ssl = SSL_new(sslContext);
	//Initialise the socket
	s = socket(PF_INET, SOCK_STREAM, 0);
	fcntl(s,F_SETFL,O_NONBLOCK);
	
	int connectSuccess = connect(s, (struct sockaddr*) &serverAddress, sizeof(serverAddress));
	//Connect
	if(connectSuccess != 0 && errno != EINPROGRESS)
	{
		NSLog(@"Connection error: %d", errno);
		[[NSException exceptionWithName:@"Socket Error" reason:@"Error Connecting" userInfo:nil] raise];
	}
	connectionState = connecting;
	//Initialise the parser
	[parser release];
	parser = [[ETXMLParser alloc] init];
	[parser setContentHandler:self];
	//Check for incoming Jabber messages 10 times per second
	if(timer == nil)
	{
		[self setTimer:[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)0.1 
														target:self
													  selector:@selector(parseXMPP:) 
													  userInfo:nil
													   repeats:YES]];		
	}	
}

//Connect to an XMPP server.
- (void) connectToJabberServer:(NSString*) jabberServer 
					   withJID:(JID*) aJID
					  password:(NSString*) password
{
	user = [[aJID node] retain];
	server = [[aJID domain] retain];
	pass = [password retain];
	if(jabberServer == nil)
	{
		serverHost = [server retain];
	}
	else
	{
		serverHost = [jabberServer retain];
	}
	NSLog(@"Connecting to %@ with username %@ and password %@", serverHost, user, pass);
	[self reconnectToJabberServer];
}

- (void) disconnect
{
	if(connectionState == loggedIn)
	{
		[self XMPPSend:@"</stream:stream>"];
		//Clean up the connection
		[timer invalidate];
		timer = nil;
		connectionState = disconnecting;
		//Keep fetching data until we have retreived everything that was queue'd by the server, then disconnect.
		while([self parseXMPP:self]);		
	}
}

- (void)characters:(NSString *)_chars
{
	NSLog(@"Unexpected CDATA encountered in <stream:stream /> tag:\n\%@", _chars);
}

- (void) send:(const char*) buffer
{
	NSLog(@"Sending %s", buffer);
	int sent;
	int error;
	int len = strlen(buffer);
	while(len > 0)
	{
		//e = send(s, sendBuffer, len, 0);
		sent = SSL_write(ssl,buffer,len);
		if(sent <= 0)
		{
			error = SSL_get_error(ssl, sent);
			while(error == SSL_ERROR_WANT_WRITE || error == SSL_ERROR_WANT_READ)
			{
				sent = SSL_write(ssl,buffer,len);
				if(sent <= 0)
				{
					error = SSL_get_error(ssl, sent);					
				}
				else
				{
					error = SSL_ERROR_NONE;
				}
			}
			if(error != SSL_ERROR_NONE)
			{
				NSLog(@"Sending error: %d",error);
				if(connectionState != offline)
				{
					connectionState = offline;
					[self reconnectToJabberServer];
					return; //Silently discard data send during connection failure - trying to send it would probably keep breaking us
				}			
			}
		}
		len -= sent;
		buffer += sent;
	}	
}

- (BOOL) parseXMPP:(id)sender
{
	if([sender isKindOfClass:[NSTimer class]] && sender != timer)
	{
		[sender invalidate];
	}
	if(connectionState == offline)
	{
		return NO;
	}
	
	//LOCK(connectionMutex);
	{
		//TODO: Make this into an ivar.
		static char buffer[2000];
		ssize_t dataLength;

		if(connectionState == connecting)
		{
			fd_set writable;
			fd_set except;
			
			struct timeval timeout;
			
			FD_ZERO(&writable);
			FD_ZERO(&except);
			
			FD_SET(s, &writable);
			FD_SET(s, &except);
			
			timeout.tv_sec = 0;
			timeout.tv_usec = 10;
			
			select(s + 1,(fd_set*)NULL, &writable, &except, &timeout);
			if(FD_ISSET(s, &writable))
			{
				SSL_set_fd(ssl,s);
				if(SSL_connect(ssl) == 1)
				{
					NSLog(@"SSL_connect returned 1.  Is it meant to do that?");
				}
				timeout.tv_sec = 1;
				select(s + 1,(fd_set*)NULL , &writable, (fd_set*)NULL, &timeout);
				NSLog(@"Connected");
				connectionState = connected;
				[self send:
					[[NSString stringWithFormat:@"<?xml version='1.0' encoding='UTF-8' ?><stream:stream to='%@' xmlns='jabber:client' version='1.0' xmlns:stream='http://etherx.jabber.org/streams'>",
						server]
						UTF8String]];
				return YES;
			}
			else if(FD_ISSET(s, &except))
			{
				connectionState = offline;
				[timer invalidate];
				timer = nil;
			}
			return NO;
		}
		
		dataLength = SSL_read(ssl,buffer,1500);
		if(dataLength > 0)
		{
			keepalive = 0;
			NSString * parseString;
			buffer[dataLength] = 0;
			parseString = [[NSString stringWithUTF8String:buffer] retain];
			[xmlLog logIncomingXML:parseString];
			[parser parseFromSource:parseString];
		}
		else if(dataLength <= 0 && connectionState == disconnecting)
		{
			connectionState = offline;
/*			SSL_free(ssl);
			SSL_CTX_free(sslContext);
			close(s);*/
			return NO;
		}		
		else if(dataLength < 0)
		{
			if(SSL_get_error(ssl,dataLength) != SSL_ERROR_WANT_READ)
			{
				if(connectionState != disconnecting)
				{
					connectionState = offline;
					[self reconnectToJabberServer];
				}
			}
		}
		keepalive++;
		if(keepalive > 500)
		{
			keepalive = 0;
			[self XMPPSend:@" "];
		}
		return YES;
	}
	//This line should never be reached - it exists to get rid of a compiler warning
	return NO;
}

//Digest non-SASL auth.
- (void) legacyLogIn
{
	if(connectionState != connected)
	{
		return;
	}
	ETXMLNode * authIq = [ETXMLNode ETXMLNodeWithType:@"iq"];
	query_jabber_iq_auth * query = [query_jabber_iq_auth queryWithUsername:user password:pass resource:res];
	NSString * newMessageID = [self newMessageID];
	
	[dispatcher addIqResultHandler:self forID:newMessageID];
	[authIq set:@"id" to:newMessageID];
	[authIq set:@"type" to:@"set"];
	[authIq set:@"to" to:server];
	[query setSessionID:sessionID];
	[authIq addChild:(ETXMLNode*)query];
	
	[self send:[[authIq stringValue] UTF8String]];
	connectionState = loggingIn;
}

- (void)startElement:(NSString *)aName
		  attributes:(NSDictionary *)_attributes
{
	NSLog(@"Parsing element: %@", aName);
	
	if([aName isEqualToString:@"stream:stream"])
	{
		sessionID = [[_attributes objectForKey:@"id"] retain];
		[server release];
		server = [[_attributes objectForKey:@"from"] retain];
		if(![[_attributes objectForKey:@"version"] isEqualToString:@"1.0"])
		{
			[self legacyLogIn];
		}
	}
	else if ([aName isEqualToString:@"success"])
	{
		//Once we're authenticated, re-initialise the stream...ha
		connectionState = unbound;
		NSString * newStream = [NSString stringWithFormat:@"<stream:stream to='%@' xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams' version='1.0'>",
                                server];
		[self send:[newStream UTF8String]];
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
	/*
	 if([aFeatureSet containsObject:@"DIGEST-MD5"])
	 {
		 //Send auth mechanism
		 [self XMPPSend:[[ETXMLNode ETXMLNodeWithType:@"auth"
										   attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																						   @"urn:ietf:params:xml:ns:xmpp-sasl", @"xmlns",
											   @"DIGEST-MD5", @"mechanism",
											   nil]] stringValue]];
	 }
	 */
	if([aFeatureSet containsObject:@"PLAIN"])
	{
		//Send auth mechanism
		ETXMLNode * authNode = [ETXMLNode ETXMLNodeWithType:@"auth"
												 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																								 @"urn:ietf:params:xml:ns:xmpp-sasl", @"xmlns",
													 @"PLAIN", @"mechanism",
													 nil]];
		NSMutableData * authData = [NSMutableData dataWithBytes:"\0" length:1];
		[authData appendData:[user dataUsingEncoding:NSUTF8StringEncoding]];
		[authData appendBytes:"\0" length:1];
		[authData appendData:[pass dataUsingEncoding:NSUTF8StringEncoding]];
		NSString * authstring = [authData base64String];
		[authNode addCData:authstring];
		[self send:[[authNode stringValue] UTF8String]];
		connectionState = loggingIn;
	}
	else
	{
		NSLog(@"No supported authentication mechanisms found.  Aborting.");
	}		
}

- (void) startSession
{
	NSString * sessionIqID = [self newMessageID];
	ETXMLNode * sessionNode = [ETXMLNode ETXMLNodeWithType:@"session"
												attributes:[NSDictionary dictionaryWithObject:@"urn:ietf:params:xml:ns:xmpp-session"
																					   forKey:@"xmlns"]];
	ETXMLNode * iqNode = [ETXMLNode ETXMLNodeWithType:@"iq"
										   attributes:[NSDictionary dictionaryWithObjectsAndKeys:
											   @"set", @"type",
											   sessionIqID, @"id",
											   nil]];
	[iqNode addChild:sessionNode];
	[self send:[[iqNode stringValue] UTF8String]];
	[dispatcher addIqResultHandler:self forID:sessionIqID];
}

- (void) bind
{
	//Bind to a resource
	//<iq type='set' id='bind_2'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'><resource>someresource</resource></bind></iq>
	NSString * bindID = [self newMessageID];
	ETXMLNode * resourceNode = [ETXMLNode ETXMLNodeWithType:@"resource"];
	[resourceNode addCData:res];
	ETXMLNode * bindNode = [ETXMLNode ETXMLNodeWithType:@"bind"
											 attributes:[NSDictionary dictionaryWithObject:@"urn:ietf:params:xml:ns:xmpp-bind" 
																					forKey:@"xmlns"]];
	[bindNode addChild:resourceNode];
	ETXMLNode * iqNode = [ETXMLNode ETXMLNodeWithType:@"iq"
										   attributes:[NSDictionary dictionaryWithObjectsAndKeys:
											   @"set", @"type",
											   bindID, @"id",
											   nil]];
	[iqNode addChild:bindNode];
	[self send:[[iqNode stringValue] UTF8String]];
	[dispatcher addIqResultHandler:self forID:bindID];	
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
- (void) addstreamFeatures:(NSDictionary*) aFeatureSet
{
	NSLog(@"Stream features has retain count %d", [streamFeatures retainCount]);
	[streamFeatures release];
	streamFeatures = [aFeatureSet retain];
	//If we are connected, try logging in
	if(connectionState == connected)
	{
		//Hack for broken servers
		if([[aFeatureSet objectForKey:@"auth"] isEqualToString:@"http://jabber.org/features/iq-auth"])
		{
			[self legacyLogIn];
		}
		else
		{
			[self logInWithMechansisms:[aFeatureSet objectForKey:@"mechanisms"]];
		}
	}
	else if (connectionState == unbound)
	{
		if ([aFeatureSet objectForKey:@"bind"] != nil)
		{
			[self bind];
		}
		else if ([aFeatureSet objectForKey:@"session"] != nil)
		{
			connectionState = noSession;
			[self startSession];
		}
		else
		{
			connectionState = loggedIn;
		}
	}
}
//END child stanza handlers

- (void)endElement:(NSString *)_Name
{
	if([_Name isEqualToString:@"stream:stream"])
	{
		if(connectionState != loggedIn)
		{
			/*
			Jesse says: we need some other kind of solution here since we don't have
			a -connectionFailed method anymore... not sure what to do. I commented it
			out since it was causing XCode's build to fail.
			
			if([[NSApp delegate] respondsToSelector:@selector(connectionFailed:)])
			{
				[(JabberApp*)[NSApp delegate] connectionFailed:account];
			}
			*/
		}
		//If we have not manually disconnected, try to reconnect.
		else if(connectionState != offline)
		{
			[self reconnectToJabberServer];
		}
		connectionState = offline;
		[presenceDisplay setPresence:PRESENCE_OFFLINE withMessage:@"Disconnected"];
	}
	
}

- (void) setPresenceDisplay:(id<XMPPPresenceDisplay,NSObject>)_display
{
	[presenceDisplay release];
	presenceDisplay = [_display retain];
}

- (void) handleIq:(Iq*)anIq
{
	if(connectionState == unbound)
	{
		if ([streamFeatures objectForKey:@"session"] != nil)
		{
			connectionState = noSession;
			[self startSession];
		}
		else
		{
			connectionState = loggedIn;			
		}
	}
	else if (connectionState == loggingIn)
	{
		connectionState = loggedIn;
		//TODO: Check that this actually is the response to the old-style auth request
	}
	else if (connectionState == noSession)
	{
		connectionState = loggedIn;
	}
	if((connectionState == loggedIn) && ([anIq type] == IQ_TYPE_RESULT))
	{
		NSString * newMessageID = [self newMessageID];
		ETXMLNode * rosterQuery = [ETXMLNode ETXMLNodeWithType:@"iq"]; 
		ETXMLNode * query = [ETXMLNode ETXMLNodeWithType:@"query" attributes:nil];
		
		[dispatcher addIqResultHandler:roster forID:newMessageID];
		
		[query set:@"xmlns" to:@"jabber:iq:roster"];
		[rosterQuery set:@"id" to:newMessageID];
		[rosterQuery set:@"type" to:@"get"];
		//[rosterQuery set:@"to" to:server];
		[rosterQuery addChild:query];
		
		connectionState = loggedIn;
		
		[self XMPPSend:[rosterQuery stringValue]];
		//				[self XMPPSend:unsentBuffer];
		[unsentBuffer setString:@""];
	}
	
}




- (NSString*) newMessageID
{
	LOCK(messageIDMutex);
	unsigned int i = messageID++;
	UNLOCK(messageID);
	return [NSString stringWithFormat:@"TRXMPP_%d", i];
}

- (void) XMPPSend: (NSString*) buffer
{
	[xmlLog logOutgoingXML:buffer];
	//LOCK(connectionMutex);
	{
		char * sendBuffer = (char*)[buffer UTF8String];
		//If we are not connected, buffer the input until we are.
		if(connectionState != loggedIn)
		{
			if(unsentBuffer == nil)
			{
				unsentBuffer = [[NSMutableString alloc] init];
			}
			//TODO:  Don't do this for </stream:stream>, it is very silly
			[unsentBuffer appendString:buffer];
			return;
		}
		if(unsentBuffer != nil)
		{
			[self send:[unsentBuffer UTF8String]];
			[unsentBuffer release];
			unsentBuffer = nil;
		}
		[self send:sendBuffer];
		keepalive = 0;
	}
}

- (void) setTimer:(NSTimer*)newTimer
{
	if(timer != nil)
	{
		[timer release];
	}
	timer = [newTimer retain];
}

- (ConnectionState) connected
{
	return connectionState;
}

- (void) setStatus:(unsigned char)_status withMessage:(NSString*)_message
{
	ETXMLNode * presenceNode = [ETXMLNode ETXMLNodeWithType:@"presence"];
	if(_status == PRESENCE_OFFLINE)
	{
		[presenceNode set:@"type" to:@"unavailable"];
	}
	if(_status != PRESENCE_ONLINE)
	{
		ETXMLNode * showNode = [ETXMLNode ETXMLNodeWithType:@"show"];
		
		[showNode setCData:[Presence xmppStringForPresence:_status]];
		[presenceNode addChild:showNode];
	}
	NSDictionary * presenceDictionary;
	if(_message != nil)
	{
		ETXMLNode * statusNode = [ETXMLNode ETXMLNodeWithType:@"status"];
		[statusNode setCData:_message];
		[presenceNode addChild:statusNode];
		presenceDictionary = 
			[NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithChar:_status],@"show",
				_message,@"status",
				nil];
	}
	else
	{
		presenceDictionary = [NSDictionary dictionaryWithObject:[NSNumber numberWithChar:_status] forKey:@"show"];
	}
	//Notify anyone who cares that our presence has changed
	NSNotificationCenter * local = [NSNotificationCenter defaultCenter];
	NSNotificationCenter * remote = [NSDistributedNotificationCenter defaultCenter];
	[local postNotificationName:@"LocalPresenceChangedNotification"
						 object:account
					   userInfo:presenceDictionary];
	[remote postNotificationName:@"LocalPresenceChangedNotification"
						  object:[account name]
						userInfo:presenceDictionary];
	//[presenceDisplay setPresence:_status withMessage:_message];
	[self XMPPSend:[presenceNode stringValue]];
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

- (void) dealloc
{
	[super dealloc];
}
@end
