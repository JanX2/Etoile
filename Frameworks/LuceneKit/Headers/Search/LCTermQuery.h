#ifndef __LUCENE_SEARCH_TERM_QUERY_
#define __LUCENE_SEARCH_TERM_QUERY_

#include <LuceneKit/Search/LCQuery.h>
#include <LuceneKit/Search/LCWeight.h>

@class LCTerm;
@class LCTermQuery;
@class LCSimilarity;
@class LCSearcher;

@interface LCTermWeight: NSObject <LCWeight>
{
	LCSimilarity *similarity;
	//LCSearcher *searcher;
	LCTermQuery *query;
	float value;
	float idf;
	float queryNorm;
	float queryWeight;
}
- (id) initWithTermQuery: (LCTermQuery *) query
				searcher: (LCSearcher *) searcher;
@end

@interface LCTermQuery: LCQuery
{
	LCTerm *term;
}
- (id) initWithTerm: (LCTerm *) term;
- (LCTerm *) term;
@end

#endif /* __LUCENE_SEARCH_TERM_QUERY_ */

