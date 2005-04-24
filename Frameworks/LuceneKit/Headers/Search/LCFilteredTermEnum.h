#ifndef __LUCENE_SEARCH_FILTERED_TERM_ENUM__
#define __LUCENE_SEARCH_FILTERED_TERM_ENUM__

#include "Index/LCTermEnum.h"

@interface LCFilteredTermEnum: LCTermEnum
{
  LCTerm *currentTerm;
  LCTermEnum *actualEnum;
}

- (BOOL) termCompare: (LCTerm *) term;
- (float) difference;
- (BOOL) endEnum;
- (void) setEnum: (LCTermEnum *) actualEnum;
- (int) documentFrequency;
- (BOOL) next;
- (LCTerm *) term;
- (void) close;
@end

#endif /* __LUCENE_SEARCH_FILTERED_TERM_ENUM__ */
