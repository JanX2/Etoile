//
//  XMPPDiscoItems.m
//  Jabber
//
//  Created by David Chisnall on 14/11/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "XMPPDiscoItems.h"
#import <EtoileFoundation/EtoileFoundation.h>

@implementation XMPPDiscoItems
- (id) initWithXMLParser: (ETXMLParser*)aParser
                     key: (id) aKey
{
	self = [super initWithXMLParser: aParser
	                            key: aKey];
	if (nil == self)
	{
		return nil;
	}
	items = [[NSMutableArray alloc] init];
	[value autorelease];
	value = [self retain];
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
