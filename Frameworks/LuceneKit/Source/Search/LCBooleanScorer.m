#include "LCBooleanScorer.h"
#include "LCDisjunctionSumScorer.h"
#include "LCConjunctionScorer.h"
#include "LCReqExclScorer.h"
#include "LCReqOptSumScorer.h"
#include "LCDefaultSimilarity.h"
#include "LCNonMatchingScorer.h"
#include "GNUstep.h"

/* LuceneKit: This is actually BooleanScorer2 in lucene */
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

@interface LCBooleanDisjunctionSumScorer: LCDisjunctionSumScorer
{
	LCCoordinator *coordinator;
	int lastScoredDoc;
}
- (id) initWithSubScorers: (NSArray *) subScorers
		minimumNrMatchers: (int) minimumNrMatchers
			  coordinator: (LCCoordinator *) c;
@end

@interface LCBooleanConjunctionScorer: LCConjunctionScorer
{
	LCCoordinator *coordinator;
	int requiredNrMatchers;
	int lastScoredDoc;
}
- (id) initWithSimilarity: (LCSimilarity *) similarity
			  coordinator: (LCCoordinator *) c
       requiredNrMatchers: (int) required;
@end

@interface LCSingleMatchScorer: LCScorer
{
	LCScorer *scorer;
	LCCoordinator *coordinator;
	int lastScoredDoc;
}

- (id) initWithScorer: (LCScorer *) scorer
		  coordinator: (LCCoordinator *) coordinator;
@end

@interface LCBooleanScorer (LCPrivate)
- (void) initCountingSumScorer;
- (LCScorer *) countingDisjunctionSumScorer: (NSArray *) scorers;
- (LCScorer *) countingConjunctionSumScorer: (NSArray *) requiredScorers;
- (LCScorer *) makeCountingSumScorer;
- (LCScorer *) makeCountingSumScorer2: (LCScorer *) requiredCountingSumScorer
							 optional: (NSArray *) optionalScorers;
- (LCScorer *) makeCountingSumScorer3: (LCScorer *) requiredCountingSumScorer
							 optional: (LCScorer *) optionalCountingSumScorer;

@end

@implementation LCBooleanScorer
- (id) init
{
	self = [super init];
	requiredScorers = [[NSMutableArray alloc] init];
	optionalScorers = [[NSMutableArray alloc] init];
	prohibitedScorers = [[NSMutableArray alloc] init];
	countingSumScorer = nil;
	ASSIGN(similarity, AUTORELEASE([[LCDefaultSimilarity alloc] init]));
	return self;
}

- (id) initWithSimilarity: (LCSimilarity *) s
{
	self = [super initWithSimilarity: s];
	coordinator = [[LCCoordinator alloc] initWithScorer: self];
	return self;
}
- (void) addScorer: (LCScorer *) scorer
		  required: (BOOL) required
		prohibited: (BOOL) prohibited
{
	if (!prohibited) {
		[coordinator setMaxCoord: [coordinator maxCoord] + 1];
	}
	
	if (required) {
		if (prohibited) {
			NSLog(@"Scorer cannot be required and prohibited");
		}
		[requiredScorers addObject: scorer];
	} else if (prohibited) {
		[prohibitedScorers addObject: scorer];
	} else {
		[optionalScorers addObject: scorer];
	}
}

- (void) initCountingSumScorer
{
	[coordinator initiation];
	ASSIGN(countingSumScorer, [self makeCountingSumScorer]);
}

- (LCScorer *) countingDisjunctionSumScorer: (NSArray *) scorers
{
	return AUTORELEASE([[LCBooleanDisjunctionSumScorer alloc] initWithSubScorers: scorers
															   minimumNrMatchers: 1
																	 coordinator: coordinator]);
}

- (LCScorer *) countingConjunctionSumScorer: (NSArray *) scorers
{
	int requiredNrMatchers = [requiredScorers count];
	// LuceneKit: Why always use LCDefaultSimilarity ?
	LCBooleanConjunctionScorer *cs = [[LCBooleanConjunctionScorer alloc] initWithSimilarity: AUTORELEASE([[LCDefaultSimilarity alloc] init])
																				coordinator: coordinator
																		 requiredNrMatchers: requiredNrMatchers];
	NSEnumerator *e = [requiredScorers objectEnumerator];
	LCScorer *scorer;
	while ((scorer = [e nextObject]))
	{
		[cs addScorer: scorer];
	}
	return AUTORELEASE(cs);
}

- (LCScorer *) makeCountingSumScorer
{
#if 0
	NSLog(@"LCBooleanScorer -makeCountingSumScorer");
	NSLog(@"requiredScorers %@", requiredScorers);
	NSLog(@"optionalScorers %@", optionalScorers);
	NSLog(@"prohibitedScorers %@", prohibitedScorers);
#endif
	if ([requiredScorers count] == 0) {
		if ([optionalScorers count] == 0) { // only prohibited scorers
			return AUTORELEASE([[LCNonMatchingScorer alloc] init]);
		} else if ([optionalScorers count] == 1) {
			LCSingleMatchScorer *ms = [[LCSingleMatchScorer alloc] initWithScorer: [optionalScorers objectAtIndex: 0]
																	  coordinator: coordinator];
			return [self makeCountingSumScorer2: ms 
									   optional: [[NSArray alloc] init]];
		} else { // more than 1 optionalScorers, no required scorers
			LCScorer *s = [self countingDisjunctionSumScorer: optionalScorers];
			return [self makeCountingSumScorer2: s
									   optional: [[NSArray alloc] init]];
		}
	} else if ([requiredScorers count] == 1) { // 1 required
		LCSingleMatchScorer *ms = [[LCSingleMatchScorer alloc] initWithScorer: [requiredScorers objectAtIndex: 0]
																  coordinator: coordinator];
		return [self makeCountingSumScorer2: AUTORELEASE(ms) optional: optionalScorers];
	} else { // more required scorers
		LCScorer *s = [self countingConjunctionSumScorer: requiredScorers];
		return [self makeCountingSumScorer2: s
								   optional: optionalScorers];
	}
}

- (LCScorer *) makeCountingSumScorer2: (LCScorer *) requiredCountingSumScorer
							 optional: (NSArray *) os
{
#if 0
	NSLog(@"LCBooleanScorer -makeCountingSumScorer2");
	NSLog(@"RequiredCountingSumScorer %@", requiredCountingSumScorer);
	NSLog(@"optional %@", os);
#endif
	if ([os count] == 0) { // no optional
		if ([prohibitedScorers count] == 0) { // no prohibited
			return requiredCountingSumScorer;
		} else if ([prohibitedScorers count] == 1) { // no optional, 1 prohibited
			LCReqExclScorer *res = [[LCReqExclScorer alloc] initWithRequired: requiredCountingSumScorer excluded: [prohibitedScorers objectAtIndex: 0]];
			return AUTORELEASE(res);
		} else { // no optional, more prohibited
			LCDisjunctionSumScorer *dss = [[LCDisjunctionSumScorer alloc] initWithSubScorers: prohibitedScorers];
			LCReqExclScorer *res = [[LCReqExclScorer alloc] initWithRequired: requiredCountingSumScorer excluded: dss];
			RELEASE(dss);
			return AUTORELEASE(res);
		}
	} else if ([os count] == 1) { // 1 optional
		LCSingleMatchScorer *sms = [[LCSingleMatchScorer alloc] initWithScorer: [os objectAtIndex: 0]
																   coordinator: coordinator];
		return [self makeCountingSumScorer3: requiredCountingSumScorer
								   optional: sms];
	} else { // more optional
		return [self makeCountingSumScorer3: requiredCountingSumScorer
								   optional: [self countingDisjunctionSumScorer: os]];
	}
}

- (LCScorer *) makeCountingSumScorer3: (LCScorer *) requiredCountingSumScorer
							 optional: (LCScorer *) optionalCountingSumScorer
{
	if ([prohibitedScorers count] == 0) { // no prohibited
		return AUTORELEASE([[LCReqOptSumScorer alloc] initWithRequired: requiredCountingSumScorer optional: optionalCountingSumScorer]);
	} else if ([prohibitedScorers count] == 1) { // 1 prohibited
		LCReqExclScorer *res = [[LCReqExclScorer alloc] initWithRequired: requiredCountingSumScorer excluded: [prohibitedScorers objectAtIndex: 0]]; // no match counting
		return AUTORELEASE([[LCReqOptSumScorer alloc] initWithRequired: res optional: optionalCountingSumScorer]);
	} else { // more prohibited
		LCDisjunctionSumScorer *disjunction = [[LCDisjunctionSumScorer alloc] initWithSubScorers: prohibitedScorers]; // score unused, not match counting
		LCReqExclScorer *res = [[LCReqExclScorer alloc] initWithRequired: requiredCountingSumScorer excluded: disjunction];
		LCReqOptSumScorer *ros = [[LCReqOptSumScorer alloc] initWithRequired: res optional: optionalCountingSumScorer];
		return AUTORELEASE(ros);
	}
}

- (void) score: (LCHitCollector *) hc
{
	//NSLog(@"LCBooleanScorer -score: %@", hc);
	if (countingSumScorer == nil) {
		[self initCountingSumScorer];
	}
	while ([countingSumScorer next]) {
		[hc collect: [countingSumScorer document] score: [self score]];
	}
}

- (BOOL) score: (LCHitCollector *) hc maximalDocument: (int) max
{
	int docNr = [countingSumScorer document];
	while (docNr < max) {
		[hc collect: docNr score: [self score]];
		if (![countingSumScorer next]) {
			return NO;
		}
		docNr = [countingSumScorer document];
	}
	return YES;
}

- (int) document { return [countingSumScorer document]; }

- (BOOL) next
{
	if (countingSumScorer == nil) {
		[self initCountingSumScorer];
	}
	return [countingSumScorer next];
}

- (float) score
{
	[coordinator initiateDocument];
	float sum = [countingSumScorer score];
	return (sum * [coordinator coordFactor]);
}

- (BOOL) skipTo: (int) target
{
	if (countingSumScorer == nil) {
		[self initCountingSumScorer];
	}
	return [countingSumScorer skipTo: target];
}

- (LCExplanation *) explain: (int) doc
{
	NSLog(@"not supported");
	return nil;
}

@end

@implementation LCBooleanConjunctionScorer 
- (id) initWithSimilarity: (LCSimilarity *) s
			  coordinator: (LCCoordinator *) c
       requiredNrMatchers: (int) required
{
	self = [super initWithSimilarity: s];
	ASSIGN(coordinator, c);
	requiredNrMatchers = required;
	lastScoredDoc = -1;
	return self;
}

- (float) score
{
	if ([self document] > lastScoredDoc) {
		lastScoredDoc = [self document];
		[coordinator setNrMatchers: [coordinator nrMatchers] + requiredNrMatchers];
	}
	return [super score];
}
@end

@implementation LCBooleanDisjunctionSumScorer
- (id) initWithSubScorers: (NSArray *) sub
		minimumNrMatchers: (int) minimum
			  coordinator: (LCCoordinator *) c
{
	self = [super initWithSubScorers: sub
				   minimumNrMatchers: minimum];
	ASSIGN(coordinator, c);
	lastScoredDoc = -1;
	return self;
}

- (float) score
{
	if ([self document] > lastScoredDoc) {
		lastScoredDoc = [self document];
		[coordinator setNrMatchers: [coordinator nrMatchers] + nrMatchers];
	}
	return [super score];
}
@end

@implementation LCSingleMatchScorer
- (id) initWithScorer: (LCScorer *) s coordinator: (LCCoordinator *) c
{
	self = [self initWithSimilarity: [s similarity]];
	ASSIGN(scorer, s);
	ASSIGN(coordinator, c);
	lastScoredDoc = -1;
	return self;
}

- (float) score
{
	if ([self document] > lastScoredDoc)
	{
		lastScoredDoc = [self document];
		[coordinator setNrMatchers: [coordinator nrMatchers] + 1];
	}
	return [scorer score];
}

- (int) document
{
	return [scorer document];
}

- (BOOL) next
{
	return [scorer next];
}

- (BOOL) skipTo: (int) target
{
	return [scorer skipTo: target];
}

- (LCExplanation *) explain: (int) document
{
	return [scorer explain: document];
}

@end

@implementation LCCoordinator
- (id) initWithScorer: (LCBooleanScorer *) s
{
	self = [self init];
	ASSIGN(scorer, s);
	maxCoord = 0;
	return self;
}

- (void) initiation
{
	coordFactors = [[NSMutableArray alloc] init];
	LCSimilarity *sim = [scorer similarity];
	//NSLog(@"sim %@", sim);
	int i;
	for (i = 0; i <= maxCoord; i++)
	{
		//NSLog(@"LCCoordinator: i = %d, coord = %f, maxCoord = %d", i, [sim coordination: i max: maxCoord], maxCoord);
		[coordFactors addObject: [NSNumber numberWithFloat: [sim coordination: i max: maxCoord]]];
	}
}

- (void) initiateDocument
{
	nrMatchers = 0;
}

- (float) coordFactor 
{ 
	return [[coordFactors objectAtIndex: nrMatchers] floatValue]; 
}

- (int) maxCoord { return maxCoord; }
- (void) setMaxCoord: (int) max { maxCoord = max; }
- (int) nrMatchers { return nrMatchers; }
- (void) setNrMatchers: (int) matchers { nrMatchers = matchers; }
@end
