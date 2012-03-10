//
//  XMPPStreamFeatures.m
//  Jabber
//
//  Created by David Chisnall on 05/06/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "XMPPStreamFeatures.h"
#import <EtoileXML/ETXMLString.h>
#import <EtoileFoundation/EtoileFoundation.h>

@implementation XMPPStreamFeatures
- (id) initWithXMLParser: (ETXMLParser*)aParser
                     key: (id)aKey
{
	self = [super initWithXMLParser: aParser
	                            key: aKey];
	if (nil == self)
	{
		return nil;
	}
	features = [[NSMutableDictionary alloc] init];
	[features setObject:[NSMutableArray array] forKey:@"mechanisms"];
	NSLog(@"Key is %@", aKey);
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
						    key:@"mechanism"] startElement:aName
															     attributes:attributes];
	}
	else
	{
		[features setObject:[attributes objectForKey:@"xmlns"] forKey:aName];
		[[[ETXMLNullHandler alloc] initWithXMLParser:parser
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
