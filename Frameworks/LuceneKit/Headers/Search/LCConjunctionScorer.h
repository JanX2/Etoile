#ifndef __LUCENE_SEARCH_CONJUNCTION_SCORER__
#define __LUCENE_SEARCH_CONJUNCTION_SCORER__

#include "Search/LCScorer.h"

@interface LCConjunctionScorer: LCScorer
{
  NSArray *scorers;
  BOOL firstTime;
  BOOL more;
  float coord;
}

- (id) initWithSimilarity: (LCSimilarity *) similarity;
- (void) addScorer: (LCScorer *) scorer;
- (LCScorer *) first;
- (LCScorer *) last;
- (int) doc;
- (BOOL) next;
- (BOOL) doNext;
- (BOOL) skipTo: (int) target;
- (float) score;
- (void) initWithScorers: (LCBoolean *) initScorers;
- (void) sortScorers;
- (LCExplanation *) explain: (int) doc;
@end

#endif /* __LUCENE_SEARCH_CONJUNCTION_SCORER__ */
