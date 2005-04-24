#ifndef __LUCENE_SEARCH_BOOLEAN_QUERY__
#define __LUCENE_SEARCH_BOOLEAN_QUERY__

#include "Search/LCQuery.h"
#include "Search/LCWeight.h"

// private
@interface LCBooleanWeight: LCWeight
{
  LCSearcher *searcher;
  NSArray *weights;
}

- (id) initWithSearcher: (LCSearcher *) searcher;
- (LCQuery *) query;
- (float) value;
- (float) sumOfSquaredWeights;
- (void) normalize: (float) norm;
- (LCScorer *) scorer: (LCIndexReader *) reader;
- (LCExplanation *) explain: (LCIndexReader *) reader doc: (int) doc;
@end

@interface LCBooleanWeight2: LCBooleanWeight
@end

static int maxClauseCount = 1024
static BOOL useScore14 = NO;

@interface LCBooleanQuery: LCQuery
{
  NSArray *clauses;
  BOOL disableCoord;
}

+ (int) maxClauseCount;
+ (void) setMaxClauseCount: (int) maxClauseCount;

- (id) initWithCoord: (BOOL) disableCoord;

- (BOOL) isCoordDisabled;
- (LCSimilarity *) similarity: (LCSearcher *) searcher;
- (void) addQuery: (LCQuery *) query
         required: (BOOL) required
	 prohibited: (BOOL) prohibited;
- (void) addQuery: (LCQuery *) query
	  occur: (NSString *) occur;
- (void) addClause: (LCBooleanClause *) clause;
- (NSArray *) clauses;

+ (void) setUseScorer14: (BOOL) use14;
+ (BOOL) useScorer14;
- (LCWeight *) createWeight: (LCSearcher *) searcher;
- (LCQuery *) rewrite: (LCIndexReader *) reader;

@end

#endif /* __LUCENE_SEARCH_BOOLEAN_QUERY__ */
