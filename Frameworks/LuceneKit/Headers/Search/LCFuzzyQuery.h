#ifndef __LUCENE_SEARCH_FUZZY_QUERY__
#define __LUCENE_SEARCH_FUZZY_QUERY__

#include "Search/LCMultiTermQuery.h"

@interface LCScoreTerm: NSObject
{
  LCTerm *term;
  float score;
}

- (id) initWithTerm: (LCTerm *) term score: (float) score;
@end

@interface LCScoreTermQueue: LCPriorityQueue
@end

static float defaultMinSimilarity = 0.5f;
static int defaultPrefixLength = 0;

@interface LCFuzzyQuery: LCMultiTermQuery
{
  float minimumSimilarity;
  int prefixLength;
}

- (id) initWithTerm: (LCTerm *) term
       minimumSimilarity: (float) minimumSimilarity
       prefixLength: (int) prefixLength;
- (id) initWithTerm: (LCTerm *) term
       minimumSimilarity: (float) minimumSimilarity;
- (id) initWithTerm: (LCTerm *) term;
- (float) minSimilarity;
- (int) prefixLength;
- (LCFilteredTermEnum *) enum: (LCIndexReader *) reader;
- (LCQuery *) rewrite: (LCIndexReader *) reader;

@end

#endif /* __LUCENE_SEARCH_FUZZY_QUERY__ */
