#ifndef __LUCENE_SEARCH_HITS__
#define __LUCENE_SEARCH_HITS__

#include <Foundation/Foundation.h>

@interface LCHitDoc: NSObject
{
  float score;
  int identifier;
  LCDocument *doc;

  LCHitDoc *next;
  LCHitDoc *prev;
}

- (id) initWithScore: (float) s identifier: (int) iden;
@end

@interface LCHits: NSObject
{
  LCQuery *query;
  LCSearcher *searcher;
  LCFilter *filter;
  LCSort *soft;
  int length;
  NSArray *hitDocs;
  LCHitDoc *first;
  LCHitDoc *last;
  int numDocs;
  int maxDocs;
}

- (id) initWithSearcher: (LCSearcher *) s
                 query: (LCQuery *) q
		 filter: (LCFilter *) f;
- (id) initWithSearcher: (LCSearcher *) s
                 query: (LCQuery *) q
		 filter: (LCFilter *) f
		 sort: (LCSort *) s;
- (void) moreDocs: (int) min;
- (int) length;
- (LCDocument *) doc: (int) n;
- (float) score: (int) n;
- (int) identifier: (int) n;
- (LCHitDoc *) hitDoc: (int) n;
- (void) addToFront: (LCHitDoc *) hitDoc;
- (void) remove: (LCHitDoc *) hitDoc;

@end

#endif /* __LUCENE_SEARCH_HITS__ */
