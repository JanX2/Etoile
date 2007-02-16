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
	[sharedInstance addHandler:NSClassFromString(@"Query_jabber_iq_roster")
						forTag:@"query" 
				   inNamespace:@"jabber:iq:roster"];
	[sharedInstance addValue:@"RosterItems"
					  forTag:@"query" 
				 inNamespace:@"jabber:iq:roster"];
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

