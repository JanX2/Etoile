#ifndef __LUCENE_SEARCH_QUERY_FILTER__
#define __LUCENE_SEARCH_QUERY_FILTER__

#include "Search/LCFilter.h"

@interface LCQueryFilter: LCFilter
{
  LCQuery *query;
  NSDictionary *cache;
}

- (id) initWithQuery: (LCQuery *) query;
- (LCBitSet *) bits: (LCIndexReader *) reader;

@end

#endif /* __LUCENE_SEARCH_QUERY_FILTER__ */
