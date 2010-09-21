//
//  iq.m
//  Jabber
//
//  Created by David Chisnall on Thu Apr 22 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "iq.h"
#import "query_jabber_iq_roster.h"

@implementation iq

+ (id) iqWithID:(NSString*) nodeID
{
	return [[[iq alloc] initWithID:nodeID] autorelease];
}

- (id) initWithID:(NSString*) nodeID
{
	XMPPID = [nodeID retain];
	return [self init];
}

- (id) init
{
	nodeType = @"iq";
	return [super init];
}

- (void) setDestination:(NSString*) destination
{
	[to release];
	to = [destination retain];
}

- (NSString*) getDestingation
{
	return to;
}

- (void) setOrigin:(NSString*) origin
{
	[from release];
	from = [origin retain];
}

- (NSString*) getOrigin
{
	return from;
}

- (void) setIQType:(NSString*) newType
{
	if([newType isEqualToString:@"set"])
	{
		type = set;
	} 
	else if([newType isEqualToString:@"get"])
	{
		type = get;
	} 
	else if([newType isEqualToString:@"error"])
	{
		type = error;
	} 
	else if([newType isEqualToString:@"result"])
	{
		type = result;
	} 
	else
	{
		[[NSException exceptionWithName:@"Invalid IQ type" reason:nil userInfo:nil] raise];		
	}
	
}

- (NSString*) getIQType
{
	switch(type)
	{
		case set:
			return @"set";
		case get:
			return @"get";
		case error:
			return @"error";
		case result:
			return @"result";
	}
	//This line is never reached, and is here simly to eliminate a compiler warning
	return @"";
}

- (NSString*) toXML:(NSString *)flags
{
	int child;
	NSString * XML;
	NSMutableString * childrenXML = [[NSMutableString alloc] init];
	
	for(child = 0 ; child < [children count] ; child++)
	{
		[childrenXML appendString:[[children objectAtIndex:child] toXML:flags]];
	}		
	XML = [NSString stringWithFormat:@"<iq type=\"%@\" to=\"%@\" id=\"%@\">\n%@</iq>",[self getIQType],to,XMPPID,childrenXML];
	[childrenXML release];
	return XML;
}

- (void)startElement:(NSString *)_localName
		   namespace:(NSString *)_ns
			 rawName:(NSString *)_rawName
		  attributes:(NSDictionary *)_attributes
{
	NSLog([@"Parsing element:" stringByAppendingString:_localName]);
	
	if([_localName isEqualToString:@"query"])
	{
		if([_ns isEqualToString:@"jabber:iq:roster"])
		{
			id queryNode = [[query_jabber_iq_roster alloc] init];
			[queryNode setParser:parser];
			[queryNode setParent:self];
			[parser setContentHandler:queryNode];
		}
		else
		{
			[super startElement:_localName
					  namespace:_ns
						rawName:_rawName
					 attributes:_attributes];
		}
	}
	else
	{
		[super startElement:_localName
				  namespace:_ns
					rawName:_rawName
				 attributes:_attributes];
	}
}

- (NSString*)getID
{
	return XMPPID;
}

- (void) dealloc
{
	[XMPPID release];
	[super dealloc];
}
@end
