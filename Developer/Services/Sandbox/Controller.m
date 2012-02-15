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
	[textView setFont:
		[NSFont userFixedPitchFontOfSize: [NSFont systemFontSize]]];
	textStorage = [textView textStorage];

     	NoodleLineNumberView* lineNumberView = [[NoodleLineNumberView alloc] initWithScrollView: scrollView];
	[scrollView setHasHorizontalRuler: NO];
	[scrollView setHasVerticalRuler: YES];
	[scrollView setVerticalRulerView: lineNumberView];
	[scrollView setRulersVisible: YES];

	project = [SCKSourceCollection new];
	highlighter = [SCKSyntaxHighlighter new];
	[self setHighlighterColors];

	sourceFile = [[project sourceFileForPath: @"temp.m"] retain];
	parsedSourceFile = [[project sourceFileForPath: @"temp.m"] retain];
	NSString* content = [NSString stringWithContentsOfFile: [sourceFile fileName]];
	NSMutableAttributedString* astr = [[NSMutableAttributedString alloc] initWithString: content];
	[textStorage setAttributedString: astr];
	[textStorage addAttribute: @"NSFontAttributeName"
		value: [NSFont userFixedPitchFontOfSize: [NSFont systemFontSize]]
		range: NSMakeRange(0, [textStorage length])];

	[astr release];

	[textView setSourceFile: sourceFile];
//	[self performSelector: @selector(parse) withObject: nil afterDelay: 0];
	[NSThread detachNewThreadSelector: @selector(parse) toTarget: self withObject: nil];

	queuedParsing = false;
	lock = [NSLock new];
}

- (void) dealloc
{
	[super dealloc];
	[lock release];
}

- (void) setHighlighterColors
{
	NSDictionary *comment = D([NSColor blueColor], NSForegroundColorAttributeName);
	NSDictionary *keyword = D([NSColor darkGrayColor], NSForegroundColorAttributeName);
	NSDictionary *literal = D([NSColor grayColor], NSForegroundColorAttributeName);
	NSDictionary *noAttributes = [NSDictionary new];

	highlighter.tokenAttributes = [D(
			comment, SCKTextTokenTypeComment,
			noAttributes, SCKTextTokenTypePunctuation,
			keyword, SCKTextTokenTypeKeyword,
			literal, SCKTextTokenTypeLiteral)
				mutableCopy];

	[noAttributes release];

	highlighter.semanticAttributes = [D(
			D([NSColor redColor], NSForegroundColorAttributeName), SCKTextTypeDeclRef,
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

- (BOOL) textView: (NSTextView*) aTextView shouldChangeTextInRange: (NSRange) aRange
                                                replacementString: (NSString*) aString
{
	[lock lock];
	BOOL allow = true;
        BOOL needParsing = false;

	if ([aString isEqualToString: @"\n"]) {
		NSUInteger indent = [self indentationForPosition: aRange.location];
		if (indent > 0) {
			NSString* str = [self stringWithNumberOfTabs: indent]; 
			NSAttributedString* astr = [[NSAttributedString alloc] initWithString:
				[NSString stringWithFormat: @"\n%@", str]];
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
				NSAttributedString* astr = [[NSAttributedString alloc] initWithString:
								   [NSString stringWithFormat: @"%@}", str]];
			 	[textStorage replaceCharactersInRange:
			 		NSMakeRange(aRange.location - tabs, tabs) withAttributedString: astr];
				[astr release];
		        	allow = NO;
			}
		}
		needParsing = YES;
	} 

        if ([aString isEqualToString: @" "] || [aString isEqualToString: @"\t"]
		|| [aString isEqualToString: @";"]
		|| [aString isEqualToString: @"{"]
		|| [aString isEqualToString: @"["]
		|| [aString isEqualToString: @"]"]
		|| [aString isEqualToString: @">"])
                needParsing = YES;

	[textView changeText];
	if (!allow)
		[lock unlock];
	return allow;
}

- (void) textDidChange: (NSNotification*) notification
{
	[lock unlock];
}

- (void) parse
{
	int preversion = -1;
	while (true) {
		NSAutoreleasePool* pool = [NSAutoreleasePool new];

		BOOL doParsing = NO;

		[lock lock];
		int currentVersion = [textView version];
		if (preversion != currentVersion)
			doParsing = YES;
		[lock unlock];

		if (doParsing) {
			[self performSelectorOnMainThread: @selector(copyText)
				               withObject: nil waitUntilDone: YES];

			if ([self isValidVersion: currentVersion]) {
				@try{
					[self llvmParsing: copiedText
                                              withVersion: currentVersion];
				} @catch(NSException* e) {
					[copiedText release];
					copiedText = nil;
				}
			}

			if (copiedText && [self isValidVersion: currentVersion]) {
				BOOL applyNewText = NO;
				[lock lock];
				if (currentVersion == [textView version]) {
					applyNewText = YES;
					preversion = currentVersion;
				}
				[lock unlock];

				if (applyNewText) {
					[self performSelectorOnMainThread: @selector(afterParse)
                                                               withObject: nil waitUntilDone: YES];
				}
			}
		} else {
			usleep(1000);
		}
		
		[pool release];
	}
}

- (BOOL) isValidVersion: (unsigned int) aVersion
{
	BOOL ret = YES;
	[lock lock];
	if (aVersion != [textView version])
		ret = NO;
	[lock unlock];
	return ret;
}

- (void) llvmParsing: (NSTextStorage*) storage withVersion: (unsigned int) currentVersion
{
	parsedSourceFile.source = storage;
	[parsedSourceFile reparse];

	if ([self isValidVersion: currentVersion])
		[parsedSourceFile syntaxHighlightFile];
	else
		return;

	if ([self isValidVersion: currentVersion])
		[parsedSourceFile collectDiagnostics];
	else
		return;

	if ([self isValidVersion: currentVersion])
		[highlighter transformString: storage];
	else
		return;

	NSDictionary* dictionary = [NSDictionary dictionaryWithObject: [NSFont userFixedPitchFontOfSize: [NSFont systemFontSize]]
					forKey: @"NSFontAttributeName"];

	[storage addAttribute: @"NSFontAttributeName"
		value: [NSFont userFixedPitchFontOfSize: [NSFont systemFontSize]]
		range: NSMakeRange(0, [storage length])];
}

- (void) copyText
{
	[copiedText release];
	copiedText = [[NSTextStorage alloc] initWithString: [[textStorage string] copy]];
	queuedVersion = [textView version];
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
	//queuedParsing = false;
	if (copiedText != nil && queuedVersion == [textView version]) {
		[textStorage removeAttribute: NSForegroundColorAttributeName range:
			 NSMakeRange(0, [textStorage length])];
		[textStorage removeAttribute: NSBackgroundColorAttributeName range:
			 NSMakeRange(0, [textStorage length])];
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
		//queuedParsing = true;
		// [self performSelector: @selector(parse) withObject: nil afterDelay: 0.5];
//		[NSThread detachNewThreadSelector: @selector(parse) toTarget: self withObject: nil];
	}	
}

@end
