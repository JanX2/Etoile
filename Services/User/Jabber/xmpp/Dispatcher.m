//
//  Dispatcher.m
//  Jabber
//
//  Created by David Chisnall on Sun May 23 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//


#import "Dispatcher.h"
#import "JID.h"
#import "../Macros.h"

@implementation Dispatcher

+ (id) dispatcherWithDefaultIqHandler:(id <IqHandler>)iq 
					   messageHandler:(id <MessageHandler>)message 
					  presenceHandler:(id <PresenceHandler>)presence
{
	return [[[Dispatcher alloc] initWithDefaultIqHandler:iq 
										 messageHandler:message 
										presenceHandler:presence] 
		autorelease];
}

- (id) initWithDefaultIqHandler:(id <IqHandler>)iq 
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
	messageHandlers = [[NSMutableDictionary alloc] init];
	presenceHandlers = [[NSMutableDictionary alloc] init];
	
	return [super init];
}

- (id) addIqResultHandler:(id <IqHandler>)handler forID:(NSString*)iqID
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

- (void) dispatch:(TRXMLNode*)node
{
/*	NSMutableSet * handlers = nil;
	id <DispatchDelegate> defaultHandler = nil;
	if([[node getType] isEqualToString:@"message"])
	{
		NSString * jidString = [node get:@"from"];
		handlers = [messageHandlers objectForKey:jidString];
		if(handlers == nil)
		{
			JID *  jid = [[JID jidWithString:[node get:@"from"]] retain];
			handlers = [messageHandlers objectForKey:[jid jidStringWithNoResource]];
			if(handlers == nil)
			{
				handlers = [[NSMutableSet alloc] init];
				[messageHandlers setObject:handlers forKey:[jid jidStringWithNoResource]];
				[handlers release];
			}
		}
		defaultHandler = defaultMessageHandler;
	}
	else if([[node getType] isEqualToString:@"presence"])
	{
		NSString * jidString = [node get:@"from"];
		handlers = [presenceHandlers objectForKey:jidString];
		if(handlers == nil)
		{
			JID *  jid = [JID jidWithString:[node get:@"from"]];
			handlers = [presenceHandlers objectForKey:[jid jidStringWithNoResource]];
			if(handlers == nil)
			{
				handlers = [[NSMutableSet alloc] init];
				[presenceHandlers setObject:handlers forKey:[jid jidStringWithNoResource]];
				[handlers release];
			}
		}
		defaultHandler = defaultPresenceHandler;
	}
	else if([[node getType] isEqualToString:@"iq"])
	{
		NSString * nodeId = [node get:@"id"];
		if(nodeId != nil)
		{
			handlers = [iqHandlers objectForKey:nodeId];
			if(handlers == nil)
			{
				handlers = [[NSMutableSet alloc] init];
				[iqHandlers setObject:handlers forKey:[node get:@"id"]];
				[handlers release];
			}
		}
		defaultHandler = defaultIqHandler;
	}
	NSEnumerator * handlerList = [handlers objectEnumerator];
	id <DispatchDelegate> currentHandler;
	while((currentHandler = [handlerList nextObject]))
	{
		[currentHandler handleNode:node fromDispatcher:self];
	}
	[defaultHandler handleNode:node fromDispatcher:self];*/
}

- (void) dispatchMessage:(Message*)aMessage
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

- (void) dispatchPresence:(Presence*)aPresence
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

- (void) dispatchIq:(Iq*)anIq
{
	//TODO: namespaced handlers for 'get's.
	NSMutableSet * handlers = [iqHandlers valueForKey:[anIq sequenceID]];
	FOREACH(handlers, iqHandler, id<IqHandler>)
	{
		[iqHandler handleIq:anIq];
	}
	[defaultIqHandler handleIq:anIq];
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
