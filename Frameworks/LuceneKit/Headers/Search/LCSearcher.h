#ifndef __LUCENE_SEARCH_SEARCHER__
#define __LUCENE_SEARCH_SEARCHER__

#include "Search/LCSearchable.h"

@class LCSimilarity;
@class LCHits;
@class LCQuery;
@class LCSort;
@class LCFilter;
@class LCHitCollector;

@interface LCSearcher: NSObject <LCSearchable>
{
	LCSimilarity *similarity;
}
- (LCHits *) search: (LCQuery *) query;
- (LCHits *) search: (LCQuery *) query
			 filter: (LCFilter *) filter;
- (LCHits *) search: (LCQuery *) query sort: (LCSort *) sort;
- (LCHits *) search: (LCQuery *) query 
             filter: (LCFilter *) filter sort: (LCSort *) sort;
- (void) search: (LCQuery *) query
   hitCollector: (LCHitCollector *) results;
- (void) setSimilarity: (LCSimilarity *) similarity;
- (LCSimilarity *) similarity;

@end

#endif /* __LUCENE_SEARCH_SEARCHER__ */
