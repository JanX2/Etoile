#ifndef __LUCENE_SEARCH_BOOLEAN_SCORER2__
#define __LUCENE_SEARCH_BOOLEAN_SCORER2__

#include "Search/LCScorer.h"

/* LuceneKit: This is actuall the BooleanScorer2 in lucene */

@class LCBooleanScorer;
@class LCCoordinator;

@interface LCCoordinator: NSObject
{
	int maxCoord;
	NSMutableArray *coordFactors;
	
	int nrMatchers;
	LCBooleanScorer *scorer;
}
- (id) initWithScorer: (LCBooleanScorer *) scorer;
- (void) initiation; /* LuceneKit: init in lucene */
- (void) initiateDocument;
- (float) coordFactor;
- (int) maxCoord;
- (void) setMaxCoord: (int) maxCoord;
- (int) nrMatchers;
- (void) setNrMatchers: (int) matchers;
@end

@interface LCSingleMatchScorer: LCScorer
{
	LCScorer *scorer;
	LCCoordinator *coordinator;
}

- (id) initWithScorer: (LCScorer *) scorer
		  coordinator: (LCCoordinator *) coordinator;
@end

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
- (void) initCountingSumScorer;
- (LCScorer *) countingDisjunctionSumScorer: (NSArray *) scorers;
- (LCScorer *) countingConjunctionSumScorer: (NSArray *) requiredScorers;
- (LCScorer *) makeCountingSumScorer;
- (LCScorer *) makeCountingSumScorer2: (LCScorer *) requiredCountingSumScorer
							 optional: (NSArray *) optionalScorers;
- (LCScorer *) makeCountingSumScorer3: (LCScorer *) requiredCountingSumScorer
							 optional: (LCScorer *) optionalCountingSumScorer;
@end

#endif /* __LUCENE_SEARCH_BOOLEAN_SCORER2__ */
