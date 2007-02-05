//
//  Iq.m
//  Jabber
//
//  Created by David Chisnall on 30/05/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "Iq.h"
#import "IqStanzaFactory.h"
#import "JabberIdentity.h"
#import "Macros.h"

static NSDictionary * TYPES;

@implementation Iq
+ (void) initialize
{
	TYPES = [[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:IQ_TYPE_SET], @"set",
		[NSNumber numberWithInt:IQ_TYPE_GET], @"get",
		[NSNumber numberWithInt:IQ_TYPE_RESULT], @"result",
		[NSNumber numberWithInt:IQ_TYPE_ERROR], @"error",
		nil] retain];
}
- (id) init
{
	SUPERINIT;
	children = RETAINED(NSMutableDictionary);
	return self;
}

- (void)startElement:(NSString *)aName
		  attributes:(NSDictionary*)attributes;
{
	if([aName isEqualToString:@"iq"])
	{
		depth++;
		type = [[TYPES objectForKey:[attributes objectForKey:@"type"]] intValue];
		jid = [[JID alloc] initWithString:[attributes objectForKey:@"from"]];
		sequenceID = [[attributes objectForKey:@"id"] retain];
	}
	else
	{
		IqStanzaFactory * factory = [IqStanzaFactory sharedStazaFactory];
		NSString * xmlns = [attributes objectForKey:@"xmlns"];
		Class handler = [factory handlerForTag:aName inNamespace:xmlns];
		NSString * elementKey = [factory valueForTag:aName inNamespace:xmlns];
		[[[handler alloc] initWithXMLParser:parser
									 parent:self
										key:elementKey] startElement:aName
														  attributes:attributes];
		
	}
}
- (NSString*) sequenceID
{
	return sequenceID;
}

- (JID*) jid
{
	return jid;
}

- (iq_type_t) type
{
	return type;
}

//TODO:  Put this in a Stanza class, and make it a common superclass of Iq, Message and Presence
- (void) addChild:(id)aChild forKey:aKey
{
	[children setValue:aChild forKey:aKey];
}

- (NSDictionary*) children
{
	return children;
}
@end
