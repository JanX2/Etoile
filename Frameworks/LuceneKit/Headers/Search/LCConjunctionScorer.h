#ifndef __LUCENE_SEARCH_CONJUNCTION_SCORER__
#define __LUCENE_SEARCH_CONJUNCTION_SCORER__

#include "Search/LCScorer.h"

@interface LCConjunctionScorer: LCScorer
{
  NSMutableArray *scorers;
  BOOL firstTime;
  BOOL more;
  float coord;
}

- (void) addScorer: (LCScorer *) scorer;
- (LCScorer *) first;
- (LCScorer *) last;
- (BOOL) doNext;
- (void) initWithScorers: (BOOL) initScorers;
- (void) sortScorers;
@end

#endif /* __LUCENE_SEARCH_CONJUNCTION_SCORER__ */
