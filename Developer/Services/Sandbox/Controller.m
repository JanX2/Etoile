/* All Rights reserved */

#include <AppKit/AppKit.h>
#import <SourceCodeKit/SourceCodeKit.h>
#include "Controller.h"

@implementation Controller

- (void) awakeFromNib
{
	textStorage = [[NSTextStorage alloc] init];
	NSLayoutManager* layoutManager;
	layoutManager = [[NSLayoutManager alloc] init];
	[textStorage addLayoutManager: layoutManager];
	[layoutManager release];
	NSRect frame = [[window contentView] frame];
	NSTextContainer* container;
	container = [[NSTextContainer alloc] initWithContainerSize: frame.size];
	[layoutManager addTextContainer: container];
	[container release];

	NSTextView* textView = [[NSTextView alloc] initWithFrame: frame textContainer: container];
	[window setContentView: textView];
	[window makeKeyAndOrderFront: nil];
	[textView setDelegate: self];
	[textView release];

	// sourceFile = [[project sourceFileForPath: @"main.m"] retain];
	project = [SCKSourceCollection new];
	highlighter = [SCKSyntaxHighlighter new];
	//sourceFile = [SCKSourceFile new];
	sourceFile = [[project sourceFileForPath: @"main.m"] retain];

	queuedParsing = false;
	version = 0;
}

- (void) textDidChange: (NSNotification*) notification
{
//	[NSObject cancelPreviousPerformRequestsWithTarger: self selector: @selector(parse) object: nil];
	version++;

	if (!queuedParsing) {
			queuedParsing = true;
			queuedVersion = version;
			[self performSelector: @selector(parse) withObject: nil afterDelay: 0.5];
	}
}

- (void) parse
{
	[self performSelectorOnMainThread: @selector(copyText) withObject: nil waitUntilDone: YES];

	@try{

	[self llvmParsing];

	} @catch(NSException* e) {
//		NSLog(@" exc: %@", e);
		[copiedText release];
		copiedText = nil;
	}

	[self performSelectorOnMainThread: @selector(afterParse) withObject: nil waitUntilDone: YES];
}

- (void) llvmParsing
{
	sourceFile.source = copiedText;
	[sourceFile reparse];
	[sourceFile syntaxHighlightFile];
	[sourceFile collectDiagnostics];
	[highlighter transformString: copiedText];
}

- (void) copyText
{
	[copiedText release];
	copiedText = [[NSMutableAttributedString alloc] initWithString: [[textStorage string] copy]];
}

- (void) applyAttributesFrom: (NSTextStorage*) a to: (NSTextStorage*) b
{
	unsigned index = 0;
	while (index < [a length]) 
	{
		NSRange range;
		NSDictionary* dict = [a attributesAtIndex: index effectiveRange: &range];
		[b setAttributes: dict range: range];
		index += range.length;
	}
}

- (void) afterParse
{
	queuedParsing = false;
	if (queuedVersion == version) {
		[textStorage removeAttribute: NSForegroundColorAttributeName range: NSMakeRange(0, [textStorage length])];
		[textStorage removeAttribute: NSBackgroundColorAttributeName range: NSMakeRange(0, [textStorage length])];
		[self applyAttributesFrom: copiedText to: textStorage];
	} else {
		queuedParsing = true;
		queuedVersion = version;
		[self performSelector: @selector(parse) withObject: nil afterDelay: 0.5];
	}	
}

@end
