/*
	Copyright (C) 2010 Niels Grewe

	Author:  Niels Grewe <niels.grewe@halbordnung.de>
	Date:  March 2010
	License: Modified BSD (see COPYING)
 */
#import "ETVarint.h"
#import <Foundation/Foundation.h>
#include <stdint.h>
#include <limits.h>

#define zigZag(x) ((x << 1) ^ (x >> 63))

NSUInteger ETVarintMaxBytes = 10;

void ETVarintFromUnsignedInteger(void *buffer, uint16_t *length, unsigned long long integer)
{
	NSNumber *num = [NSNumber numberWithUnsignedLongLong: integer];
	NSData *bytes = [num varintValue];
	uint16_t len = [bytes length];
	if (length != NULL)
	{
		*length = len;
	}
	[bytes getBytes: buffer
	         length: len];
}

void ETVarintFromInteger(void *buffer, uint16_t *length, long long integer)
{
	NSNumber *num = [NSNumber numberWithLongLong: integer];
	NSData *bytes = [num signedVarintValue];
	uint16_t len = [bytes length];
	if (length != NULL)
	{
		*length = len;
	}
	[bytes getBytes: buffer
	         length: len];
}

@implementation NSNumber (ETVarint)

- (NSData*)varintValueWithZigZagEncoding: (BOOL)doZigZag;
{
	unsigned long long value = 0;

	// When processing signed integers zig-zag encoding saves space:
	if (doZigZag)
	{
		long long num = [self longLongValue];
		value = zigZag(num);
	}
	else
	{
		value = [self unsignedLongLongValue];
	}
	NSMutableData *result = [[[NSMutableData alloc] init] autorelease];
	uint16_t byte_index = 0;
	do
	{
		/*
		 * Each byte of a varint contains a flag as its MSB and 7 bits of
		 * information. So at byte n the least significiant n*7 bits of the
		 * value have already been processed.
		 */
		uint8_t shift_bits = (7 * byte_index);
		uint8_t byte = (uint8_t)((value >> shift_bits));
		if (value < (1 << (shift_bits+7)))
		{
			/* 
			 * The remaining bits of the value fit within the byte, set the MSB
			 * to 0.
			 */
			byte &= 0x7F;
		}
		else
		{
			/* The remaining bits do not fit within the byte, set the MSB to 1
			 * to indicate more bits will follow.
			 */
			byte |= 0x80;
		}
		[result appendBytes: (void*)&byte length: 1];
		byte_index++;
	} while ((byte_index < ETVarintMaxBytes) && ((1 << (7 * byte_index )) < value));
	
	return result;
}

- (NSData*)varintValue
{
	return [self varintValueWithZigZagEncoding: NO];
}

- (NSData*)signedVarintValue
{
	return [self varintValueWithZigZagEncoding: YES];
}

@end
