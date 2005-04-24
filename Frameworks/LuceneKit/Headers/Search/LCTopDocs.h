#ifndef __LUCENE_SEARCH_TOP_DOCS__
#define __LUCENE_SEARCH_TOP_DOCS__

#include <Foundation/Foundation.h>

@interface LCTopDocs: NSObject
{
  /** Expert: The total number of hits for the query.
   * @see Hits#length()
   */
  int totalHits;
  /** Expert: The top hits for the query. */
  NSArray *scoreDocs;
}
/** Expert: Constructs a TopDocs.*/
- (id) initWithTotalHits: (int) totalHits 
       scoreDocuments: (NSArray *) scoreDocs;
@end

#endif /* __LUCENE_SEARCH_TOP_DOCS__ */
