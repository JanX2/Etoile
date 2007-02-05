//
//  MessageStanzaFactory.m
//  Jabber
//
//  Created by David Chisnall on 24/05/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "MessageStanzaFactory.h"
#import "TRXML/TRXMLString.h"
#import "TRXMLXHTML-IMParser.h"
#import "Message.h"

static MessageStanzaFactory * sharedInstance;

@implementation MessageStanzaFactory
+ (void) initialize
{
	sharedInstance = [[MessageStanzaFactory alloc] init];
	//Insert default handlers here:
	[sharedInstance addHandler:[TRXMLString class] forTag:@"body"];
	[sharedInstance addHandler:[TRXMLString class] forTag:@"subject"];
	[sharedInstance addHandler:[Timestamp class] forTag:@"x" inNamespace:@"jabber:x:delay"];
#ifndef WITHOUT_XHTML_IM
//	[sharedInstance addHandler:[TRXMLXHTML_IMParser class] forTag:@"html"];
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
