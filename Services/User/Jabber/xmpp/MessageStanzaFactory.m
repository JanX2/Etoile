//
//  MessageStanzaFactory.m
//  Jabber
//
//  Created by David Chisnall on 24/05/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "MessageStanzaFactory.h"
#import "ETXMLString.h"
#import "ETXMLXHTML-IMParser.h"
#import "XMPPError.h"
#import "Message.h"

static MessageStanzaFactory * sharedInstance;

@implementation MessageStanzaFactory
+ (void) initialize
{
	sharedInstance = [[MessageStanzaFactory alloc] init];
	//Insert default handlers here:
	[sharedInstance addHandler:[ETXMLString class] forTag:@"body"];
	[sharedInstance addHandler:[ETXMLString class] forTag:@"subject"];
	[sharedInstance addHandler:[Timestamp class] withValue:@"timestamp" forTag:@"x" inNamespace:@"jabber:x:delay"];
	[sharedInstance addHandler:[XMPPError class] forTag:@"error"];
#ifndef WITHOUT_XHTML_IM
	[sharedInstance addHandler:[ETXMLXHTML_IMParser class] forTag:@"html"];
#endif
}

+ (id) sharedStazaFactory
{
	return sharedInstance;
}
- (id) parser
{
	return [[Message alloc] init];
}
@end
