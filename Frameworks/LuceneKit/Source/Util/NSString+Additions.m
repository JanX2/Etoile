#include <LuceneKit/Util/NSString+Additions.h>

@implementation NSString (LuceneKit_Util)
- (int) positionOfDifference: (NSString *) other
{
	int len1 = [self length];
	int len2 = [other length];
	int len = len1 < len2 ? len1 : len2;
	int i;
	for (i = 0; i < len; i++) 
    {
		if ([self characterAtIndex: i] != [other characterAtIndex: i ])
        {
			return i;
        }
    }
	return len;
}
@end

#ifdef HAVE_UKTEST

#include <UnitKit/UnitKit.h>

@interface NSStringAdditions: NSObject <UKTest>
@end

@implementation NSStringAdditions
- (void) testDifference
{
	NSString *test1 = @"test";
	NSString *test2 = @"testing";
	
	int result = [test1 positionOfDifference: test2];
	UKTrue(result == 4);
	
	test2 = @"foo";
	result = [test1 positionOfDifference: test2];
	UKTrue(result == 0);
	
	test2 = @"test";
	result = [test1 positionOfDifference: test2];
	UKTrue(result == 4);
}
@end

#endif /* HAVE_UKTEST */

