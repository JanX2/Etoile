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

- (void) testSequenceWith
{
	id stream = [[PKInputStream alloc] initWithStream: @"testsequence"];
	PKParseMatch * match1 = [[PKParseMatch alloc] initWithInput: stream length: [NSNumber numberWithInt: 2]];
	PKParseMatch * match2 = [[PKParseMatch alloc] initWithInput: stream length: [NSNumber numberWithInt: 2]];

	PKParseMatch * matchFinal = [match1 sequenceWith: match2];

	UKTrue([[matchFinal isSuccess] boolValue]);
	UKObjectsEqual(@"test", [matchFinal matchText]);
	UKIntsEqual(0, [[stream lastPosition] intValue]);
}
@end

