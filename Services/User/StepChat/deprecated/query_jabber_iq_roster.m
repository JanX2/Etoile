//
//  query_jabber_iq_roster.m
//  Jabber
//
//  Created by David Chisnall on Sun Apr 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "query_jabber_iq_roster.h"
#import "roster_item.h"

@implementation query_jabber_iq_roster
- (id) init
{
	nodeType = @"query";
	return [super init];
}
- (void)startElement:(NSString *)_localName
		   namespace:(NSString *)_ns
			 rawName:(NSString *)_rawName
		  attributes:(NSDictionary *)_attributes
{
	NSLog([@"Parsing element:" stringByAppendingString:_localName]);

	if([_localName isEqualToString:@"item"])
	{
		id itemNode = [[roster_item itemWithJID:[_attributes objectForKey:@"jid"] 
								  subscription:[_attributes objectForKey:@"subscription"] 
										  name:[_attributes objectForKey:@"name"]] retain];
		[itemNode setParser:parser];
		[itemNode setParent:self];
		[parser setContentHandler:itemNode];
	}
	else
	{
		[super startElement:_localName
				  namespace:_ns
					rawName:_rawName
				 attributes:_attributes];
	}	
}

- (NSString*) toXML:(NSString *)flags
{
	//TODO:  This won't work for set queries.
	return @"<query xmlns=\"jabber:iq:roster\"/>";
}

@end
