#ifndef __LUCENE_INDEX_SEGMENT_MERGE_INFO__
#define __LUCENE_INDEX_SEGMENT_MERGE_INFO__

#include <Foundation/Foundation.h>
#include "LuceneKit/Index/LCTermPositions.h"

@class LCTerm;
@class LCTermEnum;
@class LCIndexReader;

@interface LCSegmentMergeInfo: NSObject
{
  LCTerm *term;
  int base;
  LCTermEnum *termEnum;
  LCIndexReader *reader;
  id <LCTermPositions> postings;
  NSMutableArray *docMap; // maps around deleted docs
}

- (id) initWithBase: (int) b termEnum: (LCTermEnum *) te 
              reader: (LCIndexReader *) r;
- (LCTerm *) term;
- (LCTermEnum *) termEnum;
- (int) base;
- (BOOL) next;
- (void) close;
- (NSArray *) docMap;
- (id <LCTermPositions>) postings;
@end
#endif /* __LUCENE_INDEX_SEGMENT_MERGE_INFO__ */
