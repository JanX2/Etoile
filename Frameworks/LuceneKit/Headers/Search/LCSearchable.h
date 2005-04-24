#ifndef __LUCENE_SEARCH_SEARCHABLE__
#define __LUCENE_SEARCH_SEARCHABLE__

#include <Foundation/Foundation.h>
#include "Search/LCWeight.h"

@class LCQuery;
@class LCFilter;
@class LCHitCollector;
@class LCTerm;
@class LCDocument;
@class LCExplanation;
@class LCTopDocs;
@class LCTopFieldDocs;
@class LCSort;

@protocol LCSearchable <NSObject>
- (void) search: (id <LCWeight>) weight 
              filter: (LCFilter *) filter
	   hitCollector: (LCHitCollector *) results;
- (void) close;
- (int) documentFrequencyWithTerm: (LCTerm *) term;
- (NSArray *) documentFrequencyWithTerms: (NSArray *) terms;
- (int) maximalDocument;
- (LCTopDocs *) search: (id <LCWeight>) weight 
                filter: (LCFilter *) filter
		maximum: (int) n;
- (LCDocument *) document: (int) i;
- (LCQuery *) rewrite: (LCQuery *) query;
- (LCExplanation *) explainWithQuery: (LCQuery *) query
                      document: (int) doc;
- (LCExplanation *) explainWithWeight: (id <LCWeight>) weight 
                      document: (int) doc;
- (LCTopFieldDocs *) search: (id <LCWeight>) weight 
                     filter: (LCFilter *) filter
		     maximum: (int) n
		     sort: (LCSort *) sort;
@end
#endif /* __LUCENE_SEARCH_SEARCHABLE__ */
