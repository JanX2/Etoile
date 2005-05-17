#include <Foundation/Foundation.h>

@class LCQuery;
@class LCSearcher;
@class LCHits;

@interface TestCheckHits: NSObject
+ (void) checkHits: (LCQuery *) query
		  searcher: (LCSearcher *) searcher results: (NSArray *) results;
+ (void) checkDocIds: (LCHits *) hits results: (NSArray *) results;

@end
