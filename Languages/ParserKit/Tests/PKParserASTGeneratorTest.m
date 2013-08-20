/*
	Copyright (C) 2013 Mathieu Suen

	Author: Mathieu Suen <mathieusuen@yahoo.fr>
	Date: august 2013
	License: BSD like.
*/

#import "PKParser.h"
#import <UnitKit/UnitKit.h>
#import <LanguageKit/LanguageKit.h>

@interface PKParserASTGeneratorTest : NSObject <UKTest>
@end

@implementation PKParserASTGeneratorTest

- (void) testGenTemp
{
	id gen = [PKParserASTGenerator new];
	id temp = [gen genTemp];
	id tempOther = [gen genTemp];
	UKObjectKindOf(temp, LKDeclRef);
	UKObjectsEqual(@"temp0", [temp symbol]);
	UKObjectsNotEqual([tempOther symbol], [temp symbol]);
}
@end
