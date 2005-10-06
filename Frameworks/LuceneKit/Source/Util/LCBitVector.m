#include "LCBitVector.h"
#include "LCIndexInput.h"
#include "LCIndexOutput.h"
#include "GNUstep.h"

@implementation LCBitVector

- (id) init
{
	self = [super init];
	count = -1;
	size = 0;
	bits = [[NSMutableData alloc] init];
	return self;
}

- (id) initWithSize: (int) n
{
	self = [self init];
	size = n;
	NSRange r = NSMakeRange(0, [bits length]);
	[bits resetBytesInRange: r];
	[bits setLength: (n >> 3) + 1];
	return self;
}

- (void) dealloc
{
	DESTROY(bits);
	[super dealloc];
}

- (void) setBit: (int) bit
{
	unsigned char b;
	NSRange r = NSMakeRange((bit >> 3), 1);
	[bits getBytes: &b range: r];
	b |= 1 << (bit & 7);
	[bits replaceBytesInRange: r withBytes: &b];
	count = -1; // Recalculate count
}

- (void) clearBit: (int) bit
{
	unsigned char b;
	NSRange r = NSMakeRange((bit >> 3), 1);
	[bits getBytes: &b range: r];
	b &= ~(1 << (bit & 7));
	[bits replaceBytesInRange: r withBytes: &b];
	count = -1; //Recalculate count
}

- (BOOL) bit: (int) bit
{
	NSRange r = NSMakeRange((bit >> 3), 1);
	unsigned char b;
	[bits getBytes: &b range: r];
	int result = b & (1 << (bit & 7));
	return ((result != 0) ? YES : NO);
}

- (int) size
{
	return size;
}

static char BYTE_COUNTS[] = {	  // table of bits/byte
    0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4,
    1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
    1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
    1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
    3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
    4, 5, 5, 6, 5, 6, 6, 7, 5, 6, 6, 7, 6, 7, 7, 8
};

- (int) count
{
	if (count == -1) 
    {
		int i, c = 0;
		unsigned char b;
		NSRange r;
		int end = [bits length];
		for (i = 0; i < end; i++)
        {
			r = NSMakeRange(i, 1);
			[bits getBytes: &b range: r];
			c += BYTE_COUNTS[b & 0xFF];	  // sum bits per byte
		}
		count = c;
    }
	return count;
}

- (void) writeToDirectory: (id <LCDirectory>) d
				 name: (NSString *) name
{
	LCIndexOutput *output = [d createOutput: name];
	if (output)
	{
		[output writeInt: [self size]];
		[output writeInt: [self count]];
		[output writeBytes: bits length: [bits length]];
		[output close];
	}
}

- (id) initWithDirectory: (id <LCDirectory>) d
				 name: (NSString *) name
{
	self = [self init];
	LCIndexInput *input = [d openInput: name];
	if (input)
	{
		size = [input readInt];
		self = [self initWithSize: size];
		count = [input readInt];
		[input readBytes: bits offset: 0 length: (size >> 3) + 1];
		[input close];
		return self;
	}
	else
	{
		NSLog(@"Cannot get saved bit-vector");
		return nil;
	}
}

@end

