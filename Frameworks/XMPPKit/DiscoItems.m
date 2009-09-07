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
- (id) initWithXMLParser: (ETXMLParser*)aParser
                  parent: (id <ETXMLParserDelegate>) aParent
                     key: (id) aKey
{
	self = [super initWithXMLParser: aParser
	                         parent: aParent
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
