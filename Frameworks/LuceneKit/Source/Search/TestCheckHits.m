#include "TestCheckHits.h"
#include "LCQuery.h"
#include "LCSearcher.h"
#include "LCHits.h"
#include <UnitKit/UnitKit.h>

@implementation TestCheckHits

+ (void) checkHits: (LCQuery *) query 
		  searcher: (LCSearcher *) searcher results: (NSArray *) results
{
	LCHits *hits = [searcher search: query];
	[TestCheckHits checkDocIds: hits results: results];
}

+ (void) checkDocIds: (LCHits *) hits results: (NSArray *) results
{
	UKIntsEqual([hits count], [results count]);
	int i;
	for (i = 0; i < [results count]; i++)
	{
		UKIntsEqual([hits identifier: i], [[results objectAtIndex: i] intValue]);
	}
}

@end

