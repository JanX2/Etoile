#ifndef __LUCENE_INDEX_SEGMENT_TERM_DOCS__
#define __LUCENE_INDEX_SEGMENT_TERM_DOCS__

#include <Foundation/Foundation.h>
#include "LuceneKit/Index/LCTermDocs.h"

@class LCSegmentReader;
@class LCIndexInput;
@class LCBitVector;
@class LCTermInfo;

@interface LCSegmentTermDocs: NSObject <LCTermDocs>
{
  LCSegmentReader *parent;
  LCIndexInput *freqStream;
  int count;
  int df;
  LCBitVector *deletedDocs;
  int doc;
  int freq;

  int skipInterval;
  int numSkips;
  int skipCount;
  LCIndexInput *skipStream;
  int skipDoc;
  long freqPointer;
  long proxPointer;
  long skipPointer;
  BOOL haveSkipped;
}

- (id) initWithSegmentReader: (LCSegmentReader *) p;
- (void) seekTermInfo: (LCTermInfo *) ti;
- (void) skippingDoc;
- (void) skipProx: (long) proxPointer;

@end

#endif /* __LUCENE_INDEX_SEGMENT_TERM_DOCS__ */
