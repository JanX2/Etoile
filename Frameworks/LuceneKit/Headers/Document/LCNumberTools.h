#ifndef __LUCENE_DOCUMENT_NUMBER_TOOLS__
#define __LUCENE_DOCUMENT_NUMBER_TOOLS__

#include <Foundation/Foundation.h>

/**
 * Provides support for converting longs to Strings, and back again. The strings
 * are structured so that lexicographic sorting order is preserved.
 * 
 * <p>
 * That is, if l1 is less than l2 for any two longs l1 and l2, then
 * NumberTools.longToString(l1) is lexicographically less than
 * NumberTools.longToString(l2). (Similarly for "greater than" and "equals".)
 * 
 * <p>
 * This class handles <b>all</b> long values (unlike
 * {@link org.apache.lucene.document.DateField}).
 * 
 * @author Matt Quail (spud at madbean dot com)
 */

#define RADIX 36

static NSString *NEGATIVE_PREFIX = @"-";
static NSString *POSITIVE_PREFIX = @"0";

// long in java is 8 bytes, which is long long in C (most unix)
@interface NSString (LuceneKit_Document_Number)
+ (id) stringWithLongLong: (long long) l;
- (long long) longLongValue;
@end

#endif /* __LUCENE_DOCUMENT_NUMBER_TOOLS__ */
