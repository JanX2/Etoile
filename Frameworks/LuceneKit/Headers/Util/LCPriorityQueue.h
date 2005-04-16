#ifndef __LUCENE_UTIL_PRIORITY_QUEUE__
#define __LUCENE_UTIL_PRIORITY_QUEUE__

#include <Foundation/Foundation.h>

/* LuceneKit: used by LCPriorityQueue 
 * to decide which one is less (NSOrderedAscending)
 */
@protocol LCComparable <NSObject>
- (NSComparisonResult) compare: (id) other;
@end

/** A PriorityQueue maintains a partial ordering of its elements such that the
  least element can always be found in constant time.  Put()'s and pop()'s
  require log(size) time. */

@interface LCPriorityQueue: NSObject
{
  NSMutableArray *heap;
  int maxSize;
}

- (id) initWithSize: (int) size;
- (void) put: (id) element;
- (BOOL) insert: (id) element;
- (id) top;
- (id) pop;
- (void) adjustTop;
- (int) size;
- (void) clear;

@end
#endif /* __LUCENE_UTIL_PRIORITY_QUEUE__ */
