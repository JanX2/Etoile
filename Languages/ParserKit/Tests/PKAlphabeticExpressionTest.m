/*
	Copyright (C) 2013 Mathieu Suen

	Author: Mathieu Suen <mathieusuen@yahoo.fr>
	Date: august 2013
	License: BSD like.
*/

#import "PKParser.h"
#import <UnitKit/UnitKit.h>
#import <LanguageKit/LanguageKit.h>
@interface PKAlphabeticExpressionTest : NSObject <UKTest>
@end

@implementation PKAlphabeticExpressionTest
- (void)testParseAlphaInput
{
	PKInputStream *stream  = [[PKInputStream alloc] initWithStream: @"test"];
	PKAlphabeticExpression *exp = [PKAlphabeticExpression new];
	id result  = [exp parseInput: stream];
	UKObjectKindOf(result, PKParseMatch);
	UKTrue([[result isSuccess] boolValue]);
	UKObjectsEqual([result matchText], @"t");
}

- (void)testParseNonAlphaInput
{
	PKInputStream *stream = [[PKInputStream alloc] initWithStream: @"1test"];
	PKAlphabeticExpression *exp = [PKAlphabeticExpression new];
	id result = [exp parseInput: stream];
	UKObjectKindOf(result, PKParseFail);
	UKFalse([[result isSuccess] boolValue]);
}
@end
