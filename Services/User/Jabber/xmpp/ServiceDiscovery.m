//
//  ServiceDiscovery.m
//  Jabber
//
//  Created by David Chisnall on 18/02/2005.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "ServiceDiscovery.h"


static const NSString * xmlnsDiscoInfo = @"http://jabber.org/protocol/disco#info";
static const NSString * xmlnsDiscoItems = @"http://jabber.org/protocol/disco#items";

@implementation ServiceDiscovery
- (ServiceDiscovery*) initWithAccount:(XMPPAccount*)xmppaccount
{
	self = [self init];
	if(!self)
	{
		return nil;
	}
	account = [xmppaccount retain];
	cache = [[NSMutableDictionary alloc] init];
	returnHandlers = [[NSMutableDictionary alloc] init];
	return self;
}

//Return the capabilities if we know them
- (Capabilities*) getCapabilitiesForJID:(JID*)jid atNode:(NSString*)node
{
	NSDictionary * nodes = [cache objectForKey:[node jidString]];
	Capabilities * caps;
	if(node == nil)
	{
		caps = [nodes objectForKey:@""];
	}
	else
	{
		caps = [nodes objectForKey:node];		
	}
	//If we have not already disco'd this node
	if(caps == nil)
	{
		NSString * messageID = [[account connection] newMessageID];
		TRXMLNode * queryNode = [TRXMLNode TRXMLNodeWithType:@"iq"
												  attributes:[NSDictionary dictionaryWithObjectsAndKeys:
													  messageID,@"id",
													  @"get",@"type",
													  nil]];
		if(node == nil)
		{
			[queryNode addChild:[TRXMLNode TRXMLNodeWithType:@"query" 
												  attributes:[NSDictionary dictionaryWithObjectsAndKeys:
													  xmlnsDiscoInfo, @"xmlns",
													  nil]]];
		}
		else
		{
			[queryNode addChild:[TRXMLNode TRXMLNodeWithType:@"query" 
												  attributes:[NSDictionary dictionaryWithObjectsAndKeys:
													  xmlnsDiscoInfo, @"xmlns",
													  node, @"node",
													  nil]]];
		}
		[[[account connection] dispatcher] addIqResultHandler:self forID:messageID];
		[[account connection] XMPPSend:[queryNode toXML]];
	}
	return caps;
}

- (void) invalidateCacheForJID:(JID*)jid
{
	NSString * jidString = [jid jidString];
	[cache removeObjectForKey:jidString];
	[knownNodes removeObjectForKey:jidString];
}


- (void) handleNode:(TRXMLNode*)node fromDispatcher:(id)_dispatcher
{
	if([[node getType] isEqualToString:@"iq"])
	{
		NSString * nodeID = [xml get:@"id"];
		if([[node get:@"type"] isEqualToString:@"result"])
		{
			TRXMLNode * query = [[xml getChildrenWithName:@"query"] anyObject];
			Capabilities * caps = [[Capabilities alloc] initFromXML:query];
			//Cache capabilities
			[cache setObject:caps forKey:from];
			//Send notification
			NSInvocation * invocation = [returnHandlers objectForKey:nodeID];
			[returnHandlers removeObjectForKey:nodeID];
			[invocation setArgument:caps atIndex:2];
			[invocation invoke];
			[invocation release];
		}
		else if([[node get:@"type"] isEqualToString:@"get"])
		{
			
		}
	}
}

- (void) dealloc
{
	[account release];
	[cache release];
	[knownNodes release];
	[super dealloc];
}

@end


