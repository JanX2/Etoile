//
//  XMPPInfoQueryStanzaFactory.m
//  Jabber
//
//  Created by David Chisnall on 25/05/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "XMPPInfoQueryStanzaFactory.h"

#import "XMPPInfoQueryStanza.h"

static XMPPInfoQueryStanzaFactory * sharedInstance;

@implementation XMPPInfoQueryStanzaFactory
+ (void) initialize
{
	sharedInstance = [[XMPPInfoQueryStanzaFactory alloc] init];
	//Insert default handlers here:
	//Roster updates:
	[sharedInstance addHandler:NSClassFromString(@"QueryRosterHandler")
						forTag:@"query" 
				   inNamespace:@"jabber:iq:roster"];
	[sharedInstance addValue:@"RosterItems"
					  forTag:@"query" 
				 inNamespace:@"jabber:iq:roster"];
	//vCards:
	[sharedInstance addHandler:NSClassFromString(@"XMPPvCard")
						forTag:@"vCard" 
				   inNamespace:@"vcard-temp"];
	[sharedInstance addValue:@"vCard"
					  forTag:@"vCard" 
				 inNamespace:@"vcard-temp"];
	//Service Discovery:
	[sharedInstance addHandler:NSClassFromString(@"XMPPDiscoItems")
						forTag:@"query" 
				   inNamespace:@"http://jabber.org/protocol/disco#items"];
	[sharedInstance addValue:@"DiscoItems"
					  forTag:@"query" 
				 inNamespace:@"http://jabber.org/protocol/disco#items"];
		[sharedInstance addHandler:NSClassFromString(@"XMPPDiscoInfo")
						forTag:@"query" 
				   inNamespace:@"http://jabber.org/protocol/disco#info"];
	[sharedInstance addValue:@"DiscoInfo"
					  forTag:@"query" 
				 inNamespace:@"http://jabber.org/protocol/disco#info"];
}

+ (id) sharedStazaFactory
{
	return sharedInstance;
}
- (id) parser
{
	return [[XMPPInfoQueryStanza alloc] init];
}
@end

