#include "LuceneKit/Util/LCBitVector.h"
#include "LuceneKit/Store/LCIndexInput.h"
#include "LuceneKit/Store/LCIndexOutput.h"
#include "GNUstep.h"

/** Optimized implementation of a vector of bits.  This is more-or-less like
  java.util.BitSet, but also includes the following:
  <ul>
  <li>a count() method, which efficiently computes the number of one bits;</li>
  <li>optimized read from and write to disk;</li>
  <li>inlinable get() method;</li>
  </ul>

  @author Doug Cutting
  @version $Id$
  */
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
  //ASSIGN(bits, [[NSMutableData alloc] initWithLength: (n >> 3) + 1]);
  //bits = malloc(sizeof(char)*(size >> 3) + 1); 
  return self;
}

- (void) setBit: (int) bit
{
  /** Sets the value of <code>bit</code> to one. */
  unsigned char b;
  NSRange r = NSMakeRange((bit >> 3), 1);
  [bits getBytes: &b range: r];
  b |= 1 << (bit & 7);
  [bits replaceBytesInRange: r withBytes: &b];
  //bits[bit >> 3] |= 1 << (bit & 7);
  count = -1;
}

- (void) clearBit: (int) bit
{
  /** Sets the value of <code>bit</code> to zero. */
  unsigned char b;
  NSRange r = NSMakeRange((bit >> 3), 1);
  [bits getBytes: &b range: r];
  b &= ~(1 << (bit & 7));
  [bits replaceBytesInRange: r withBytes: &b];
  //bits[bit >> 3] &= ~(1 << (bit & 7));
  count = -1;
}

- (BOOL) getBit: (int) bit
{
  /** Returns <code>true</code> if <code>bit</code> is one and
    <code>false</code> if it is zero. */
  NSRange r = NSMakeRange((bit >> 3), 1);
  unsigned char b;
  [bits getBytes: &b range: r];
  int result = b & (1 << (bit & 7));
  //int result = bits[bit >> 3] & (1 << (bit & 7));
  return ((result != 0) ? YES : NO);
}

- (int) size
{
  /** Returns the number of bits in this vector.  This is also one greater than
    the number of the largest valid bit number. */
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
  /** Returns the total number of one bits in this vector.  This is efficiently
    computed and cached, so that, if the vector is not changed, no
    recomputation is done for repeated calls. */
  // if the vector has been modified
  if (count == -1) 
    {
      int i, c = 0;
      unsigned char b;
      NSRange r;
      //int end = malloc_size(bits)/sizeof(char); // maybe malloc_good_size()
      //int end = sizeof(bits[]);;
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
  /** Writes this vector to the file <code>name</code> in Directory
    <code>d</code>, in a format that can be read by the constructor {@link
    #BitVector(Directory, String)}.  */

  LCIndexOutput *output = [d createOutput: name];
  if (output)
  {
    [output writeInt: [self size]];
    [output writeInt: [self count]];
    [output writeBytes: bits length: [bits length]];
    [output close];
  }
#if 0
    OutputStream output = d.createFile(name);
    try {
      output.writeInt(size());			  // write size
      output.writeInt(count());			  // write count
      output.writeBytes(bits, bits.length);	  // write bits
    } finally {
      output.close();
    }
#endif
}

- (id) initWithDirectory: (id <LCDirectory>) d
                andName: (NSString *) name
{
  /** Constructs a bit vector from the file <code>name</code> in Directory
    <code>d</code>, as written by the {@link #write} method.
    */
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
    
#if 0
    try {
      size = input.readInt();			  // read size
      count = input.readInt();			  // read count
      bits = new byte[(size >> 3) + 1];		  // allocate bits
      input.readBytes(bits, 0, bits.length);	  // read bits
    } finally {
      input.close();
    }
#endif
}

- (void) dealloc
{
  RELEASE(bits);
  [super dealloc];
}

@end

#ifdef HAVE_UKTEST

#include "LuceneKit/Store/LCRAMDirectory.h"

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
