#ifndef __LUCENE_INDEX_MULTIPLE_TERM_POSITION__
#define __LUCENE_INDEX_MULTIPLE_TERM_POSITION__

#include <Foundation/Foundation.h>
#include "LuceneKit/Index/LCTermPositions.h"
#include "LuceneKit/Util/LCPriorityQueue.h"

@interface LCTermPositionsQueue: LCPriorityQueue
- (id) initWithTermPositions: (NSArray *) termPositions;
- (id <LCTermPositions>) peek;
@end

@interface LCIntQueue: NSObject
{
  int _arraySize;
  int _index;
  int _lastIndex;
  NSMutableArray *_array;
}

- (void) add: (int) i;
- (int) next;
- (void) sort;
- (void) clear;
- (int) size;
- (void) growArray;

@end

@class LCIndexReader;

@interface LCMultipleTermPositions: NSObject <LCTermPositions>
{
  int _doc;
  int _freq;
  LCTermPositionsQueue *_termPositionsQueue;
  LCIntQueue *_posList;
}

- (id) initWithIndexReader: (LCIndexReader *) indexReader
                terms: (NSArray *) terms;
@end

#endif /* __LUCENE_INDEX_MULTIPLE_TERM_POSITION__ */
