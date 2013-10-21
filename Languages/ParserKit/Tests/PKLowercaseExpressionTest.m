/*
	Copyright (C) 2013 Mathieu Suen

	Author: Mathieu Suen <mathieusuen@yahoo.fr>
	Date: august 2013
	License: BSD like.
*/

#import "PKParser.h"
#import <UnitKit/UnitKit.h>
#import <LanguageKit/LanguageKit.h>
@interface PKLowercaseExpressionTest : NSObject <UKTest>
@end

@implementation PKLowercaseExpressionTest
- (void)testParseUpperInput
{
	PKInputStream *stream  = [[PKInputStream alloc] initWithStream: @"Test"];
	PKLowercaseExpression *exp = [PKLowercaseExpression new];
	id result  = [exp parseInput: stream];
	UKObjectKindOf(result, PKParseFail);
	UKFalse([[result isSuccess] boolValue]);
}

- (void)testParseLowerInput
{
	PKInputStream *stream = [[PKInputStream alloc] initWithStream: @"test"];
	PKLowercaseExpression *exp = [PKLowercaseExpression new];
	id result = [exp parseInput: stream];
	UKObjectKindOf(result, PKParseMatch);
	UKTrue([[result isSuccess] boolValue]);
	UKObjectsEqual([result matchText], @"t");
}

- (void)testParseOtherInput
{
	PKInputStream *stream = [[PKInputStream alloc] initWithStream: @"0"];
	PKLowercaseExpression *exp = [PKLowercaseExpression new];
	id result = [exp parseInput: stream];
	UKObjectKindOf(result, PKParseFail);
	UKFalse([[result isSuccess] boolValue]);
}
@end
