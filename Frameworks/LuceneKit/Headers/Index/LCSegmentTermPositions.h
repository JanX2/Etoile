#ifndef __LUCENE_INDEX_SEGMENT_TERM_POSITIONS__
#define __LUCENE_INDEX_SEGMENT_TERM_POSITIONS__

#include "Index/LCSegmentTermDocs.h"
#include "Index/LCTermPositions.h"

@class LSIndexInput;

@interface LCSegmentTermPositions: LCSegmentTermDocs <LCTermPositions>
{
  LCIndexInput *proxStream;
  int proxCount;
  int position;
}

- (id) initWithSegmentReader: (LCSegmentReader *) p;

  
@end


#endif /* __LUCENE_INDEX_SEGMENT_TERM_POSITIONS__ */
