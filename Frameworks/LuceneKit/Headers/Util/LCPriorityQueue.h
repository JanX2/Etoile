#ifndef __LUCENE_UTIL_PRIORITY_QUEUE__
#define __LUCENE_UTIL_PRIORITY_QUEUE__

#include <Foundation/Foundation.h>

/** A PriorityQueue maintains a partial ordering of its elements such that the
  least element can always be found in constant time.  Put()'s and pop()'s
  require log(size) time. */

@interface LCPriorityQueue: NSObject
{
  NSMutableArray *heap;
  int maxSize;
}

/** Determines the ordering of objects in this priority queue.  Subclasses
 *     must define this one method. */
- (BOOL) lessThan: (id) a : (id) b;

- (id) initWithSize: (int) size;
- (void) put: (id) element;
- (BOOL) insert: (id) element;
- (id) top;
- (id) pop;
- (void) adjustTop;
- (int) size;
- (void) clear;
- (void) upHeap;
- (void) downHeap;

@end
#endif __LUCENE_UTIL_PRIORITY_QUEUE__
