//
//  IqStanzaFactory.m
//  Jabber
//
//  Created by David Chisnall on 25/05/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "IqStanzaFactory.h"

#import "Iq.h"

static IqStanzaFactory * sharedInstance;

@implementation IqStanzaFactory
+ (void) initialize
{
	sharedInstance = [[IqStanzaFactory alloc] init];
	//Insert default handlers here:
	//Roster updates:
	[sharedInstance addHandler:NSClassFromString(@"Query_jabber_iq_roster")
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
	[sharedInstance addHandler:NSClassFromString(@"DiscoItems")
						forTag:@"query" 
				   inNamespace:@"http://jabber.org/protocol/disco#items"];
	[sharedInstance addValue:@"DiscoItems"
					  forTag:@"query" 
				 inNamespace:@"http://jabber.org/protocol/disco#items"];
		[sharedInstance addHandler:NSClassFromString(@"DiscoInfo")
						forTag:@"query" 
				   inNamespace:@"http://jabber.org/protocol/disco#info"];
	[sharedInstance addValue:@"DiscoItems"
					  forTag:@"query" 
				 inNamespace:@"http://jabber.org/protocol/disco#items"];
}

+ (id) sharedStazaFactory
{
	return sharedInstance;
}
- (id) parser
{
	return [[Iq alloc] init];
}
@end

