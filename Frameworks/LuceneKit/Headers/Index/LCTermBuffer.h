#ifndef __LUCENE_INDEX_TERM_BUFFER__
#define __LUCENE_INDEX_TERM_BUFFER__

#include "LuceneKit/Index/LCTerm.h"

@class LCIndexInput;
@class LCFieldInfos;

@interface LCTermBuffer: LCTerm

/* only used by LCSegmentTermEnum */
- (void) read: (LCIndexInput *) input
         fieldInfos: (LCFieldInfos *) fieldInfos;

@end

#endif /* __LUCENE_INDEX_TERM_BUFFER__ */
