#import "TestCommon.h"
#import <AppKit/AppKit.h>
#import "ETTextFragment.h"
#import "ETTextStorage.h"
#import "ETTextTree.h"

@interface TestTextStorage : TestCommon
{
	ETTextTree *textTree;
	ETTextStorage *textStorage;
	NSTextView *textView;
}

@end

@implementation TestTextStorage

- (id)init
{
	SUPERINIT;
	[self prepareTextTree];
	textStorage = [ETTextStorage new];
	textView = [[NSTextView alloc] initWithFrame: NSMakeRect(0, 0, 500, 500)];
	return self;
}

- (void)dealloc
{
	DESTROY(textTree);
	DESTROY(textStorage);
	DESTROY(textView);
	[super dealloc];
}

- (void)prepareTextTree
{
	NSArray *textNodes = A([ETTextFragment fragmentWithString: @"A"],
						   [ETTextFragment fragmentWithString: @"B"],
						   [ETTextFragment fragmentWithString: @"C"]);
	ASSIGN(textTree, [ETTextTree textTreeWithChildren: textNodes]);
}

- (void)prepareTextStorageWithTextTree: (ETTextTree*)aTextTree
{
	[textStorage setText: aTextTree];
	[[[textView textContainer] layoutManager] replaceTextStorage: textStorage];
}

- (void) testBasicTextStorageReplacement
{
	NSTextStorage *basicTextStorage = [[NSTextStorage new] autorelease];

	[[basicTextStorage mutableString] setString: @"ABC"];
	[[[textView textContainer] layoutManager] replaceTextStorage: basicTextStorage];

	UKStringsEqual(@"ABC", [textView string]);
}

- (void)testTextViewString
{
	[self prepareTextStorageWithTextTree: textTree];

	UKStringsEqual(@"ABC", [textView string]);
}

@end
