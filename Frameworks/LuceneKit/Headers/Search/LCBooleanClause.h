#ifndef __LUCENE_SEARCH_BOOLEAN_CLAUSE__
#define __LUCENE_SEARCH_BOOLEAN_CLAUSE__

#include <Foundation/Foundation.h>

static NSString *OCCUR_MUST = @"MUST";
static NSString *OCCUR_SHOULD = @"SHOULD";
static NSString *OCCUR_MUST_NOT = @"MUST_NOT";

@interface LCBooleanQuery: NSObject // Serializable
{
  NSString *occur;
}

- (id) initWithQuery: (LCQuery *) q
              require: (BOOL) r
	      prohibited: (BOOL) p;
- (id) initWithQuery: (LCQuery *) q
             occur: (NSString *) o;
- (NSString *) occur;
- (void) setOccur: (NSString *) o;
- (LCQuery *) query;
- (void) setOuery: (LCQuery *) q;
- (BOOL) isProhibited;
- (BOOL) isRequired;
- (void) setFields: (NSString *) o;

@end
#endif /* __LUCENE_SEARCH_BOOLEAN_CLAUSE__ */
