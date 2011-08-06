//
//  XMPPConversation.m
//  Jabber
//
//  Created by David Chisnall on 17/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XMPPConversation.h"
#import "XMPPObjectStore.h"
#import "XMPPMessage.h"

static NSMutableDictionary * conversations = nil;
static Class delegateClass = Nil;

static NSMutableArray * filters;


@implementation XMPPConversation
+ (void) initialize
{
	conversations = [[NSMutableDictionary alloc] init];
	filters = [[NSMutableArray alloc] init];
	[super initialize];
}
+ (void) setViewClass:(Class)aClass
{
	if([aClass conformsToProtocol:@protocol(XMPPConversationDelegate)])
	{
		delegateClass = aClass;
	}
}
- (id) initWithPerson:(XMPPPerson*)corespondent forAccount:(XMPPAccount*)_account
{
	SELFINIT;
	connection = [_account connection];
	name = [[corespondent name] retain];
	remoteJID = [[[corespondent defaultIdentity] jid] retain];
	remotePerson = [corespondent retain];
	//Register to receive any updates to this person's presence.  This will let us switch to a different default corespondent if required
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(updatePresence:) 
												 name:@"TRXMPPIdentityPresenceChanged" 
											   object:remotePerson];
	return self;
}

- (id) init
{
	SUPERINIT;
	connection = nil;
	return self;
}

+ (id) conversationWithPerson:(XMPPPerson*)corespondent forAccount:(XMPPAccount*)_account
{
	if(conversations == nil)
	{
		conversations = [[NSMutableDictionary alloc] init];
	}
	XMPPConversation * conversation = [conversations objectForKey:corespondent];
	if(conversation == nil)
	{
		conversation = [[XMPPConversation alloc] initWithPerson:corespondent forAccount:_account];
		[conversations setObject:conversation
						  forKey:corespondent];
		[conversation release];
	}
	return conversation;
}

+ (id) conversationForPerson:(XMPPPerson*)corespondent
{
	return [conversations objectForKey:corespondent];
}
+ (void) releaseAllXMPPConversations
{
	NSEnumerator * enumerator = [conversations objectEnumerator];
	for(id conversation = [enumerator nextObject] ; conversation != nil ; conversation = [enumerator nextObject])
	{
		[conversation release];
	}
}

- (void) handleMessage:(XMPPMessage*)aMessage
{
	FOREACH(filters, filter, id<MessageFilter>)
	{
		[filter filterMessage:aMessage];
	}
	if([aMessage shouldDisplay])
	{
		[delegate displayMessage:aMessage incoming:YES];
	}
}

- (id<NSObject,XMPPConversationDelegate>) delegate
{
	return delegate;
}

- (void) setDelegate:(id<NSObject,XMPPConversationDelegate>)_delegate
{
	[delegate release];
	delegate = [_delegate retain];
	XMPPPresence * presence = [[remotePerson defaultIdentity] presence];
	[delegate setPresence:[presence show] 
			  withMessage:[presence status]];
	[delegate newRemoteJID:[[remotePerson defaultIdentity] jid]];
}

- (void) sendText:(id)_message
{
	XMPPMessage * newMessage = [XMPPMessage messageWithBody:_message for:remoteJID withSubject:nil type:MESSAGE_TYPE_CHAT];
	[delegate displayMessage:newMessage incoming:NO];
	[newMessage writeToXMLWriter: [connection xmlWriter]];
}

- (XMPPObjectStore*) objectStoreForObjectWithUUID: (ETUUID*)uuid
                                   andApplication: (NSString*)registeredName
{
	XMPPMessage *newMessage = [XMPPMessage messageWithBody: nil  for:remoteJID
	                                   withSubject: nil type: MESSAGE_TYPE_CHAT];
	[newMessage beginWritingToXMLWriter: [connection xmlWriter]];
	XMPPObjectStore *store = [[[XMPPObjectStore alloc] initWithXMLWriter: [connection xmlWriter]
	                                                      inConversation: self] autorelease];
	[store beginObjectWithUUID: uuid andApplication: registeredName];
	return store;
}

//If the corespondent's presence changes, we may wish to talk to a different one of their identities.  Check this, then update the UI.
- (void) updatePresence:(NSNotification*)_notification
{
	JID * defaultJID = [[remotePerson defaultIdentity] jid];
	//Are we still talking to the same person?
	if(![remoteJID isEqual:defaultJID])
	{
		if([delegate newRemoteJID:defaultJID])
		{
			remoteJID = [remoteJID retain];
		}
	}
	XMPPPresence * presence = [[remotePerson identityForJID:remoteJID] presence];
	[delegate setPresence:[presence show] withMessage:[presence status]];
}

- (JID*) remoteJID
{
	return remoteJID;
}

- (XMPPPerson*) remotePerson
{
	return remotePerson;
}

- (void) setJID:(JID*)jid
{
	if([delegate newRemoteJID:jid])
	{
		[remoteJID release];
		remoteJID = [jid retain];
		//Update the presence display in the UI as well
		XMPPPresence * presence = [[remotePerson identityForJID:remoteJID] presence];
		[delegate setPresence:[presence show] withMessage:[presence status]];		
	}
}

- (NSString*) name
{
	return name;
}
@end

