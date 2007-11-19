//
//  Stanza.m
//  Jabber
//
//  Created by David Chisnall on 19/11/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "Stanza.h"
#import "Macros.h"

@implementation Stanza
- (id) init
{
	SUPERINIT;
	children = [[NSMutableDictionary alloc] init];
	return self;
}
- (void) addChild:(id)aChild forKey:(NSString*)aKey
{
	[children setValue:aChild forKey:aKey];
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
