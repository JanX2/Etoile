#ifndef __LUCENE_SEARCH_QUERY_TERM_VECTOR__
#define __LUCENE_SEARCH_QUERY_TERM_VECTOR__

#include <LuceneKit/Index/LCTermFreqVector.h>

@class LCAnalyzer;

@interface LCQueryTermVector: NSObject <LCTermFreqVector>
{
	NSMutableArray *terms;
	NSMutableArray *termFreqs;
}

- (id) initWithQueryTerms: (NSArray *) queryTerms;
- (id) initWithString: (NSString *) queryString
			 analyzer: (LCAnalyzer *) analyzer;
- (void) processTerms: (NSArray *) queryTerms;

@end

#endif /* __LUCENE_SEARCH_QUERY_TERM_VECTOR__ */
