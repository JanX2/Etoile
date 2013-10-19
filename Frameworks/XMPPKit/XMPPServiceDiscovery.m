//
//  XMPPServiceDiscovery.m
//  Jabber
//
//  Created by David Chisnall on 18/02/2005.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "XMPPServiceDiscovery.h"
#import "XMPPAccount.h"
#import "XMPPDiscoInfo.h"
#import "XMPPDiscoItems.h"

static NSString * xmlnsXMPPDiscoInfo = @"http://jabber.org/protocol/disco#info";
static NSString * xmlnsXMPPDiscoItems = @"http://jabber.org/protocol/disco#items";

@implementation XMPPServiceDiscovery
- (XMPPServiceDiscovery*) initWithAccount:(XMPPAccount*)account
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
	dispatcher = [[account roster] dispatcher];
	connection = [account connection];
	[dispatcher addInfoQueryHandler:self forNamespace:xmlnsXMPPDiscoInfo];
	[dispatcher addInfoQueryHandler:self forNamespace:xmlnsXMPPDiscoItems];
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
	NSString * iqID = [connection nextMessageID];
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
	[dispatcher addInfoQueryResultHandler: self forID: iqID];
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
			[self sendQueryToJID:jid node:node inNamespace:xmlnsXMPPDiscoInfo];
		}
	}
	return result;
}
- (NSArray*) identitiesForJID:(JID*)aJid node:(NSString*)aNode
{
	NSDictionary * infoDictionary = [self infoForJID:aJid node:aNode];
	return [infoDictionary objectForKey:@"identities"];
}
- (NSArray*) featuresForJID:(JID*)aJid node:(NSString*)aNode
{
	NSDictionary * infoDictionary = [self infoForJID:aJid node:aNode];
	return [infoDictionary objectForKey:@"features"];
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
		[self sendQueryToJID:jid node:node inNamespace:xmlnsXMPPDiscoItems];
	}
	return result;
}
- (void) handleInfoQuery:(XMPPInfoQueryStanza*)anIQ
{
	NSString * jid = [[anIQ jid] jidString];
	switch([anIQ type])
	{
		case IQ_TYPE_GET:
		{
			if([[anIQ queryNamespace] isEqualToString:xmlnsXMPPDiscoInfo])
			{
				ETXMLWriter *xmlWriter = [connection xmlWriter];
				[xmlWriter startElement: @"iq"
				             attributes: D(@"result", @"type",
				                           jid, @"to",
				                           [anIQ sequenceID], @"id")];
				[xmlWriter startElement: @"query"
				             attributes: D(xmlnsXMPPDiscoInfo, @"xmlns")];
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
			info = [[anIQ children] objectForKey:@"XMPPDiscoInfo"];
			items = [[anIQ children] objectForKey:@"XMPPDiscoItems"];
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
					postNotificationName: @"XMPPDiscoFeaturesFound"
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
					postNotificationName: @"XMPPDiscoItemsFound"
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

- (XMPPDiscoInfo*) info
{
	return info;
}

- (XMPPDiscoItems*) items
{
	return items;
}


@end


