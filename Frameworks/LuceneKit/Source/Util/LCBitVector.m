#include <LuceneKit/Util/LCBitVector.h>
#include <LuceneKit/Store/LCIndexInput.h>
#include <LuceneKit/Store/LCIndexOutput.h>
#include <LuceneKit/GNUstep/GNUstep.h>

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

- (BOOL) getBit: (int) bit
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
				 withName: (NSString *) name
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
				 andName: (NSString *) name
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

#ifdef HAVE_UKTEST_MORE

#include <LuceneKit/Store/LCRAMDirectory.h>

@implementation LCBitVector (UKTest_Additions)

- (void) doTestConstructOfSize: (int) n
{
	self = [self initWithSize: n];
	UKIntsEqual(n, [self size]);
}

- (void) doTestGetSetVectorOfSize: (int) n
{
	self = [self initWithSize: n];
	int i;
	for(i = 0; i < [self size]; i++) 
    {
		UKFalse([self getBit: i]);
		[self setBit: i];
		UKTrue([self getBit: i]);
    }
}

- (void) doTestClearVectorOfSize: (int) n
{
	self = [self initWithSize: n];
	int i;
	for(i = 0; i < [self size]; i++) 
    {
		UKFalse([self getBit: i]);
		[self setBit: i];
		UKTrue([self getBit: i]);
		[self clearBit: i];
		UKFalse([self getBit: i]);
    }
}

- (void) doTestCountVectorOfSize: (int) n 
{
	self = [self initWithSize: n];
	int i;
	for(i = 0; i < [self size]; i++) 
    {
		UKFalse([self getBit: i]);
		UKIntsEqual(i, [self count]);
		[self setBit: i];
		UKTrue([self getBit: i]);
		UKIntsEqual(i+1, [self count]);
    }
	
	self = [self initWithSize: n];
	// bv = [[LCBitVector alloc] initWithSize: n];
	for(i = 0; i < [self size]; i++) 
    {
		UKFalse([self getBit: i]);
		UKIntsEqual(0, [self count]);
		[self setBit: i];
		UKTrue([self getBit: i]);
		UKIntsEqual(1, [self count]);
		[self clearBit: i];
		UKFalse([self getBit: i]);
		UKIntsEqual(0, [self count]);
    }
}

- (BOOL) doCompare: (LCBitVector *) other
{
	int i;
	for(i = 0; i < [self size]; i++)
	{
		// bits must be equal
		if([self getBit: i] != [other getBit: i]) 
		{
			return NO;
		}
	}
	return YES;
}

- (void) doTestWriteRead: (int) n
{
	id <LCDirectory> d = [[LCRAMDirectory alloc] init];
	LCBitVector *compare;
	self = [self initWithSize: n];
	// test count when incrementally setting bits
	int i;
	for(i = 0; i < [self size]; i++) 
    {
		UKFalse([self getBit: i]);
		UKIntsEqual(i, [self count]);
		[self setBit: i];
		UKTrue([self getBit: i]);
		UKIntsEqual(i+1, [self count]);
		[self writeToDirectory: d withName: @"TESTBV"];
		
		compare = [[LCBitVector alloc] initWithDirectory: d
												 andName: @"TESTBV"];
		// compare bit vectors with bits set incrementally
		UKTrue([self doCompare: compare]);
		RELEASE(compare);
    }
	RELEASE(d);
}

- (void) testAll
{
	[self doTestConstructOfSize: 8];
	[self doTestConstructOfSize: 20];
	[self doTestConstructOfSize: 100];
	[self doTestConstructOfSize: 1000];
	
	[self doTestGetSetVectorOfSize: 8];
	[self doTestGetSetVectorOfSize: 20];
	[self doTestGetSetVectorOfSize: 100];
	[self doTestGetSetVectorOfSize: 1000];
	
	[self doTestClearVectorOfSize: 8];
	[self doTestClearVectorOfSize: 20];
	[self doTestClearVectorOfSize: 100];
	[self doTestClearVectorOfSize: 1000];
	
	[self doTestCountVectorOfSize: 8];
	[self doTestCountVectorOfSize: 20];
	[self doTestCountVectorOfSize: 100];
	[self doTestCountVectorOfSize: 1000];
}

- (void) testWriteRead
{
	[self doTestWriteRead: 8];
	[self doTestWriteRead: 20];
	[self doTestWriteRead: 100];
	[self doTestWriteRead: 1000];
}

@end

#endif
