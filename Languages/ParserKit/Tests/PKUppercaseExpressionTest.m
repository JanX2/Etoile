
/*
	Copyright (C) 2013 Mathieu Suen

	Author: Mathieu Suen <mathieusuen@yahoo.fr>
	Date: august 2013
	License: BSD like.
*/

#import "PKParser.h"
#import <UnitKit/UnitKit.h>
#import <LanguageKit/LanguageKit.h>
@interface PKUppercaseExpressionTest : NSObject <UKTest>
@end

@implementation PKUppercaseExpressionTest
- (void)testParseUpperInput
{
	PKInputStream *stream  = [[PKInputStream alloc] initWithStream: @"Test"];
	PKUppercaseExpression *exp = [PKUppercaseExpression new];
	id result  = [exp parseInput: stream];
	UKObjectKindOf(result, PKParseMatch);
	UKTrue([[result isSuccess] boolValue]);
	UKObjectsEqual([result matchText], @"T");
}

- (void)testParseLowerInput
{
	PKInputStream *stream = [[PKInputStream alloc] initWithStream: @"test"];
	PKUppercaseExpression *exp = [PKUppercaseExpression new];
	id result = [exp parseInput: stream];
	UKObjectKindOf(result, PKParseFail);
	UKFalse([[result isSuccess] boolValue]);
}

- (void)testParseOtherInput
{
	PKInputStream *stream = [[PKInputStream alloc] initWithStream: @"0"];
	PKUppercaseExpression *exp = [PKUppercaseExpression new];
	id result = [exp parseInput: stream];
	UKObjectKindOf(result, PKParseFail);
	UKFalse([[result isSuccess] boolValue]);
}
@end
