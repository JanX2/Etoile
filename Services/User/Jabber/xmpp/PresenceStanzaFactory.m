//
//  PresenceStanzaFactory.m
//  Jabber
//
//  Created by David Chisnall on 25/05/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "PresenceStanzaFactory.h"
#import "Presence.h"
#import <EtoileXML/ETXMLString.h>

static PresenceStanzaFactory * sharedInstance;

@implementation PresenceStanzaFactory
+ (void) initialize
{
	sharedInstance = [[PresenceStanzaFactory alloc] init];
	//Insert default handlers here:
	[sharedInstance addHandler:[ETXMLString class] forTag:@"show"];
	[sharedInstance addHandler:[ETXMLString class] forTag:@"status"];
	[sharedInstance addHandler:[ETXMLString class] forTag:@"nickname"];
	[sharedInstance addHandler:[ETXMLString class] forTag:@"priority"];
	//Replace the status message with an error message if one exists.
	[sharedInstance addHandler:[ETXMLString class] withValue:@"status" forTag:@"error" ];
	//vCard updates
	[sharedInstance addHandler:NSClassFromString(@"XMPPvCardUpdate") 
					 withValue:@"vCardUpdate"
						forTag:@"x"
				   inNamespace:@"vcard-temp:x:update"];
	//TODO: timestamps
}

+ (id) sharedStazaFactory
{
	return sharedInstance;
}
- (id) parser
{
	return [[Presence alloc] init];
}
@end
