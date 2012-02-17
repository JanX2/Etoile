/* All Rights reserved */

#include <AppKit/AppKit.h>
#import <SourceCodeKit/SourceCodeKit.h>
#include "Controller.h"
#import "NoodleLineNumberView.h"
#import "NoodleLineNumberMarker.h"

@implementation Controller

- (void) awakeFromNib
{
	[textView setDelegate: self];
	textStorage = [textView textStorage];

     	NoodleLineNumberView* lineNumberView = [[NoodleLineNumberView alloc] initWithScrollView: scrollView];
	[scrollView setHasHorizontalRuler: NO];
	[scrollView setHasVerticalRuler: YES];
	[scrollView setVerticalRulerView: lineNumberView];
	[scrollView setRulersVisible: YES];

	project = [SCKSourceCollection new];
	sourceFile = [[project sourceFileForPath: @"temp.m"] retain];
	NSString* content = [NSString stringWithContentsOfFile: [sourceFile fileName]];
	NSMutableAttributedString* astr = [[NSMutableAttributedString alloc] initWithString: content];
	[textStorage setAttributedString: astr];
	[textStorage addAttribute: @"NSFontAttributeName"
		value: [NSFont userFixedPitchFontOfSize: [NSFont systemFontSize]]
		range: NSMakeRange(0, [textStorage length])];

	[astr release];

	[textView setSourceFile: sourceFile];
}

- (void) dealloc
{
	[super dealloc];
	[project release];
	[sourceFile release];
}

@end
