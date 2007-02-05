//
//  PresenceStanzaFactory.m
//  Jabber
//
//  Created by David Chisnall on 25/05/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "PresenceStanzaFactory.h"
#import "Presence.h"
#import "TRXML/TRXMLString.h"

static PresenceStanzaFactory * sharedInstance;

@implementation PresenceStanzaFactory
+ (void) initialize
{
	sharedInstance = [[PresenceStanzaFactory alloc] init];
	//Insert default handlers here:
	[sharedInstance addHandler:[TRXMLString class] forTag:@"show"];
	[sharedInstance addHandler:[TRXMLString class] forTag:@"status"];
	[sharedInstance addHandler:[TRXMLString class] forTag:@"priority"];
	//Replace the status message with an error message if one exists.
	[sharedInstance addHandler:[TRXMLString class] withValue:@"status" forTag:@"error" ];
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
