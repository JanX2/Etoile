#ifndef __LUCENE_SEARCH_BOOLEAN_QUERY__
#define __LUCENE_SEARCH_BOOLEAN_QUERY__

#include "Search/LCQuery.h"
#include "Search/LCWeight.h"
#include "Search/LCBooleanClause.h"

@class LCSimilarity;
@class LCSearcher;
@class LCBooleanQuery;

// private
/* LuceneKit: this is actually BooleanWeight2 in lucene */
@interface LCBooleanWeight: NSObject <LCWeight>
{
	LCSimilarity *similarity;
	LCBooleanQuery *query;
	NSMutableArray *weights;
}

- (id) initWithSearcher: (LCSearcher *) searcher
                  query: (LCBooleanQuery *) query;
@end

//static int maxClauseCount = 1024;

@interface LCBooleanQuery: LCQuery
{
	NSMutableArray *clauses;
	BOOL disableCoord;
}

+ (int) maxClauseCount;
+ (void) setMaxClauseCount: (int) maxClauseCount;

- (id) initWithCoordination: (BOOL) disableCoord;

- (BOOL) isCoordinationDisabled;
- (LCSimilarity *) similarity: (LCSearcher *) searcher;
- (void) addQuery: (LCQuery *) query
         required: (BOOL) required
	   prohibited: (BOOL) prohibited;
- (void) addQuery: (LCQuery *) query
			occur: (LCOccurType) occur;
- (void) addClause: (LCBooleanClause *) clause;
- (NSArray *) clauses;
- (void) setClauses: (NSArray *) clauses;
- (void) replaceClauseAtIndex: (int) index 
				   withClause: (LCBooleanClause *) clause;
@end

#endif /* __LUCENE_SEARCH_BOOLEAN_QUERY__ */
