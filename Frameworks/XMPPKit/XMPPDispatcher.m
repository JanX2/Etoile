//
//  XMPPDispatcher.m
//  Jabber
//
//  Created by David Chisnall on Sun May 23 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//


#import "XMPPDispatcher.h"
#import "JID.h"
#import <EtoileFoundation/EtoileFoundation.h>

@implementation XMPPDispatcher

+ (id) dispatcherWithDefaultInfoQueryHandler:(id <XMPPInfoQueryStanzaHandler>)iq 
					   messageHandler:(id <MessageHandler>)message 
					  presenceHandler:(id <PresenceHandler>)presence
{
	return [[[XMPPDispatcher alloc] initWithDefaultInfoQueryHandler:iq 
										 messageHandler:message 
										presenceHandler:presence] 
		autorelease];
}

- (id) initWithDefaultInfoQueryHandler:(id <XMPPInfoQueryStanzaHandler>)iq 
				 messageHandler:(id <MessageHandler>)message 
				presenceHandler:(id <PresenceHandler>)presence
{
	defaultIqHandler = [iq retain];
	defaultMessageHandler = [message retain];
	defaultPresenceHandler = [presence retain];
	return [self init];
}
- (id) init
{
	iqHandlers = [[NSMutableDictionary alloc] init];
	iqNamespaceHandlers = [[NSMutableDictionary alloc] init];
	messageHandlers = [[NSMutableDictionary alloc] init];
	presenceHandlers = [[NSMutableDictionary alloc] init];
	
	return [super init];
}

- (id) addInfoQueryHandler:(id <XMPPInfoQueryStanzaHandler>)handler forNamespace:(NSString*)aNamespace
{
	NSMutableSet * handlers = [iqNamespaceHandlers valueForKey:aNamespace];
	if(handlers == nil)
	{
		handlers = [[NSMutableSet alloc] init];
		[iqNamespaceHandlers setObject:handlers forKey:aNamespace];
		[handlers release];
	}
	[handlers addObject:handler];
	return self;
}

- (id) addInfoQueryResultHandler:(id <XMPPInfoQueryStanzaHandler>)handler forID:(NSString*)iqID
{
	NSMutableSet * handlers = [iqHandlers valueForKey:iqID];
	if(handlers == nil)
	{
		handlers = [[NSMutableSet alloc] init];
		[iqHandlers setObject:handlers forKey:iqID];
		[handlers release];
	}
	[handlers addObject:handler];
	return self;
}

- (id) addMessageHandler:(id <MessageHandler>)handler ForJID:(NSString*)jid
{
	NSMutableSet * handlers = [messageHandlers valueForKey:jid];
	if(handlers == nil)
	{
		handlers = [[NSMutableSet alloc] init];
		[messageHandlers setObject:handlers forKey:jid];
		[handlers release];
	}
	[handlers addObject:handler];
	return self;
}

- (id) addPresenceHandler:(id <PresenceHandler>)handler ForJID:(NSString*)jid
{
	NSMutableSet * handlers = [presenceHandlers valueForKey:jid];
	if(handlers == nil)
	{
		handlers = [[NSMutableSet alloc] init];
		[presenceHandlers setObject:handlers forKey:jid];
		[handlers release];
	}
	[handlers addObject:handler];
	return self;
}
- (void) dispatchMessage:(XMPPMessage*)aMessage
{
	JID * jid = [aMessage correspondent];
	NSMutableSet * handlers = [messageHandlers objectForKey:[jid jidString]];
	if(handlers == nil)
	{
		handlers = [messageHandlers objectForKey:[jid jidStringWithNoResource]];
		if(handlers == nil)
		{
			handlers = [[NSMutableSet alloc] init];
			[messageHandlers setObject:handlers forKey:[jid jidStringWithNoResource]];
			[handlers release];
		}
	}
	//TODO:  Make this a proper protocol thing
	FOREACH(handlers, handler, id<MessageHandler>)
	{
		[handler handleMessage:aMessage];
	}
	[defaultMessageHandler handleMessage:aMessage];
}

- (void) dispatchPresence:(XMPPPresence*)aPresence
{
	NSMutableSet * handlers = [presenceHandlers valueForKey:[[aPresence jid] jidString]];
	FOREACH(handlers, presenceHandler, id<PresenceHandler>)
	{
		[presenceHandler handlePresence:aPresence];
	}
	if (![[[aPresence jid] jidStringWithNoResource] isEqualToString:[[aPresence jid] jidString]])
	{
		handlers = [presenceHandlers valueForKey:[[aPresence jid] jidStringWithNoResource]];
		FOREACH(handlers, generalPresenceHandler, id<PresenceHandler>)
		{
			[generalPresenceHandler handlePresence:aPresence];
		}
	}
	[defaultPresenceHandler handlePresence:aPresence];
}

- (void) dispatchInfoQuery:(XMPPInfoQueryStanza*)anIq
{
	iq_type_t type = [anIq type];
	if(type == IQ_TYPE_SET || type == IQ_TYPE_GET)
	{
		NSMutableSet * handlers = [iqNamespaceHandlers valueForKey:[anIq queryNamespace]];
		FOREACH(handlers, iqHandler, id<XMPPInfoQueryStanzaHandler>)
		{
			[iqHandler handleInfoQuery:anIq];
		}		
	}
	else
	{
		NSMutableSet * handlers = [iqHandlers valueForKey:[anIq sequenceID]];
		FOREACH(handlers, iqHandler, id<XMPPInfoQueryStanzaHandler>)
		{
			[iqHandler handleInfoQuery:anIq];
		}
	}
	[defaultIqHandler handleInfoQuery:anIq];
}

- (void) dealloc
{
	[iqHandlers release];
	[messageHandlers release];
	[presenceHandlers release];
	[defaultIqHandler release];
	[defaultMessageHandler release];
	[defaultPresenceHandler release];
	[super dealloc];
}
@end
