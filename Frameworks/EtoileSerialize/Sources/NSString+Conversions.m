/*
	Copyright (C) 2009 Niels Grewe

	Author:  Niels Grewe <niels.grewe@halbordnung.de>
	Date:  July 2009
	License: Modified BSD (see COPYING)
 */

#include <stdlib.h>
#include <limits.h>
#import <Foundation/Foundation.h>
#import "NSString+Conversions.h"

#define RETURN_LIMITED_VALUE(upperLimit, lowerLimit) long long value = [self longLongValue];\
	if (value > upperLimit)\
	{\
		return upperLimit;\
	}\
	else if (value < lowerLimit)\
	{\
		return lowerLimit;\
	}\
	return value;

#define RETURN_LIMITED_UNSIGNED_VALUE(limit) unsigned long long value = [self unsignedLongLongValue];\
	return MIN(value,limit);

@implementation NSString (ETNumericConversions)
-(char) charValue
{
	RETURN_LIMITED_VALUE(CHAR_MAX,CHAR_MIN)
}

-(unsigned char) unsignedCharValue
{
	RETURN_LIMITED_UNSIGNED_VALUE(UCHAR_MAX)
}

-(short) shortValue
{
	RETURN_LIMITED_VALUE(SHRT_MAX,SHRT_MIN)
}

-(unsigned short) unsignedShortValue
{
	RETURN_LIMITED_UNSIGNED_VALUE(USHRT_MAX)
}

-(int) intValue
{
	RETURN_LIMITED_VALUE(INT_MAX,INT_MIN)
}

-(unsigned int) unsignedIntValue
{
	RETURN_LIMITED_UNSIGNED_VALUE(UINT_MAX)
}

-(long) longValue
{
	return strtol([self cStringUsingEncoding: NSASCIIStringEncoding], NULL, 10);
}

-(unsigned long) unsignedLongValue
{
	return strtoul([self cStringUsingEncoding: NSASCIIStringEncoding], NULL, 10);
}

-(unsigned long long) unsignedLongLongValue
{
	return strtoull([self cStringUsingEncoding: NSASCIIStringEncoding], NULL, 10);
}
@end
