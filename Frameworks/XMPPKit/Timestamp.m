//
//  Timestamp.m
//  Jabber
//
//  Created by David Chisnall on 20/08/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "Timestamp.h"
#import <EtoileFoundation/EtoileFoundation.h>

@implementation Timestamp
+ (id) timestampWithTime:(NSCalendarDate*)_time reason:(NSString*)_reason
{
	return [[[Timestamp alloc] initWithTime:_time reason:_reason] autorelease];
}


- (id) init
{
	SUPERINIT;
	value = self;
	reason = [[NSMutableString alloc] init];
	return self;
}

- (void)characters:(NSString *)chars
{
	[reason appendString:chars];
}
/*
 <x from='capulet.com'
 stamp='20020910T23:08:25'
 xmlns='jabber:x:delay'>
 Offline Storage
 </x>
 */
- (void)startElement:(NSString *)aName
		  attributes:(NSDictionary*)attributes
{
	if([aName isEqualToString:@"x"] 
	   &&
	   [[attributes objectForKey:@"xmlns"] isEqualToString:@"jabber:x:delay"])
	{
		depth++;
		NSString * stamp = [attributes objectForKey:@"stamp"];
		time = [[NSCalendarDate dateWithYear:[[stamp substringWithRange:NSMakeRange(0,4)] intValue]
									   month:[[stamp substringWithRange:NSMakeRange(4,2)] intValue] 
										 day:[[stamp substringWithRange:NSMakeRange(6,2)] intValue] 
										hour:[[stamp substringWithRange:NSMakeRange(9,2)] intValue] 
									  minute:[[stamp substringWithRange:NSMakeRange(12,2)] intValue] 
									  second:[[stamp substringWithRange:NSMakeRange(15,2)] intValue] 
									timeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]]
			retain];
		[time setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
	}
	else
	{
		[[[ETXMLNullHandler alloc] initWithXMLParser:parser
											  parent:parent
												 key:nil] startElement:aName
															attributes:attributes];
	}
}

- (id) initWithTime:(NSCalendarDate*)_time reason:(NSString*)_reason
{
	reason = [_reason retain];
	time = [_time retain];
	return [super init];
}

- (NSCalendarDate*) time
{
	return time;
}

- (NSString*) reason
{
	return reason;
}

- (NSString*) stamp
{
	return [time descriptionWithCalendarFormat:@"%Y%m%dT%H:%M:%S"];
}

- (NSComparisonResult) compare:(Timestamp*)_other
{
	return [time compare:[_other time]];
}


- (void) dealloc
{
	[time release];
	[reason release];
	[super dealloc];
}
@end
