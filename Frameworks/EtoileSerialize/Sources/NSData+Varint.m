/*
	Copyright (C) 2010 Niels Grewe

	Author:  Niels Grewe <niels.grewe@halbordnung.de>
	Date:  March 2010
	License: Modified BSD (see COPYING)
 */
#import "ETVarint.h"
#import <Foundation/Foundation.h>
#include <stdint.h>

#define unZigZag(x) ((x >> 1) ^ -(int64_t)(x & 1))

/**
 * This function will read the var-int byte-by-byte and return both the value
 * and the length.
 */
uint64_t ETUnsignedIntegerFromVarint(const void *bytes, uint16_t *length)
{
	int byte_index = 0;
	uint64_t value = 0;
	uint8_t byte = 0;
	do
	{
		if (byte_index >= ETVarintMaxBytes)
		{
			[NSException raise: @"ETNotAVarint"
			            format: @"Byte sequence at 0x%x is not a varint",
						(uintptr_t)bytes];
		}
		byte = *(uint8_t*)(((uintptr_t)bytes)+byte_index);
		value |= ((uint64_t)(byte & 0x7F) << (7 * byte_index));
		byte_index++;
	} while (byte & 0x80);
	if (NULL != length)
	{
		*length = byte_index;
	}
	return value;
}

int64_t ETIntegerFromVarint(const void *bytes, uint16_t *length)
{
	uint64_t raw = ETUnsignedIntegerFromVarint(bytes, length);
	return unZigZag(raw);
}

@implementation NSData (ETVarint)
- (NSNumber*)readVarintWithZigZagEncoding: (BOOL)doZigZag
{
	uint64_t value = ETUnsignedIntegerFromVarint([self bytes], NULL);
	if (doZigZag)
	{
		// Signed varints need to be un-zig-zagged.
		return [NSNumber numberWithLongLong: unZigZag(value)];
	}
	else
	{
		return [NSNumber numberWithUnsignedLongLong: value];
	}
}

- (NSNumber*)readVarint
{
	return [self readVarintWithZigZagEncoding: NO];
}

- (NSNumber*)readSignedVarint
{
	return [self readVarintWithZigZagEncoding: YES];
}

@end

@implementation NSMutableData (ETVarint)
- (NSNumber*)readAndPruneVarintWithZigZagEncoding: (BOOL)doZigZag
{
	uint16_t varint_length;
	uint64_t value = ETUnsignedIntegerFromVarint([self bytes], &varint_length);
	[self replaceBytesInRange: NSMakeRange(0, varint_length)
	                withBytes: NULL
	                   length: 0];
	if (doZigZag)
	{
		// Signed varints need to be un-zig-zagged.
		return [NSNumber numberWithLongLong: unZigZag(value)];
	}
	else
	{
		return [NSNumber numberWithUnsignedLongLong: value];
	}
}

- (NSNumber*)readAndPruneVarint
{
	return [self readAndPruneVarintWithZigZagEncoding: NO];
}

- (NSNumber*)readAndPruneSignedVarint
{
	return [self readAndPruneVarintWithZigZagEncoding: YES];
}
@end
