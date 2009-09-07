//
//  presence.m
//  Jabber
//
//  Created by David Chisnall on Sun Apr 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "Presence.h"
#import "PresenceStanzaFactory.h"

int PRESENCE_ICONS[] = {
	0x25C9,
	0x25C9,
	0x25C8,
	0x25C8,
	0x25A3,
	0x25CE,
	0x25CE
};


@implementation Presence
+ (NSString*) displayStringForPresence:(unsigned char)_presence
{
	switch(_presence)
	{
		case PRESENCE_CHAT:
			return @"Free For Chat";
		case PRESENCE_ONLINE:
			return @"Online";
		case PRESENCE_AWAY:
			return @"Away";
		case PRESENCE_XA:
			return @"Extended Away";
		case PRESENCE_DND:
			return @"Do Not Disturb";
		case PRESENCE_OFFLINE:
			return @"Offline";
	}	
	return @"Unknown";
}

+ (NSString*) xmppStringForPresence:(unsigned char)_presence
{
	switch(_presence)
	{
		case PRESENCE_CHAT:
			return @"chat";
		case PRESENCE_ONLINE:
			return @"online";
		case PRESENCE_AWAY:
			return @"away";
		case PRESENCE_XA:
			return @"xa";
		case PRESENCE_DND:
			return @"dnd";
	}	
	return @"unknown";
}

+ (unsigned char) presenceForXMPPString:(NSString*)_presence
{
	if([_presence rangeOfString:@"online"].location != NSNotFound)
	{
		return PRESENCE_ONLINE;
	}
	if([_presence rangeOfString:@"away"].location != NSNotFound)
	{
		return PRESENCE_AWAY;
	}
	if([_presence rangeOfString:@"xa"].location != NSNotFound)
	{
		return PRESENCE_XA;
	}
	if([_presence rangeOfString:@"dnd"].location != NSNotFound)
	{
		return PRESENCE_DND;
	}
	if([_presence rangeOfString:@"offline"].location != NSNotFound)
	{
		return PRESENCE_OFFLINE;
	}
	if([_presence rangeOfString:@"chat"].location != NSNotFound)
	{
		return PRESENCE_CHAT;
	}
	return PRESENCE_UNKNOWN;
}

- (void)startElement:(NSString *)aName
		  attributes:(NSDictionary *)attributes
{
	if ([aName isEqualToString:@"presence"])
	{
		depth++;
		from = [[JID jidWithString:[attributes objectForKey:@"from"]] retain];
		NSString * presenceType = [attributes objectForKey:@"type"];
		priority = 0;
		onlineStatus = PRESENCE_UNKNOWN;
		//NSLog(@"Presence from %@: %@", [attributes objectForKey:@"from"], presenceType);
		if(presenceType == nil || [presenceType isEqualToString:@"online"])
		{
			NSLog(@"Online");
			onlineStatus = PRESENCE_ONLINE;
			type = online;
		}
		else if([presenceType isEqualToString:@"unavailable"])
		{
			type = unavailable;
			onlineStatus = PRESENCE_OFFLINE;
		}
		else if([presenceType isEqualToString:@"subscribe"])
		{
			type = subscribe;
		}
		else if([presenceType isEqualToString:@"unsubscribe"])
		{
			type = unsubscribe;
		}
		else if([presenceType isEqualToString:@"subscribed"])
		{
			type = subscribed;
		}
		else if([presenceType isEqualToString:@"unsubscribed"])
		{
			type = unsubscribed;
		}
		else
		{
			//NSLog(@"Presence stanza with unknown type received.");
		}
	}
	else if([aName isEqualToString:@"c"])
	{
		caps = [[attributes objectForKey:@"ver"] retain];
		depth++;
	}
	else
	{
		PresenceStanzaFactory * factory = [PresenceStanzaFactory sharedStazaFactory];
		NSString * xmlns = [attributes objectForKey:@"xmlns"];
		Class handler = [factory handlerForTag:aName inNamespace:xmlns];
		NSString * elementKey = [factory valueForTag:aName inNamespace:xmlns];
		[[[handler alloc] initWithXMLParser:parser
									 parent:self
										key:elementKey] startElement:aName
														  attributes:attributes];
		
	}
}

// Sub-stanza KVC handlers
- (void) addshow:(NSString*)show
{
	onlineStatus = [Presence presenceForXMPPString:show];			
}
- (void) addstatus:(NSString*)status
{
	message = [status retain];
}
- (void) setpriority:(NSString*)aPriority
{
	priority = [aPriority intValue];
}
- (void) addnickname:(NSString*)aNickname
{
	[nickname release];
	nickname = [aNickname retain];
}

- (id) initWithJID:(JID*)_jid
{
	from = [_jid retain];
	onlineStatus = PRESENCE_UNKNOWN;
	message = @"Status Unknown";
	return [super init];
}


- (id) initWithXMLParser: (ETXMLParser*)aParser
                  parent: (id <ETXMLParserDelegate>)aParent
                     key: (id) aKey
{
	self = [super initWithXMLParser: aParser
	                         parent: aParent
	                            key: aKey];
	if (nil == self)
	{
		return nil;
	}
	from = [[JID alloc] init];
	onlineStatus = PRESENCE_UNKNOWN;
	message = nil;
	return self;
}

- (unsigned char) show
{
	return onlineStatus;
}

- (NSString*) status
{
	return message;
}

- (NSString*) nickname
{
	return nickname;
}

- (JID*) jid
{
	return from;
}

- (int) priority
{
	return priority;
}

- (PresenceType) type
{
	return type;
}

- (NSString*) caps
{
	return caps;
}

- (NSComparisonResult) compare:(Presence*)_otherPresence
{
	if(onlineStatus < [_otherPresence show])
	{
		return NSOrderedAscending;
	}
	if(onlineStatus > [_otherPresence show])
	{
		return NSOrderedDescending;
	}
	return NSOrderedSame;
}

- (void) dealloc
{
	[from release];
	[message release];
	[nickname release];
	[caps release];
	[super dealloc];
}
@end
