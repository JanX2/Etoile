/*
	Copyright (C) 2013 Mathieu Suen

	Author: Mathieu Suen <mathieusuen@yahoo.fr>
	Date: august 2013
	License: BSD like.
*/

#import "PKParser.h"
#import <UnitKit/UnitKit.h>
#import <LanguageKit/LanguageKit.h>
@interface PKInputStreamTest : NSObject <UKTest>
@end

@implementation PKInputStreamTest
- (void)testInit
{
	PKInputStream * stream = [[PKInputStream alloc] initWithStream: @"Some text"];

	UKIntsEqual(9, [@"Some text" length]);
	UKIntsEqual(0, [[stream position] intValue]);
	UKIntsEqual(9, [stream length]);
	UKIntsEqual(9, [[stream stream] length]);
}
@end
