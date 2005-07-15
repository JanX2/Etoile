#ifndef __LUCENE_SEARCH_FILTERED_TERM_ENUM__
#define __LUCENE_SEARCH_FILTERED_TERM_ENUM__

#include <LuceneKit/Index/LCTermEnum.h>

@interface LCFilteredTermEnumerator: LCTermEnumerator
{
	LCTerm *currentTerm;
	LCTermEnumerator *actualEnum;
}

- (BOOL) isEqualToTerm: (LCTerm *) term;
- (float) difference;
- (BOOL) endOfEnumerator;
- (void) setEnumerator: (LCTermEnumerator *) actualEnum;
@end

#endif /* __LUCENE_SEARCH_FILTERED_TERM_ENUM__ */
