#ifndef __LUCENE_SEARCH_FILTERED_TERM_ENUM__
#define __LUCENE_SEARCH_FILTERED_TERM_ENUM__

#include <LuceneKit/Index/LCTermEnum.h>

@interface LCFilteredTermEnumerator: LCTermEnumerator
{
	LCTerm *currentTerm;
	LCTermEnumerator *actualEnum;
}

- (float) difference;
@end

@interface LCFilteredTermEnumerator (LCProtected)
- (BOOL) isEqualToTerm: (LCTerm *) term;
- (BOOL) endOfEnumerator;
- (void) setEnumerator: (LCTermEnumerator *) actualEnum;
@end

#endif /* __LUCENE_SEARCH_FILTERED_TERM_ENUM__ */
