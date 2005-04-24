#ifndef __LUCENE_DISJUNCTION_SUM_SCORER__
#define __LUCENE_DISJUNCTION_SUM_SCORER__

#include "Search/LCScorer.h"
#include "Util/LCPriorityQueue.h"

@interface LCScorerQueue: LCPriorityQueue
@end

@interface LCDisjunctionSumScorer: LCScorer
{
  int nrScorers;
  NSArray *subScorers;
  int minimumNrMatchers;
  LCScorerQueue *scorerQueue;
  int currentDoc;
  int nrMatchers;
  float currentScore;
}

- (id) initWithSubScorers: (NSArray *) subScorers
       minimumNrMatchers: (int) minimumNrMatchers;
- (id) initWithSubScorers: (NSArray *) subScorers;
- (void) initScorerQueue;
- (BOOL) next;
- (BOOL) advanceAfterCurrent;
- (float) score;
- (int) doc;
- (int) nrMatchers;
- (BOOL) skipTo: (int) target;
- (LCExplanation *) explain: (int) doc;

@end

#endif /* __LUCENE_DISJUNCTION_SUM_SCORER__ */
