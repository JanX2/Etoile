#ifndef __LUCENE_UTIL_BIT_VECTOR__
#define __LUCENE_UTIL_BIT_VECTOR__

#include <Foundation/Foundation.h>
#include "LuceneKit/Store/LCDirectory.h"

#ifdef HAVE_UKTEST
#include <UnitKit/UnitKit.h>
@interface LCBitVector: NSObject <UKTest>
#else
@interface LCBitVector: NSObject
#endif
{
  //char *bits; // J: byte[] bits
  NSMutableData *bits;
  int size;
  int count;
}

- (id) initWithSize: (int) n;
- (void) setBit: (int) bit;
- (void) clearBit: (int) bit;
- (BOOL) getBit: (int) bit;
- (int) size;
- (int) count;
- (void) writeToDirectory: (id <LCDirectory>) d
                 withName: (NSString *) name;
- (id) initWithDirectory: (id <LCDirectory>) d
                 andName: (NSString *) name;

@end

#endif /* __LUCENE_UTIL_BIT_VECTOR__ */
