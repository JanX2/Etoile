#ifndef __LUCENE_SEARCH_SEARCHABLE__
#define __LUCENE_SEARCH_SEARCHABLE__

#include <Foundation/Foundation.h>

@protocol LCSearchable <NSObject>
- (void) searchQuery: (LCQuery *) query
              filter: (LCFilter *) filter
	   hitCollector: (LCHitCollector *) results;
- (void) close;
- (int) docFreq: (LCTerm *) term;
- (int) maxDoc;
- (LCTopDocs *) search: (LCQuery *) query
                 filter: (LCFilter *) filter
		  number: (int) n;
- (LCDocument *) doc: (int) i;
- (LCQuery *) rewrite: (LCQuery *) query;
- (LCExplanation *) explain: (LCQuery *) query
                      doc: (int) doc;
- (LCTopFieldDocs *) search: (LCQuery *) query
                     filter: (LCFilter *) filter
		     number: (int) n
		     sort: (LCSort *) sort;
@end
#end /* __LUCENE_SEARCH_SEARCHABLE__ */
