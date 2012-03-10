//
//  XMPPStanza.m
//  Jabber
//
//  Created by David Chisnall on 19/11/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "XMPPStanza.h"
#import <EtoileFoundation/EtoileFoundation.h>

@implementation XMPPStanza
- (id) initWithXMLParser: (ETXMLParser*) aParser
                     key: (id) aKey
{
	self = [super initWithXMLParser: aParser
	                            key: aKey];
	if (nil == self)
	{
		return nil;
	}
	children = [[NSMutableDictionary alloc] init];
	return self;
}
- (void) addChild:(id)aChild forKey:(id)aKey
{
	NSString * childSelectorName = [NSString stringWithFormat:@"add%@:", aKey];
	SEL childSelector = NSSelectorFromString(childSelectorName);
	if([self respondsToSelector:childSelector])
	{
		[self performSelector:childSelector withObject:aChild];
	}
	else
	{
		[children setValue:aChild forKey:aKey];
	}	
}
- (NSDictionary*) children
{
	return children;
}
- (void) dealloc
{
	[children release];
	[super dealloc];
}
@end
