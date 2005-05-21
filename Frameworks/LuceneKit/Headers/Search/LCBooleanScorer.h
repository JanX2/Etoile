#ifndef __LUCENE_SEARCH_BOOLEAN_SCORER2__
#define __LUCENE_SEARCH_BOOLEAN_SCORER2__

#include <LuceneKit/Search/LCScorer.h>

/* LuceneKit: This is actuall the BooleanScorer2 in lucene */

@class LCBooleanScorer;
@class LCCoordinator;

@interface LCBooleanScorer: LCScorer
{
	NSMutableArray *requiredScorers;
	NSMutableArray *optionalScorers;
	NSMutableArray *prohibitedScorers;
	
	LCCoordinator *coordinator;
	LCScorer *countingSumScorer;
	
	LCSimilarity *defaultSimilarity;
}

- (id) initWithSimilarity: (LCSimilarity *) similarity;
- (void) addScorer: (LCScorer *) scorer
		  required: (BOOL) required
		prohibited: (BOOL) prohibited;
@end

#endif /* __LUCENE_SEARCH_BOOLEAN_SCORER2__ */
