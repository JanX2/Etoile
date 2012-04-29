//
//  XMPPTimestamp.m
//  Jabber
//
//  Created by David Chisnall on 20/08/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XMPPTimestamp.h"
#import <EtoileFoundation/EtoileFoundation.h>

@implementation XMPPTimestamp
+ (id) timestampWithTime:(NSCalendarDate*)_time reason:(NSString*)_reason
{
        return [[XMPPTimestamp alloc] initWithTime:_time reason:_reason];
}


- (id) initWithXMLParser: (ETXMLParser*)aParser
                  parent: (id <ETXMLParserDelegate>) aParent
                     key: (id) aKey
{
        self = [super initWithXMLParser: aParser
                                    key: aKey];
        if (nil == self)
        {
                return nil;
        }
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
                time = [NSCalendarDate dateWithYear:[[stamp substringWithRange:NSMakeRange(0,4)] intValue]
                                                                           month:[[stamp substringWithRange:NSMakeRange(4,2)] intValue] 
                                                                                 day:[[stamp substringWithRange:NSMakeRange(6,2)] intValue] 
                                                                                hour:[[stamp substringWithRange:NSMakeRange(9,2)] intValue] 
                                                                          minute:[[stamp substringWithRange:NSMakeRange(12,2)] intValue] 
                                                                          second:[[stamp substringWithRange:NSMakeRange(15,2)] intValue] 
                                                                        timeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
                [time setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        }
        else
        {
                [[[ETXMLNullHandler alloc] initWithXMLParser:parser
                                                         key:nil] startElement:aName
                                                  attributes:attributes];
        }
}

- (id) initWithTime:(NSCalendarDate*)_time reason:(NSString*)_reason
{
        reason = [_reason mutableCopy];
        time = _time;
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

- (NSComparisonResult) compare:(XMPPTimestamp*)_other
{
        return [time compare:[_other time]];
}


@end
