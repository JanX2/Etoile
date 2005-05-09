#ifndef __LUCENE_SEARCH_BOOLEAN_CLAUSE__
#define __LUCENE_SEARCH_BOOLEAN_CLAUSE__

#include <Foundation/Foundation.h>

typedef enum _OCCUR_TYPE
{
	LCOccur_MUST = 1,
	LCOccur_SHOULD,
	LCOccur_MUST_NOT
} LCOccurType;
/*
 static NSString *OCCUR_MUST = @"MUST";
 static NSString *OCCUR_SHOULD = @"SHOULD";
 static NSString *OCCUR_MUST_NOT = @"MUST_NOT";
 */

@class LCQuery;

@interface LCBooleanClause: NSObject // Serializable
{
	//  NSString *occur;
	LCOccurType occur;
	LCQuery *query; // remove for lucene 2.0
	BOOL required;
	BOOL prohibited;
}

- (id) initWithQuery: (LCQuery *) q
			required: (BOOL) r
	      prohibited: (BOOL) p;
- (id) initWithQuery: (LCQuery *) q
			   occur: (LCOccurType) o;
- (LCOccurType) occur;
- (void) setOccur: (LCOccurType) o;
- (NSString *) occurString;
- (LCQuery *) query;
- (void) setQuery: (LCQuery *) q;
- (BOOL) isProhibited;
- (BOOL) isRequired;
- (void) setFields: (LCOccurType) o;

@end
#endif /* __LUCENE_SEARCH_BOOLEAN_CLAUSE__ */
