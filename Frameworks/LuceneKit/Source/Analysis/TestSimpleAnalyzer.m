#include <LuceneKit/Analysis/LCSimpleAnalyzer.h>
#include <LuceneKit/Analysis/LCLowerCaseTokenizer.h>
#include "TestAnalyzer.h"
#include <LuceneKit/GNUstep/GNUstep.h>

@interface TestSimpleAnalyzer: NSObject <UKTest>
@end

@implementation TestSimpleAnalyzer

- (void) testSimpleAnalyzer
{
	NSString *s = @"This is a beautiful day!";
	NSArray *a = [NSArray arrayWithObjects: @"this", @"is", @"a", @"beautiful", @"day", nil];
	LCSimpleAnalyzer *analyzer = [[LCSimpleAnalyzer alloc] init];
	[analyzer compare: s and: a with: analyzer];
}

@end
