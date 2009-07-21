//
//  ServiceDiscovery.m
//  Jabber
//
//  Created by David Chisnall on 18/02/2005.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "ServiceDiscovery.h"
#import "XMPPAccount.h"
#import "DiscoInfo.h"
#import "DiscoItems.h"

static NSString * xmlnsDiscoInfo = @"http://jabber.org/protocol/disco#info";
static NSString * xmlnsDiscoItems = @"http://jabber.org/protocol/disco#items";

@implementation ServiceDiscovery
- (ServiceDiscovery*) initWithAccount:(XMPPAccount*)account
{
	SELFINIT;
	features = [[NSMutableDictionary alloc] init];
	myFeatures = [[NSMutableSet alloc] init];
	//Feature must be supported
	[myFeatures addObject:@"http://jabber.org/protocol/disco#info"];
	//TODO: Put these initialisations somewhere sensible.
	[myFeatures addObject:@"http://jabber.org/protocol/xhtml-im"];
	children = [[NSMutableDictionary alloc] init];
	capabilitiesPerJID = [[NSMutableDictionary alloc] init];
	featuresForCapabilities = [[NSMutableDictionary alloc] init];
	dispatcher = [[[account roster] dispatcher] retain];
	connection = [[account connection] retain];
	[dispatcher addIqQueryHandler:self forNamespace:xmlnsDiscoInfo];
	[dispatcher addIqQueryHandler:self forNamespace:xmlnsDiscoItems];
	return self;
}
- (void) setCapabilities:(NSString*)caps forJID:(JID*)aJid
{
	NSString * jid = [aJid jidString];
	[capabilitiesPerJID setObject:caps forKey:jid];
	if([featuresForCapabilities objectForKey:caps] == nil)
	{
		[self featuresForJID:aJid node:nil];
	}
}
- (void) sendQueryToJID:(const NSString*)jid node:(const NSString*)node inNamespace:(const NSString*)xmlns
{
	ETXMLWriter *xmlWriter = [connection xmlWriter];
	NSString * iqID = [connection newMessageID];
	[xmlWriter startElement: @"iq"
	             attributes: D(@"get", @"type",
	                           jid, @"to",
	                           iqID, @"id")];
	if(node == nil)
	{
		[xmlWriter startAndEndElement: @"query"
		                   attributes: D(xmlns, @"xmlns",
		                                 node, @"node")];
	}
	else
	{
		[xmlWriter startAndEndElement: @"query"
		                   attributes: D(xmlns, @"xmlns")];
	}
	[xmlWriter endElement]; //</iq>
	[dispatcher addIqResultHandler: self forID: iqID];
}
- (NSDictionary*) infoForJID:(JID*)aJid node:(NSString*)aNode
{
	NSString * jid = [aJid jidString];
	NSString * node = aNode;
	if(aNode == nil)
	{
		node = @"";
	}
	NSDictionary * result = [[features objectForKey:jid] objectForKey:node];
	//If we haven't already got these values, request them
	if(result == nil)
	{
		NSString * caps = [capabilitiesPerJID objectForKey:jid];
		if(caps != nil)
		{
			result = [featuresForCapabilities objectForKey:caps];
		}
		else
		{
			[self sendQueryToJID:jid node:node inNamespace:xmlnsDiscoInfo];
		}
	}
	return result;
}
- (NSArray*) identitiesForJID:(JID*)aJid node:(NSString*)aNode
{
	NSDictionary * info = [self infoForJID:aJid node:aNode];
	return [info objectForKey:@"identities"];
}
- (NSArray*) featuresForJID:(JID*)aJid node:(NSString*)aNode
{
	NSDictionary * info = [self infoForJID:aJid node:aNode];
	return [info objectForKey:@"features"];
}
- (NSArray*) itemsForJID:(JID*)aJid node:(NSString*)aNode
{
	NSString * jid = [aJid jidString];
	NSString * node = aNode;
	if(aNode == nil)
	{
		node = @"";
	}
	NSArray * result = [[children objectForKey:jid] objectForKey:node];
	//If we haven't already got these values, request them
	if(result == nil)
	{
		[self sendQueryToJID:jid node:node inNamespace:xmlnsDiscoItems];
	}
	return result;
}
- (void) handleIq:(Iq*)anIQ
{
	NSString * jid = [[anIQ jid] jidString];
	switch([anIQ type])
	{
		case IQ_TYPE_GET:
		{
			if([[anIQ queryNamespace] isEqualToString:xmlnsDiscoInfo])
			{
				ETXMLWriter *xmlWriter = [connection xmlWriter];
				[xmlWriter startElement: @"iq"
				             attributes: D(@"result", @"type",
				                           jid, @"to",
				                           [anIQ sequenceID], @"id")];
				[xmlWriter startElement: @"query"
				             attributes: D(xmlnsDiscoInfo, @"xmlns")];
				//TODO: Make the type configurable
				[xmlWriter startElement: @"identity"
				             attributes: D(@"client", @"category",
				                           @"pc", @"type")];
				FOREACH(myFeatures, feature, NSString*)
				{
					[xmlWriter startAndEndElement: @"feature"
					                   attributes: D(feature, @"var")];
				}
				[xmlWriter endElement]; // </identity>
				[xmlWriter endElement]; // </query>
				[xmlWriter endElement]; // </iq>
			}
			break;
		}
		case IQ_TYPE_RESULT:
		{
			DiscoInfo * info = [[anIQ children] objectForKey:@"DiscoInfo"];
			DiscoItems * items = [[anIQ children] objectForKey:@"DiscoItems"];
			if(info != nil)
			{
				NSDictionary * nodeInfo = D([info identities], @"identities",
				                            [info features], @"features");
				NSString * node = [info node];
				if(node == nil)
				{
					node = @"";
				}
				NSMutableDictionary * nodes = [features objectForKey:jid];
				if(nodes == nil)
				{
					nodes = [NSMutableDictionary dictionary];
					[features setObject:nodes forKey:jid];
				}
				[nodes setObject:nodeInfo forKey:node];
				NSString * caps = [capabilitiesPerJID objectForKey:jid];
				if(caps != nil)
				{
					[featuresForCapabilities setObject:nodeInfo forKey:caps];
				}
				[[NSNotificationCenter defaultCenter] 
					postNotificationName: @"DiscoFeaturesFound"
					              object: self
					            userInfo: D(jid, @"jid")];
			}
			if(items != nil)
			{
				NSArray * nodeItems = [items items];
				NSString * node = [items node];
				if(node == nil)
				{
					node = @"";
				}
				NSMutableDictionary * nodes = [children objectForKey:jid];
				if(nodes == nil)
				{
					nodes = [NSMutableDictionary dictionary];
					[children setObject:nodes forKey:jid];
				}
				[nodes setObject:nodeItems forKey:node];
				[[NSNotificationCenter defaultCenter] 
					postNotificationName: @"DiscoItemsFound"
					              object: self
					            userInfo: D(jid, @"jid")];
			}
		}
		default: {}
	}
}
- (void) addFeature:(NSString*)aFeature
{
	[myFeatures addObject:aFeature];
}

- (void) dealloc
{
	[connection release];
	[myFeatures release];
	[dispatcher release];
	[knownNodes release];
	[super dealloc];
}

@end


