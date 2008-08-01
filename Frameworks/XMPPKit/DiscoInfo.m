//
//  DiscoInfo.m
//  Jabber
//
//  Created by David Chisnall on 14/11/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "DiscoInfo.h"
#include "Macros.h"

#define ATTRIBUTE(x) [attributes objectForKey:x], x

@implementation DiscoInfo
- (id) init
{
	SUPERINIT;
	identities = [[NSMutableArray alloc] init];
	features = [[NSMutableArray alloc] init];
	value = self;
	return self;
}
- (void)startElement:(NSString *)aName
          attributes:(NSDictionary*)attributes
{
	if([aName isEqualToString:@"identity"])
	{
		[identities addObject:attributes];
	}
	else if([aName isEqualToString:@"feature"])
	{
		[features addObject:[attributes objectForKey:@"var"]];
	}
	else if([aName isEqualToString:@"query"])
	{
		node = [[attributes objectForKey:@"node"] retain];
	}
	depth++;
}
- (NSArray*) identities
{
	return identities;
}
- (NSArray*) features
{
	return features;
}
- (NSString*) node
{
	return node;
}
- (void) dealloc 
{
	[identities release];
	[features release];
	[node release];
	[super dealloc];
}
@end
