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

	project = [SCKSourceCollection new];
	highlighter = [SCKSyntaxHighlighter new];
	[self setHighlighterColors];

	//sourceFile = [SCKSourceFile new];
	sourceFile = [[project sourceFileForPath: @"temp.m"] retain];

	queuedParsing = false;
	version = 0;
}

- (void) setHighlighterColors
{
	NSDictionary *comment = D([NSColor blueColor], NSForegroundColorAttributeName);
	NSDictionary *keyword = D([NSColor yellowColor], NSForegroundColorAttributeName);
	NSDictionary *literal = D([NSColor redColor], NSForegroundColorAttributeName);
	NSDictionary *noAttributes = [NSDictionary new];

	highlighter.tokenAttributes = [D(
			comment, SCKTextTokenTypeComment,
			noAttributes, SCKTextTokenTypePunctuation,
			keyword, SCKTextTokenTypeKeyword,
			literal, SCKTextTokenTypeLiteral)
				mutableCopy];

	[noAttributes release];

	highlighter.semanticAttributes = [D(
			D([NSColor blueColor], NSForegroundColorAttributeName), SCKTextTypeDeclRef,
			D([NSColor brownColor], NSForegroundColorAttributeName), SCKTextTypeMessageSend,
			//D([NSColor greenColor], NSForegroundColorAttributeName), SCKTextTypeDeclaration,
			D([NSColor magentaColor], NSForegroundColorAttributeName), SCKTextTypeMacroInstantiation,
			D([NSColor magentaColor], NSForegroundColorAttributeName), SCKTextTypeMacroDefinition,
			D([NSColor orangeColor], NSForegroundColorAttributeName), SCKTextTypePreprocessorDirective,
			D([NSColor purpleColor], NSForegroundColorAttributeName), SCKTextTypeReference)
				mutableCopy];
}

- (NSUInteger) indentationForPosition: (NSUInteger) aPosition
{
	// FIXME: rather less than efficient approach
	NSString* str = [textStorage string];
	NSUInteger index = aPosition;
	if (index > [str length]) {
		return 0;
	}
	int indent = 0;
	index--;
	while (index > 0) {
		unichar car = [str characterAtIndex: index];
		if (car == '{')
			indent++;
		else if (car == '}')
			indent--;
		index--;
	}
	return indent < 0 ? 0 : indent;
}

- (NSUInteger) tabsBeforePosition: (NSUInteger) aPosition
{
	NSUInteger tabs = 0;
	NSString* str = [textStorage string];
	if (!aPosition || aPosition > [str length])
		return 0;
	NSUInteger index = aPosition - 1;
	while (index > 0) {
		unichar car = [str characterAtIndex: index];
		if (car == '\t')
			tabs++;
		else
			break;
		index--;
	}
	return tabs;
}

- (NSString*) stringWithNumberOfTabs: (NSUInteger) tabs
{
	NSMutableString* str = [NSMutableString stringWithString: @""];
	for (int i=0; i<tabs; i++) {
		[str appendString: @"\t"];
	}
	return str;
}

- (BOOL) textView: (NSTextView*) textView shouldChangeTextInRange: (NSRange) aRange replacementString: (NSString*) aString
{
	BOOL allow = true;
        BOOL needParsing = false;

	if ([aString isEqualToString: @"\n"]) {
		NSUInteger indent = [self indentationForPosition: aRange.location];
		if (indent > 0) {
	  	    NSString* str = [self stringWithNumberOfTabs: indent]; 
		    NSAttributedString* astr = [[NSAttributedString alloc] initWithString: [NSString stringWithFormat: @"\n%@", str]];
		    [textStorage replaceCharactersInRange: aRange withAttributedString: astr];
		    [astr release];
        	    allow = NO;
		}
	    	needParsing = YES;
	}

        if ([aString isEqualToString: @"}"]) {
		NSUInteger tabs = [self tabsBeforePosition: aRange.location];	
		NSUInteger indent = [self indentationForPosition: aRange.location];
		if (indent >= 1) {
			indent --;
			if (indent != tabs) {
	  	            NSString* str = [self stringWithNumberOfTabs: indent]; 
			    NSAttributedString* astr = [[NSAttributedString alloc] initWithString: [NSString stringWithFormat: @"%@}", str]];
			    [textStorage replaceCharactersInRange: NSMakeRange(aRange.location - tabs, tabs) withAttributedString: astr];
			    [astr release];
		            allow = NO;
			}
		}
		needParsing = YES;
	} 

        if ([aString isEqualToString: @" "] || ([aString isEqualToString: @"\t"]) || ([aString isEqualToString: @";"]))
                needParsing = YES;

	if (needParsing) {
		// We queue a parsing
		if (!queuedParsing) {
			queuedParsing = true;
			[self performSelector: @selector(parse) withObject: nil afterDelay: 0.5];
		}
        }

	return allow;
}

- (void) textDidChange: (NSNotification*) notification
{
//	[NSObject cancelPreviousPerformRequestsWithTarger: self selector: @selector(parse) object: nil];
	version++;

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
	copiedText = [[NSTextStorage alloc] initWithString: [[textStorage string] copy]];
	queuedVersion = version;
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
	if (copiedText != nil && queuedVersion == version) {
		[textStorage removeAttribute: NSForegroundColorAttributeName range: NSMakeRange(0, [textStorage length])];
		[textStorage removeAttribute: NSBackgroundColorAttributeName range: NSMakeRange(0, [textStorage length])];
		[self applyAttributesFrom: copiedText to: textStorage];

/*
		NSLog(@"current functions:");
		NSDictionary* functions = [project functions];
		for (SCKFunction* function in [functions objectEnumerator]) {
			if ([[[function definition] file] isEqualToString: [sourceFile fileName]]) {
				NSLog(@"function: %@", function);
			}
		}	

		NSLog(@"current classes:");
		NSDictionary* classes = [project classes];
		for (SCKClass* aClass in [classes objectEnumerator]) {
			if ([[[aClass definition] file] isEqualToString: [sourceFile fileName]]) {
				NSLog(@"class def: %@", aClass);
			}
			if ([[[aClass declaration] file] isEqualToString: [sourceFile fileName]]) {
				NSLog(@"class decl: %@", aClass);
			}
		}	
*/
	} else {
		queuedParsing = true;
		[self performSelector: @selector(parse) withObject: nil afterDelay: 0.5];
	}	
}

@end
