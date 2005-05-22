#ifndef __LUCENE_SEARCH_FUZZY_TERM_ENUM__
#define __LUCENE_SEARCH_FUZZY_TERM_ENUM__

static int TYPICAL_LONGEST_WORD_IN_INDEX = 19;

int min(int a, int b, int c);

#include "LCFilteredTermEnum.h"

@class LCTerm;
@class LCIndexReader;

@interface LCFuzzyTermEnumerator: LCFilteredTermEnumerator
{
	NSArray *d;
	float similarity;
	BOOL endEnum;
	LCTerm *searchTerm;
	NSString *field;
	NSString *text;
	NSString *prefix;
	
	float minimumSimilarity;
	float scale_factor;
	NSArray *maxDistances;
}

- (id) initWithReader: (LCIndexReader *) reader term: (LCTerm *) term;
- (id) initWithReader: (LCIndexReader *) reader term: (LCTerm *) term 
		   similarity: (LCSimilarity *) similarity;
- (id) initWithReader: (LCIndexReader *) reader term: (LCTerm *) term 
		   similarity: (LCSimilarity *) similarity prefixLength: (int) prefixLength;
- (BOOL) termCompare: (LCTerm *) term;
- (float) difference;
- (BOOL) endEnumerator;
- (NSArray *) initDistanceArray;
- (float) similarity: (NSString *) target;
- (void) growDistanceArray: (int) m;
- (int) maxDistance: (int) m;
- (void) initializeMaxDistances;
- (int) calculateMaxDistance: (int) m;
- (void) close;
@end

#endif /* __LUCENE_SEARCH_FUZZY_TERM_ENUM__ */
