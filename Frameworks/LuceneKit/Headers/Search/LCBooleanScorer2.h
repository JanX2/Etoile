#ifndef __LUCENE_SEARCH_BOOLEAN_SCORER2__
#define __LUCENE_SEARCH_BOOLEAN_SCORER2__

#include "Search/LCScorer.h"

@interface LCCordinator: NSObject
{
  int maxCorrd;
  NSArray *corrdFactors;
  
  int nrMatchers;
}

- (float) coordFactor;
@end

@interface LCSingleMatchScorer: LCScorer
{
  LCScorer *scorer;
}

- (id) initWithScorer: (LCScorer *) scorer;
- (float) score;
- (int) doc;
- (BOOL) next;
- (BOOL) skipTo: (int) docNr;
- (LCExplanantion *) explain: (int) docNr;
@end

@interface LCBooleanScorer2: LCScorer
{
  NSArray *requiredScorers;
  NSArray *optionalScorers;
  NSArray *prohibitedScorers;
  
  LCCordinator *coordinator;
  LCScorer *countingSumScorer;

  LCSimilarity *defaultSimilarity;
}

- (id) initWithSimilarity: (LCSimilarity *) similarity;
- (void) addScorer: (LCScorer *) scorer
         required: (BOOL) required
	 prohibited: (BOOL) prohibited;
- (void) initCountingSumScorer;
- (LCScorer *) countingDisjunctionSumScorer: (NSArray *) scorers;
- (LCScorer *) countingConjunctionSumScorer: (NSArray *) requiredScorers;
- (LCScorer *) makeCountingSumScorer;
- (LCScorer *) makeCountingSumScorer2: (LCScorer *) requiredCountingSumScorer
               optional: (NSArray *) optionalScorers;
- (LCScorer *) makeCountingSumScorer3: (LCScorer *) requiredCountingSumScorer
               optional: (NSArray *) optionalCountingSumScorer;
- (void) score: (LCHitCollector *) hc;
- (BOOL) score: (LCHitCollector *) hc max: (int) max;
- (int) doc;
- (BOOL) next;
- (float) score;
- (BOOL) skipTo: (int) target;
- (LCExplanation *) explain: (int) doc;

@end

#endif /* __LUCENE_SEARCH_BOOLEAN_SCORER2__ */
