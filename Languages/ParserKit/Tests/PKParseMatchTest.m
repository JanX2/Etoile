/*
	Copyright (C) 2013 Mathieu Suen

	Author: Mathieu Suen <mathieusuen@yahoo.fr>
	Date: august 2013
	License: BSD like.
*/

#import "PKParser.h"
#import <UnitKit/UnitKit.h>
#import <LanguageKit/LanguageKit.h>
@interface PKParseMatchTest : NSObject <UKTest>
@end

@implementation PKParseMatchTest
- (void) testInit
{
	id stream = [[PKInputStream alloc] initWithStream: @"test"];
	PKParseMatch * match = [[PKParseMatch alloc] initWithInput: stream length: [NSNumber numberWithInt:2]];
	UKTrue([[match isSuccess] boolValue]);
	UKFalse([[match isFailure] boolValue]);
	UKFalse([[match isEmpty] boolValue]);
	UKObjectsEqual(@"te", [match matchText]);
}
@end
