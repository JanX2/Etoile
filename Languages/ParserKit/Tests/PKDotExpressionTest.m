
/*
	Copyright (C) 2013 Mathieu Suen

	Author: Mathieu Suen <mathieusuen@yahoo.fr>
	Date: august 2013
	License: BSD like.
*/

#import "PKParser.h"
#import <UnitKit/UnitKit.h>
#import <LanguageKit/LanguageKit.h>
@interface PKDotExpressionTest : NSObject <UKTest>
@end

@implementation PKDotExpressionTest
- (void)testParseInput
{
	PKInputStream *stream  = [[PKInputStream alloc] initWithStream: @"test"];
	PKDotExpression *exp = [PKDotExpression new];
	id result  = [exp parseInput: stream];
	UKObjectKindOf(result, PKParseMatch);
	UKTrue([[result isSuccess] boolValue]);
	UKObjectsEqual([result matchText], @"t");
}
@end

