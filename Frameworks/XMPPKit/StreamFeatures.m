//
//  StreamFeatures.m
//  Jabber
//
//  Created by David Chisnall on 05/06/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "StreamFeatures.h"
#import <EtoileXML/ETXMLString.h>
#import <EtoileFoundation/EtoileFoundation.h>

@implementation StreamFeatures
- (id) initWithXMLParser: (ETXMLParser*)aParser
                  parent: (id <ETXMLParserDelegate>)aParent
                     key: (id)aKey
{
	self = [super initWithXMLParser: aParser
	                         parent: aParent
	                            key: aKey];
	if (nil == self)
	{
		return nil;
	}
	features = [[NSMutableDictionary alloc] init];
	[features setObject:[NSMutableArray array] forKey:@"mechanisms"];
	[value autorelease];
	value = features;
	return self;
}
- (void)startElement:(NSString *)aName
		  attributes:(NSDictionary*)attributes;
{
	if([aName isEqualToString:@"stream:features"] || [aName isEqualToString:@"mechanisms"])
	{
		depth++;
	}
	else if([aName isEqualToString:@"mechanism"])
	{
		[[[ETXMLString alloc] initWithXMLParser:parser
										 parent:self
											key:@"mechanism"] startElement:aName
																attributes:attributes];
	}
	else
	{
		[features setObject:[attributes objectForKey:@"xmlns"] forKey:aName];
		[[[ETXMLNullHandler alloc] initWithXMLParser:parser
											  parent:self
												 key:nil] startElement:aName
															attributes:attributes];
	}
}

- (void) addmechanism:(NSString*)aMechanism
{
	[[features objectForKey:@"mechanisms"] addObject:aMechanism]; 
}

- (void) dealloc 
{
	[features release];
	[super dealloc];
}


@end
