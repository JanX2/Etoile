#ifndef __LUCENE_SEARCH_SCORER__
#define __LUCENE_SEARCH_SCORER__

#include <Foundation/Foundation.h>
#include <LuceneKit/Search/LCSimilarity.h>
#include <LuceneKit/Search/LCHitCollector.h>
#include <LuceneKit/Search/LCExplanation.h>

@interface LCScorer: NSObject
{
	LCSimilarity *similarity;
}
- (id) initWithSimilarity: (LCSimilarity *) si;
- (LCSimilarity *) similarity;
- (void) score: (LCHitCollector *) hc;
- (BOOL) score: (LCHitCollector *) hc maximalDocument: (int) max;
	/* Override by subclass */
- (BOOL) next;
- (int) document;
- (float) score;
- (BOOL) skipTo: (int) target;
- (LCExplanation *) explain: (int) doc;
@end
#endif /* __LUCENE_SEARCH_SCORER__ */
