#ifndef __LUCENE_SEARCH_SCORER__
#define __LUCENE_SEARCH_SCORER__

#include <Foundation/Foundation.h>

@interface LCScorer: NSObject
{
  LCSimilarity *similarity;
}
- (id) initWithSimilarity: (LCSimilarity *) si;
- (LCSimilarity *) similarity;
- (void) score: (LCHitCollector *) hc;
- (BOOL) score: (LCHitCollector *) hc
           max: (int) max;
- (BOOL) next;
- (int) doc;
- (float) score;
- (LCExplanation *) explain: (int) doc;
@end
#endif /* __LUCENE_SEARCH_SCORER__ */
