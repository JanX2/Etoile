//
//  XMLFunctions.m
//  Vienna
//
//  Created by Steve on 5/27/05.
//  Copyright (c) 2007 Yen-Ju Chen. All rights reserved.
//  Copyright (c) 2004-2005 Steve Palmer. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
// 

#import "XMLTag.h"
#import "XMLFunctions.h"
#import "StringExtensions.h"
#import "CurlGetDate/CurlGetDate.h"

typedef struct
{
	NSString *str;
	NSStringEncoding enc;
} enc_struct;

enc_struct enc_map[] = 
{
	{ @"UTF-8", NSUTF8StringEncoding },
	{ @"ISO-8859-1", NSISOLatin1StringEncoding },
	{ @"US-ASCII", NSASCIIStringEncoding },
	{ @"ANSI_X3.4-1968", NSUTF8StringEncoding },
	{ nil, -1 }
};

/* encodingFromString
 * return encoding based on encoding name 
 */
NSStringEncoding encodingFromString (NSString *encodingString)
{
	int i;
	for (i = 0; enc_map[i].str; i++)
	{
		if ([encodingString compare: enc_map[i].str
		                    options: NSCaseInsensitiveSearch] == NSOrderedSame)
		{
			return enc_map[i].enc;
		}
	}

	NSLog(@"Unknown Encoding: %@", encodingString);
	return NSUTF8StringEncoding;
}

/* quoteAttributes
 * Scan the specified string and convert HTML literal characters to their entity equivalents.
 */
NSString *quoteAttributes (NSString *stringToProcess)
{
	NSMutableString * newString = [NSMutableString stringWithString:stringToProcess];
	[newString replaceString:@"&" withString:@"&amp;"];
	[newString replaceString:@"<" withString:@"&lt;"];
	[newString replaceString:@">" withString:@"&gt;"];
	[newString replaceString:@"\"" withString:@"&quot;"];
	[newString replaceString:@"'" withString:@"&apos;"];
	return newString;
}

/* parseXMLDate
 * Parse a date in an XML header into an NSCalendarDate. This is horribly expensive and needs
 * to be replaced with a parser that can handle these formats:
 *
 *   2005-10-23T10:12:22-4:00
 *   2005-10-23T10:12:22
 *   2005-10-23T10:12:22Z
 *   Mon, 10 Oct 2005 10:12:22 -4:00
 *   10 Oct 2005 10:12:22 -4:00
 *
 * These are the formats that I've discovered so far.
 */
NSCalendarDate *parseXMLDate (NSString *dateString)
{
	int yearValue = 0;
	int monthValue = 1;
	int dayValue = 0;
	int hourValue = 0;
	int minuteValue = 0;
	int secondValue = 0;
	int tzOffset = 0;

	// Let CURL have a crack at parsing since it knows all about the
	// RSS/HTTP formats. Add a hack to substitute UT with GMT as it doesn't
	// seem to be able to parse the former.
	dateString = [dateString trim];
	unsigned int dateLength = [dateString length];
	if ([dateString hasSuffix:@" UT"])
		dateString = [[dateString substringToIndex:dateLength - 3] stringByAppendingString:@" GMT"];
	// CURL seems to require seconds in the time, so add seconds if necessary.
	NSScanner * scanner = [NSScanner scannerWithString:dateString];
	if ([scanner scanUpToString:@":" intoString:NULL])
	{
		unsigned int location = [scanner scanLocation] + 3u;
		if ((location < dateLength) && [dateString characterAtIndex:location] != ':')
		{
			dateString = [NSString stringWithFormat:@"%@:00%@", [dateString substringToIndex:location], [dateString substringFromIndex:location]];
			scanner = [NSScanner scannerWithString:dateString];
		}
	}

	NSCalendarDate * curlDate = [CurlGetDate getDateFromString:dateString];
	if (curlDate != nil)
		return curlDate;

	// Otherwise do it ourselves.
	[scanner setScanLocation:0u];
	if (![scanner scanInt:&yearValue])
		return nil;
	if (yearValue < 100)
		yearValue += 2000;
	if ([scanner scanString:@"-" intoString:NULL])
	{
		if (![scanner scanInt:&monthValue])
			return nil;
		if (monthValue < 1 || monthValue > 12)
			return nil;
		if ([scanner scanString:@"-" intoString:NULL])
		{
			if (![scanner scanInt:&dayValue])
				return nil;
			if (dayValue < 1 || dayValue > 31)
				return nil;
		}
	}

	// Parse the time portion.
	// (I discovered that GMail sometimes returns a timestamp with 24 as the hour
	// portion although this is clearly contrary to the RFC spec. So be
	// prepared for things like this.)
	if ([scanner scanString:@"T" intoString:NULL])
	{
		if (![scanner scanInt:&hourValue])
			return nil;
		hourValue %= 24;
		if ([scanner scanString:@":" intoString:NULL])
		{
			if (![scanner scanInt:&minuteValue])
				return nil;
			if (minuteValue < 0 || minuteValue > 59)
				return nil;
			if ([scanner scanString:@":" intoString:NULL] || [scanner scanString:@"." intoString:NULL])
			{
				if (![scanner scanInt:&secondValue])
					return nil;
				if (secondValue < 0 || secondValue > 59)
					return nil;
				// Drop any fractional seconds
				if ([scanner scanString:@"." intoString:NULL])
				{
					if (![scanner scanInt:NULL])
						return nil;
				}
			}
		}
	}
	else
	{
		// If no time is specified, set the time to 11:59pm,
		// so new articles within the last 24 hours are detected.
		hourValue = 23;
		minuteValue = 59;
	}

	// At this point we're at any potential timezone
	// tzOffset needs to be the number of seconds since GMT
	if ([scanner scanString:@"Z" intoString:NULL])
		tzOffset = 0;
	else if (![scanner isAtEnd])
	{
		if (![scanner scanInt:&tzOffset])
			return nil;
		if (tzOffset > 12)
			return nil;
	}

	// Now combine the whole thing into a date we know about.
	NSTimeZone * tzValue = [NSTimeZone timeZoneForSecondsFromGMT:tzOffset * 60 * 60];
	return [NSCalendarDate dateWithYear:yearValue month:monthValue day:dayValue hour:hourValue minute:minuteValue second:secondValue timeZone:tzValue];
}

BOOL extractFeedsToArray(NSData *xmlData, NSMutableArray *linkArray)
{
	BOOL success = NO;
	NS_DURING
	NSArray * arrayOfTags = [XMLTag parserFromData:xmlData];
	if (arrayOfTags != nil)
	{
		int count = [arrayOfTags count];
		int index;

		for (index = 0; index < count; ++index)
		{
			XMLTag * tag = [arrayOfTags objectAtIndex:index];
			NSString * tagName = [tag name];

			if ([tagName isEqualToString:@"rss"] || [tagName isEqualToString:@"rdf:rdf"] || [tagName isEqualToString:@"feed"])
			{
				success = NO;
				break;
			}
			if ([tagName isEqualToString:@"link"])
			{
				NSDictionary * tagAttributes = [tag attributes];
				NSString * linkType = [tagAttributes objectForKey:@"type"];

				// We're looking for the link tag. Specifically we're looking for the one which
				// has application/rss+xml or atom+xml type. There may be more than one which is why we're
				// going to be returning an array.
				if ([linkType isEqualToString:@"application/rss+xml"])
				{
					NSString * href = [tagAttributes objectForKey:@"href"];
					if (href != nil)
						[linkArray addObject:href];
				}
				else if ([linkType isEqualToString:@"application/atom+xml"])
				{
					NSString * href = [tagAttributes objectForKey:@"href"];
					if (href != nil)
						[linkArray addObject:href];
				}
			}
			if ([tagName isEqualToString:@"/head"])
				break;
			success = [linkArray count] > 0;
		}
	}
	NS_HANDLER
	success = NO;
	NS_ENDHANDLER
	return success;
}

