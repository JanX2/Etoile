#include "Search/LCTopDocs.h"
#include "GNUstep/GNUstep.h"

/** Expert: Returned by low-level search implementations.
 * @see Searcher#search(Query,Filter,int) */
@implementation LCTopDocs: NSObject // Serializable

- (id) initWithTotalHits: (int) th
       scoreDocuments: (NSArray *) sd
{
  self = [super init];
  totalHits = th;
  ASSIGN(scoreDocs, sd);
  return self;
}

- (void) dealloc
{
  DESTROY(scoreDocs);
  [super dealloc];
}

@end
