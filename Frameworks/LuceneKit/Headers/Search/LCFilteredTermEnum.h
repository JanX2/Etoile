#ifndef __LUCENE_SEARCH_FILTERED_TERM_ENUM__
#define __LUCENE_SEARCH_FILTERED_TERM_ENUM__

#include <LuceneKit/Index/LCTermEnum.h>

@interface LCFilteredTermEnumerator: LCTermEnumerator
{
	LCTerm *currentTerm;
	LCTermEnumerator *actualEnum;
}

- (BOOL) termCompare: (LCTerm *) term;
- (float) difference;
- (BOOL) endEnumerator;
- (void) setEnumerator: (LCTermEnumerator *) actualEnum;
- (int) documentFrequency;
- (BOOL) next;
- (LCTerm *) term;
- (void) close;
@end

#endif /* __LUCENE_SEARCH_FILTERED_TERM_ENUM__ */
