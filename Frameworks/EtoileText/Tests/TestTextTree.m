#import "TestCommon.h"
#import "ETTextTree.h"
#import "ETTextFragment.h"

@interface TestTextTree : TestCommon
{
	ETTextTree *textTree;
}

@end

@implementation TestTextTree

- (id)init
{
	SUPERINIT;
	[self prepareTextTree];
	return self;
}

- (void)dealloc
{
	DESTROY(textTree);
	[super dealloc];
}

- (void)prepareTextTree
{
	NSArray *textNodes = A([ETTextFragment fragmentWithString: @"A"],
						   [ETTextFragment fragmentWithString: @"B"],
						   [ETTextFragment fragmentWithString: @"C"]);
	ASSIGN(textTree, [ETTextTree textTreeWithChildren: textNodes]);
}

- (void)testStringProperties
{
	UKTrue('A' == [textTree characterAtIndex: 0]);
	UKTrue('B' == [textTree characterAtIndex: 1]);
	UKTrue('C' == [textTree characterAtIndex: 2]);
	UKIntsEqual(3, (int)[textTree length]);
}

- (void)testStringValue
{
	UKStringsEqual(@"ABC", [textTree stringValue]);
}

- (void)testChangeStringValue
{
	[textTree setStringValue: @"XYZ"];

	UKStringsEqual(@"XYZ", [textTree stringValue]);
	UKIntsEqual(1, (int)[textTree count]);
}

- (void)testAppendFragment
{
	ETTextFragment *fragment = [ETTextFragment fragmentWithString: @"DE"];

	[textTree appendTextFragment: fragment];

	UKObjectsSame(textTree, [fragment parent]);
	UKIntsEqual(5, (int)[textTree length]);
	UKStringsEqual(@"ABCDE", [textTree stringValue]);
}

- (void)testRemoveFragment
{
	ETTextFragment *fragment = [[textTree children] objectAtIndex: 1];

	[textTree removeTextFragment: fragment];
	
	UKNil([fragment parent]);
	UKIntsEqual(2, (int)[textTree length]);
	UKStringsEqual(@"AC", [textTree stringValue]);
}

- (void)testChangeFragmentStringValue
{
	[[[textTree children] firstObject] setStringValue: @"XY"];

	UKIntsEqual(4, (int)[textTree length]);
	UKStringsEqual(@"XYBC", [textTree stringValue]);
}

@end
