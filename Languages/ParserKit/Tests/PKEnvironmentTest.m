/*
	Copyright (C) 2013 Mathieu Suen

	Author: Mathieu Suen <mathieusuen@yahoo.fr>
	Date: august 2013
	License: BSD like.
*/

#import "PKParser.h"
#import <UnitKit/UnitKit.h>
#import <LanguageKit/LanguageKit.h>
@interface PKEnvironmentTest : NSObject <UKTest>
@end

@implementation PKEnvironmentTest
- (void)testNew
{
	PKEnvironmentStack * env  = [PKEnvironmentStack new];

}
@end

