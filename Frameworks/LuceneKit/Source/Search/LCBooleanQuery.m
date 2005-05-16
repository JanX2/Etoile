#include <LuceneKit/Search/LCBooleanQuery.h>
#include <LuceneKit/Search/LCSimilarityDelegator.h>
#include <LuceneKit/Search/LCSearcher.h>
#include <LuceneKit/Search/LCBooleanScorer.h>
#include <LuceneKit/GNUstep/GNUstep.h>

@interface LCBooleanSimilarityDelegator: LCSimilarityDelegator
@end

@implementation LCBooleanSimilarityDelegator
- (float) coordination: (int) overlap max: (int) maxOverlap
{
	return 1.0f;
}
@end

static int maxClauseCount = 1024;

@implementation LCBooleanQuery
+ (int) maxClauseCount { return maxClauseCount; }
+ (void) setMaxClauseCount: (int) max { maxClauseCount = max; }
- (id) init
{
	self = [super init];
	clauses = [[NSMutableArray alloc] init];
	return self;
}
- (id) initWithCoordination: (BOOL) dc
{
	self = [self init];
	disableCoord = dc;
	return self;
}
- (BOOL) isCoordinationDisabled { return disableCoord; }
- (LCSimilarity *) similarity: (LCSearcher *) searcher
{
	LCSimilarity *result = [super similarity: searcher];
	if (disableCoord) { // disable coord as requested
		result = [[LCBooleanSimilarityDelegator alloc] init];
		AUTORELEASE(result);
	}
	return result;
}

- (void) addQuery: (LCQuery *) query
         required: (BOOL) required
	   prohibited: (BOOL) prohibited
{
	LCBooleanClause *clause = [[LCBooleanClause alloc] initWithQuery: query
															required: required prohibited: prohibited];
	[self addClause: clause];
	RELEASE(clause);
}

- (void) addQuery: (LCQuery *) query
			occur: (LCOccurType) occur
{
	LCBooleanClause *clause = [[LCBooleanClause alloc] initWithQuery: query occur: occur];
	[self addClause: clause];
	RELEASE(clause);
}

- (void) addClause: (LCBooleanClause *) clause
{
	if ([clauses count] >= maxClauseCount)
	{
		NSLog(@"Too many clauses");
		return;
	}
	[clauses addObject: clause];
}

- (NSArray *) clauses
{
	return clauses;
}

- (void) setClauses: (NSArray *) c
{
	[clauses setArray: c];
}

- (id <LCWeight>) createWeight: (LCSearcher *) searcher
{
	return AUTORELEASE([[LCBooleanWeight alloc] initWithSearcher: searcher query: self]);
}

- (LCQuery *) rewrite: (LCIndexReader *) reader
{
	if ([clauses count] == 1) { // optimize 1-clause queries
		LCBooleanClause *c = [clauses objectAtIndex: 0];
		if ([c isProhibited]) { // just return clause
			LCQuery *query = [[c query] rewrite: reader]; // rewrite first
			if ([self boost] != 1.0f) {// incorporate boost
				if ([query isEqual: [c query]]) // if rewrite was no-op
					query = [query copy];
				[query setBoost: [self boost] * [query boost]];
			}
			return query;
		}
	}
	
	LCBooleanQuery *clone = nil; // recursively rewrite
	int i;
	for (i = 0; i < [clauses count]; i++) {
		LCBooleanClause *c = [clauses objectAtIndex: i];
		LCQuery *query = [[c query] rewrite: reader];
		if ([query isEqual: [c query]] == NO) { // clause rewrote: must clone
			if (clone = nil)
				clone = [self copy];
			LCBooleanClause *clause = [[LCBooleanClause alloc] initWithQuery: query occur: [c occur]];
			[clone replaceClauseAtIndex: i withClause: AUTORELEASE(clause)];
		}
	}
	if (clone != nil) {
		return clone; // some clauses rewrote
	} else {
		return self; // no clauses rewrote
	}
}

- (void) extractTerms: (NSMutableArray *) terms
{
	NSEnumerator *e = [clauses objectEnumerator];
	LCBooleanClause *clause;
	while ((clause = [e nextObject])) {
		[[clause query] extractTerms: terms];
	}
}

- (LCQuery *) combine: (NSArray *) queries
{
	return [LCQuery mergeBooleanQueries: queries];
}

- (LCQuery *) copyWithZone: (NSZone *) zone
{
	LCBooleanQuery *clone = [super copyWithZone: zone];
	[clone setClauses: AUTORELEASE([[self clauses] copy])];
	return clone;
}

- (void) replaceClauseAtIndex: (int) index 
				   withClause: (LCBooleanClause *) clause
{
	[clauses replaceObjectAtIndex: index withObject: clause];
}

- (NSString *) descriptionWithField: (NSString *) field
{
	NSMutableString *s = [[NSMutableString alloc] init];
	if ([self boost] != 1.0) {
		[s appendString: @"("];
	}
	int i;
	for (i = 0; i < [clauses count]; i++) {
		LCBooleanClause *c = [clauses objectAtIndex: i];
		if ([c isProhibited])
			[s appendString: @"-"];
		else if ([c isRequired])
			[s appendString: @"+"];
		
		LCQuery *subQuery = [c query];
		if ([subQuery isKindOfClass: [LCBooleanQuery class]]) { // wrap sub-bools is parens
			[s appendString: @"("];
			[s appendString: [[c query] descriptionWithField: field]];
			[s appendString: @")"];
		} else
			[s appendString: [[c query] descriptionWithField: field]];
		
		if (i != [clauses count]-1)
			[s appendString: @" "];
	}
	
	return AUTORELEASE(s);
}

- (BOOL) isEqual: (id) o
{
	if (![o isKindOfClass: [LCBooleanQuery class]])
		return NO;
	LCBooleanQuery *other = (LCBooleanQuery *)o;
	if (([self boost] == [other boost]) &&
		([clauses isEqualToArray: [other clauses]]))
		return YES;
	else
		return NO;
}

- (unsigned) hash
{
	return (unsigned)((int)[self boost] ^ [clauses hash]);
}

@end

@implementation LCBooleanWeight
- (id) initWithSearcher: (LCSearcher *) searcher
                  query: (LCBooleanQuery *) q
{
	self = [super init];
	ASSIGN(query, q);
	ASSIGN(similarity, [query similarity: searcher]);
	weights = [[NSMutableArray alloc] init];
	NSArray *clauses = [query clauses];
	int i;
	for (i = 0; i < [clauses count]; i++) 
	{
		LCBooleanClause *c = [clauses objectAtIndex: i];
		[weights addObject: [[c query] createWeight: searcher]];
	}
	return self;
}

- (void) dealloc
{
	DESTROY(weights);
	[super dealloc];
}

- (LCQuery *) query
{
	return query;
}

- (float) value
{
	return [query boost];
}

- (float) sumOfSquaredWeights
{
	float sum = 0.0f;
	NSArray *clauses = [query clauses];
	int i;
	for (i = 0; i < [weights count]; i++) {
		LCBooleanClause *c = [clauses objectAtIndex: i];
		id <LCWeight> w = [weights objectAtIndex: i];
		if (![c isProhibited])
			sum += [w sumOfSquaredWeights]; // sum sub weights
	}
	sum *= [query boost] * [query boost]; // boost each sub-weight
	
	return sum;
}

- (void) normalize: (float) n
{
	float norm = n * [query boost]; // incorporate boost
	int i;
	NSArray *clauses = [query clauses];
	for (i = 0; i < [weights count]; i++) {
		LCBooleanClause *c = [clauses objectAtIndex: i];
		id <LCWeight> w = [weights objectAtIndex: i];
		if (![c isProhibited])
			[w normalize: norm];
	}
}

- (LCScorer *) scorer: (LCIndexReader *) reader
{
	/* LuceneKit: this is actually BooleanScorer2 in lucene */
	LCBooleanScorer *result = [[LCBooleanScorer alloc] initWithSimilarity: similarity];
	NSArray *clauses = [query clauses];
	int i;
	for (i = 0; i < [weights count]; i++)
	{
		LCBooleanClause *c = [clauses objectAtIndex: i];
		id <LCWeight> w = [weights objectAtIndex: i];
		LCScorer *subScorer = [w scorer: reader];
		if (subScorer != nil)
			[result addScorer: subScorer required: [c isRequired] prohibited: [c isProhibited]];
		else if ([c isRequired])
			return nil;
	}
	return AUTORELEASE(result);
}

- (LCExplanation *) explain: (LCIndexReader *) reader
				   document: (int) doc
{
	LCExplanation *sumExpl = [[LCExplanation alloc] init];
	[sumExpl setRepresentation: @"sum of:"];
	int coord = 0;
	int maxCoord = 0;
	float sum = 0.0f;
	int i;
	NSArray *clauses = [query clauses];
	for (i = 0; i < [weights count]; i++)
	{
		LCBooleanClause *c = [clauses objectAtIndex: i];
		id <LCWeight> w = [weights objectAtIndex: i];
		LCExplanation *e = [w explain: reader document: doc];
		if (![c isProhibited]) maxCoord++;
		if ([e value] > 0) {
			if (![c isProhibited]) {
				[sumExpl addDetail: e];
				sum += [e value];
				coord++;
			} else {
				return AUTORELEASE([[LCExplanation alloc] initWithValue: 0.0f representation: @"match prohibited"]);
			}
		} else if ([c isRequired]) {
			return AUTORELEASE([[LCExplanation alloc] initWithValue: 0.0f representation: @"match required"]);
		}
	}
	[sumExpl setValue: sum];
	
	if (coord == 1) // only one clause matched
		sumExpl = [[sumExpl details] objectAtIndex: 0]; // eliminate wrapper
	
	float coordFactor = [similarity coordination: coord max: maxCoord];
	if (coordFactor == 1.0f)  // coord is no-op
		return sumExpl; // elimate wrapper
	else {
		LCExplanation *result = [[LCExplanation alloc] init];
		[result setRepresentation: @"product of:"];
		[result addDetail: sumExpl];
		LCExplanation *e = [[LCExplanation alloc] initWithValue: coordFactor representation: [NSString stringWithFormat: @"coord(%d/%d)", coord, maxCoord]];
		[result addDetail: e];
		DESTROY(e);
		[result setValue: sum * coordFactor];
		return AUTORELEASE(result);
	}
}
@end
