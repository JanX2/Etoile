#ifndef __LUCENE_UTIL_BIT_VECTOR__
#define __LUCENE_UTIL_BIT_VECTOR__

#include <Foundation/Foundation.h>
#include "Store/LCDirectory.h"

#ifdef HAVE_UKTEST
#include <UnitKit/UnitKit.h>
@interface LCBitVector: NSObject <UKTest>
#else
@interface LCBitVector: NSObject
#endif
{
  NSMutableData *bits;
  int size;
  int count;
}

/* Initialized to be able to contain n bits */
- (id) initWithSize: (int) n;
/* Set YES at <bit> */
- (void) setBit: (int) bit;
/* Set NO at ,bit> */
- (void) clearBit: (int) bit;
/* Get <bit> value */
- (BOOL) getBit: (int) bit;
/* Get size */
- (int) size;
/* Count the number of bits which are YES */
- (int) count;
/* Read / Write */
- (void) writeToDirectory: (id <LCDirectory>) d
                 withName: (NSString *) name;
- (id) initWithDirectory: (id <LCDirectory>) d
                 andName: (NSString *) name;

@end

#endif /* __LUCENE_UTIL_BIT_VECTOR__ */
