//
//  DiscoItems.m
//  Jabber
//
//  Created by David Chisnall on 14/11/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "DiscoItems.h"
#import <EtoileFoundation/EtoileFoundation.h>

@implementation DiscoItems
- (id) init
{
	SUPERINIT;
	items = [[NSMutableArray alloc] init];
	value = self;
	return self;
}
- (void)startElement:(NSString *)aName
          attributes:(NSDictionary*)attributes
{
	if([aName isEqualToString:@"item"])
	{
		[items addObject:attributes];
	}
	else if([aName isEqualToString:@"query"])
	{
		node = [[attributes objectForKey:@"node"] retain];
	}
	depth++;
}
- (NSArray*) items
{
	return items;
}
- (NSString*) node
{
	return node;
}
- (void) dealloc 
{
	[items release];
	[super dealloc];
}
@end
