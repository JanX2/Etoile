#ifndef __LUCENE_SEARCH_QUERY__
#define __LUCENE_SEARCH_QUERY__

#include <Foundation/Foundation.h>

@implementation LCQuery: NSObject <NSCopying> // Seriable
{
  float boost;
}
- (void) setBoost: (float) b;
- (float) boost;
- (NSString *) descriptionWithQuery: (NSString *) query;
- (LCWeight *) createWeight: (LCSearcher *) searcher;
- (LCWeight *) weight: (LCSearcher *) searcher;
- (LCQuery *) rewrite: (LCIndexReader *) reader;
- (LCQuery *) combine: (NSArray *) queries;
+ (LCQuery *) mergeBooleanQueries: (NSArray *) queries;
- (LCSimilarity *) similarity: (LCSearcher *) searcher;
@end
#endif /* __LUCENE_SEARCH_QUERY__ */
