#ifndef __LUCENE_SEARCH_QUERY__
#define __LUCENE_SEARCH_QUERY__

#include <Foundation/Foundation.h>
#include "Search/LCWeight.h"
#include "Search/LCSearcher.h"
#include "Search/LCSimilarity.h"
#include "Index/LCIndexReader.h"

@interface LCQuery: NSObject <NSCopying> // Seriable
{
  float boost;
}
- (void) setBoost: (float) b;
- (float) boost;
- (NSString *) descriptionWithField: (NSString *) field;
- (id <LCWeight>) createWeight: (LCSearcher *) searcher;
- (id <LCWeight>) weight: (LCSearcher *) searcher;
- (LCQuery *) rewrite: (LCIndexReader *) reader;
- (LCQuery *) combine: (NSArray *) queries;
- (void) extractTerms: (NSSet *) terms;
+ (LCQuery *) mergeBooleanQueries: (NSArray *) queries;
- (LCSimilarity *) similarity: (LCSearcher *) searcher;
@end
#endif /* __LUCENE_SEARCH_QUERY__ */
