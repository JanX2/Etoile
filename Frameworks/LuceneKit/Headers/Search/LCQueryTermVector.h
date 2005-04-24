#ifndef __LUCENE_SEARCH_QUERY_TERM_VECTOR__
#define __LUCENE_SEARCH_QUERY_TERM_VECTOR__

#include "Index/LCTermFreqVector.h"

@interface LCQueryTermVector: NSObject <LCTermFreqVector>
{
  NSArray *terms;
  NSArray *termFreqs;
}

- (id) initWithQueryTerms: (NSArray *) queryTerm;
- (id) initWithQueryTerms: (NSArray *) queryTerm 
       analyzer: (LCAnalyzer *) analyzer;
- (NSString *) field;
- (void) processTerms: (NSArray *) queryTerms;
- (int) size;
- (NSArray *) terms;
- (NSArray *) termFrequencies;
- (int) indexOfTerm: (LCTerm *) term;
- (NSArray *) IndexOfTerms: (NSArray *) terms start: (int) start length: (int) len;

@end

#endif /* __LUCENE_SEARCH_QUERY_TERM_VECTOR__ */
