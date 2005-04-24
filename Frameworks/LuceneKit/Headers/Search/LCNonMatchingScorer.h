#ifndef __LUCENE_SEARCH_NON_MATCHING_SCORER__
#define __LUCENE_SEARCH_NON_MATCHING_SCORER__

#include "Search/LCScorer.h"

@interface LCNonMatchingScorer: LCScorer
- (int) doc;
- (BOOL) next;
- (float) score;
- (BOOL) skipTo: (int) target;
- (LCExplanation *) explain: (int) doc;

@end

#endif /* __LUCENE_SEARCH_NON_MATCHING_SCORER__ */
