#ifndef __LUCENE_SEARCH_MULTI_TERM_QUERY__
#define __LUCENE_SEARCH_MULTI_TERM_QUERY__

#include "Search/LCQuery.h"

@interface LCMultiTermQuery: LCQuery
{
	LCTerm *term;
}

- (id) initWithTerm: (LCTerm *) term;
- (LCTerm *) term;
- (LCFilteredTermEnum *) enum: (LCIndexReader *) reader
- (LCQuery *) rewrite: (LCIndexReader *) reader;
- (LCQuery *) combine: (NSArray *) queries;

@end

#endif /* __LUCENE_SEARCH_MULTI_TERM_QUERY__ */
