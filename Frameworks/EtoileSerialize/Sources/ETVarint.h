/*
	Copyright (C) 2010 Niels Grewe

	Author:  Niels Grewe <niels.grewe@halbordnung.de>
	Date:  March 2010
	License: Modified BSD (see COPYING)
 */
#import <Foundation/Foundation.h>
#include <stdint.h>


/**
 * This category extends NSNumber with the capability to encode integer values
 * into the machine-independent and space-efficient varint format which is used
 * by Google's Protocol Buffers <http://code.google.com/apis/protocolbuffers/>.
 * Integers are encoded as sequences of bytes (beginning with the LSB) where
 * the most significiant bit carries a flag whether further bytes will follow.
 * TODO: The present implementation is probably not very efficient (e.g. it
 * assumes all values to be fully blown 64bit integers).
 */
@interface NSNumber (ETVarint)

/**
 * Return a varint-encoded byte-sequence for the integer value.
 */
- (NSData*)varintValue;

/**
 * Returns a byte-sequence representing the signed integer value, to save space,
 * the value is zig-zag encoded first ((n << 1) ^ (n >> 63)).
 */
- (NSData*)signedVarintValue;
@end

/**
 * This category extends NSData with the capability to read varints from the
 * beginning of the buffer.
 */
@interface NSData (ETVarint)

/**
 * Try to read a varint from the beginning of the buffer. Will raise an
 * ETNotAVarint exception if the buffer does not begin with a valid varint. 
 */
- (NSNumber*)readVarint;

/**
 * Try to read a signed (zig-zag encoded) varint from the beginning of the
 * buffer. Will raise an ETNotAVarint exception if the buffer does not begin
 * with a valid varint.
 */
- (NSNumber*)readSignedVarint;
@end

@interface NSMutableData (ETVarint)
/**
 * Try to read a varint from the beginning of the buffer and remove it from the
 * buffer. Will raise an ETNotAVarint exception if the buffer does not begin
 * with a valid varint.
 */
- (NSNumber*)readAndPruneVarint;

/**
 * Try to read a signed (zig-zag encoded) varint from the beginning of the
 * buffer and remove it from the buffer. Will raise an ETNotAVarint exception if
 * the buffer does not begin with a valid varint.
 */
- (NSNumber*)readAndPruneVarint;
@end

/**
 * References the maximum number of bytes used to store a varint.
 */
extern NSUInteger ETVarintMaxBytes;

/**
 *  Try to read a varint from the buffer referenced by bytes and return the
 *  number of bytes read in the integer pointed to by length.
 */
uint64_t ETUnsignedIntegerFromVarint(const void* bytes, uint16_t *length);

/**
 * Try to read a varint from the buffer referenced by bytes and return it as a
 * signed integer. Also return the number of bytes read in the integer pointed
 * to by length.
 */
int64_t ETIntegerFromVarint(const void* bytes, uint16_t *length);

/**
 * Write the varint representation of an unsigned integer to buffer. The caller
 * needs to allocate ETVarintMaxBytes (=10) bytes for the buffer, the actual
 * number of bytes needed will be returned in length.
 */
void ETVarintFromUnsignedInteger(void *buffer, uint16_t *length, unsigned long long integer);

/**
 * Write the varint representation of a signed integer to buffer. The caller
 * needs to allocate ETVarintMaxBytes bytes for the buffer, the actual number of
 * bytes needed will be returned in length.
 */
void ETVarintFromInteger(void *buffer, uint16_t *length, long long integer);
