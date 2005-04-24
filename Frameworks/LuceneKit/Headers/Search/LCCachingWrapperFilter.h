#ifndef __LUCENE_SEARCH_CACHING_WRAPPER_FILTER__
#define __LUCENE_SEARCH_CACHING_WRAPPER_FILTER__

#include "Search/LCFilter.h"

@interface LCCachingWrapperFilter
{
  LCFilter *filter;
  LCDictionary *cache;
}

- (id) initWithFilter: (LCFilter *) filter;
- (LCBitSet *) bits: (LCIndexReader *) reader;
@end

#endif /* __LUCENE_SEARCH_CACHING_WRAPPER_FILTER__ */
