#ifndef __LUCENE_SEARCH_FUZZY_QUERY__
#define __LUCENE_SEARCH_FUZZY_QUERY__

#include <LuceneKit/Search/LCMultiTermQuery.h>

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
- (float) minSimilarity;
- (int) prefixLength;
+ (float) defaultMinSimilarity;
+ (int) defaultPrefixLength;


@end

#endif /* __LUCENE_SEARCH_FUZZY_QUERY__ */
