#include "IDETextView.h"

@interface CompletionElement : NSObject
@property BOOL placeHolder;
@property (retain) NSString* text;
@end

@implementation CompletionElement
@synthesize placeHolder, text;
@end

@class PlaceholderAttachment;

@interface PlaceholderAttachmentCell : NSTextAttachmentCell
@end

@implementation PlaceholderAttachmentCell

- (NSPoint) cellBaselineOffset
{
	return NSMakePoint(0, 4);
}

- (NSSize) cellSize
{
	PlaceholderAttachment* attachment = (PlaceholderAttachment*) [self attachment];
	NSDictionary* attributes = [NSDictionary dictionaryWithObject: [NSFont userFixedPitchFontOfSize: [NSFont systemFontSize]]
					forKey: NSFontAttributeName];
	NSSize textSize = [[attachment text] sizeWithAttributes: attributes];
	return NSMakeSize(textSize.width + 16, textSize.height + 4);
}

- (void) drawWithFrame: (NSRect) aFrame inView: (NSView*) aView
{
	NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect: aFrame xRadius: 4 yRadius: 4];

	[[NSColor colorWithCalibratedRed: 0.78 green: 0.87 blue: 1.0 alpha: 1.0] set];
	[path fill];

	[[NSColor blackColor] set];
	[path setLineWidth: 1];
	[path stroke];

	PlaceholderAttachment* attachment = (PlaceholderAttachment*) [self attachment];
	NSDictionary* attributes = [NSDictionary dictionaryWithObject: [NSFont userFixedPitchFontOfSize: [NSFont systemFontSize]]
					forKey: NSFontAttributeName];
	
	NSRect frame = NSMakeRect(aFrame.origin.x + 8, aFrame.origin.y + 2, aFrame.size.width, aFrame.size.height);
	[[attachment text] drawInRect: frame withAttributes: attributes];
}

@end

@interface PlaceholderAttachment : NSTextAttachment
@property (retain) NSString* text;
+ (id) attachmentWithString: (NSString*) text;
- (id) initWithString: (NSString*) aText;
@end

@implementation PlaceholderAttachment
static PlaceholderAttachmentCell* gDrawingCell = 0;
@synthesize text;

+ (id) attachmentWithString: (NSString*) text
{
	if (!gDrawingCell) {
		gDrawingCell = [PlaceholderAttachmentCell new];
	}
	PlaceholderAttachment* instance = [[PlaceholderAttachment alloc]
		initWithString: text];
	[instance setAttachmentCell: gDrawingCell];
	return [instance autorelease];
}

- (id) initWithString: (NSString*) aText
{
	self = [super init];
	[self setText: aText];
	return self;
}

@end

@implementation IDETextView

@synthesize sourceFile, version, delegate;

#define NO_TEXT 0
#define NEW_TEXT 1

- (void) awakeFromNib
{
	popup = nil;
	queuedVersion = -1;
	version = 0;
	conditionLock = [[NSConditionLock alloc] initWithCondition: NO_TEXT];
	highlighter = [SCKSyntaxHighlighter new];
	[self setHighlighterColors];
	[self setFont:
		[NSFont userFixedPitchFontOfSize: [NSFont systemFontSize]]];

	SCKSourceCollection* tmpProject = [SCKSourceCollection new];
	parsedSourceFile = [[tmpProject sourceFileForPath: @"/tmp/temp.m"] retain];
	[tmpProject release];
	queuedParsing = false;
	[super setDelegate: self];
	[NSThread detachNewThreadSelector: @selector(parseThread) toTarget: self withObject: nil];
}

- (void) dealloc
{
	[super dealloc];
	[popup release];
	[conditionLock release];
	[highlighter release];
	[parsedSourceFile release];
}

- (void) setSourceFile: (SCKSourceFile*) aSourceFile
{
	[aSourceFile retain];
	[sourceFile release];
	sourceFile = aSourceFile;
	[self queueParsingNow: YES];
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

- (void) showCompletionMenuAtPosition: (NSPoint) position
		            withArray: (NSArray*) completions
{
	NSLog(@"showCompletion menu");
	NSMenu* menu = [[[NSMenu alloc] init] autorelease];

	//FIXME -- shouldn't be needed
        //         will probably implement this in a different way though
        //         (scrollable list) rather than using a menu
	[menu addItemWithTitle: @"" action: @selector(complete:) keyEquivalent: @""];

	for (NSString* c in completions) {
		[[menu addItemWithTitle: c action: @selector(complete:) keyEquivalent: @""]
			 setTarget: self];
	} 

	float menuHeight = [menu menuBarHeight];
	NSRect frame = NSMakeRect(position.x + 8, position.y - menuHeight, 250, menuHeight);
	popup = [[NSPopUpButtonCell alloc] init];
	[popup setPullsDown: YES];
	[popup setMenu: menu];
	[popup attachPopUpWithFrame: frame inView: self];
	[popup selectItemAtIndex: 1];
}

- (void) goNextCompletion
{
	NSString* content = [[self textStorage] string];

	NSRange aRange = [self rangeForUserTextChange];
	if (aRange.location != NSNotFound) {
		unsigned int length = [content length];
		NSRange range;
		// todo: cleanup	
		for (unsigned int i = aRange.location + 1; i < length; i++) {
			NSDictionary* attributes = [[self textStorage] attributesAtIndex: i
				effectiveRange: &range];
			if ([attributes objectForKey: NSAttachmentAttributeName]) {
				[self setSelectedRange: range];
				return;	
			}
			unsigned int newPos = range.location + range.length - 1;
			if (i < newPos)
				i = newPos;
		}
		for (unsigned int i = 0; i < length; i++) {
			NSDictionary* attributes = [[self textStorage] attributesAtIndex: i
				effectiveRange: &range];
			if ([attributes objectForKey: NSAttachmentAttributeName]) {
				[self setSelectedRange: range];
				return;	
			}
			unsigned int newPos = range.location + range.length - 1;
			if (i < newPos)
				i = newPos;
		}
	}
}

- (void) complete: (id) sender
{
	// check if we have placeholders
	// parse the string and get a collection of CompletionElement.

	NSString* completion = [sender title];

	NSMutableArray* completionsElements = [NSMutableArray new];
	NSMutableString* currentString = [NSMutableString new];
	BOOL begin = NO;
	BOOL placeHolder = NO;
	for (unsigned int i = 0; i < [completion length]; i++) {
		unichar c = [completion characterAtIndex: i];

		if (c == '<') {
			begin = YES;

			CompletionElement* e = [CompletionElement new];
			e.placeHolder = NO;
			e.text = [currentString stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];	
			[completionsElements addObject: e];
			[e release];
			[currentString release];
			currentString = [NSMutableString new];

			continue;
		}

		if (c == '#' && begin) {
			placeHolder = YES;
			continue;
		}

		if (c == '#' && placeHolder) {
			continue;
		}

		if (c == '>' && placeHolder) {
			begin = NO;
			placeHolder = NO;

			CompletionElement* e = [CompletionElement new];
			e.placeHolder = YES;
			e.text = [currentString stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];	
			[completionsElements addObject: e];
			[e release];
			[currentString release];
			currentString = [NSMutableString new];
	
			continue;
		}
		
		[currentString appendFormat: @"%c", c];
	}

	{
		CompletionElement* e = [CompletionElement new];
		e.placeHolder = NO;
		e.text = [currentString stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];	
		[completionsElements addObject: e];
		[e release];
		[currentString release];
		currentString = [NSMutableString new];
	}

	// now let's build the attributed string
	NSMutableAttributedString* astr = [NSMutableAttributedString new];

	BOOL first = YES;
	BOOL firstPlaceHolder = YES;
	NSRange selectionRange = NSMakeRange(NSNotFound, 0);
	for (CompletionElement* element in completionsElements) {
		if (!first) {
			NSAttributedString* as = [[[NSAttributedString alloc] initWithString: @" "] autorelease];
			[astr appendAttributedString: as];
		}
		if ([element placeHolder]) {
			NSTextAttachment* attachment = [PlaceholderAttachment attachmentWithString: [element text]];
			NSAttributedString* str = [NSAttributedString attributedStringWithAttachment: attachment];
			if (firstPlaceHolder) {
				firstPlaceHolder = NO;
				selectionRange = NSMakeRange(completionRange.location + [astr length], 1);
			}
			[astr appendAttributedString: str];
		} else {
			NSAttributedString* as = [[[NSAttributedString alloc] initWithString: [element text]] autorelease];
			[astr appendAttributedString: as];
		}
		if (first)
			first = NO;
	}

	[[self textStorage] replaceCharactersInRange: completionRange withAttributedString: astr];
	if (selectionRange.location != NSNotFound) {
		[self setSelectedRange: selectionRange];
	}
	[astr release];

	[self setVersion: [self version] + 1];
}

- (void) keyDown: (NSEvent*) theEvent
{
	NSString* characters = [theEvent characters];
	unichar character = 0;
	if ([characters length] > 0)
		character = [characters characterAtIndex: 0];

	if ([theEvent modifierFlags] & NSControlKeyMask) {
		NSString* characters = [theEvent charactersIgnoringModifiers];
		unichar character = 0;
		if ([characters length] > 0)
			character = [characters characterAtIndex: 0];

		switch (character)
		{
			case '/': [self goNextCompletion];
				break;
		}
	}

	if (popup) {
		if ([[popup menu] performKeyEquivalent: theEvent]) {
			[popup dismissPopUp];
			[popup release];
			popup = nil;
			return;
		}
		int selectedIndex = [popup indexOfSelectedItem];
		switch (character)
		{
			case NSNewlineCharacter:
			case NSEnterCharacter:
			case NSCarriageReturnCharacter:
			{
				[[popup menu] performActionForItemAtIndex: selectedIndex];
				[popup dismissPopUp];
				[popup release];
				popup = nil;
				return;
			}
			case '\e':
			{
				[popup dismissPopUp];
				[popup release];
				popup = nil;
				return;
			}
			case NSUpArrowFunctionKey:
			{
				int index = selectedIndex - 1;
				if (index < 1) // cycle
					index = [popup numberOfItems] - 1;
				[popup selectItemAtIndex: index];
				return;
			}
			case NSDownArrowFunctionKey:
			{
				int index = selectedIndex + 1;
				if (index >= [popup numberOfItems])
					index = 1;
				[popup selectItemAtIndex: index];
				return;
			}
		}
	}

	// handle completion
	if (character == '\e') {
		NSString* str = [[self textStorage] string];
		NSRange aRange = [self rangeForUserTextChange];
		if ((aRange.location != NSNotFound) 
                    && [str characterAtIndex: aRange.location - 1] != ' ') {
			// Let's use the current content
			sourceFile.source = [self textStorage];
			[sourceFile reparse];

			BOOL punctuation = NO;
			NSUInteger punctuationIndex = 0;
			NSUInteger index = aRange.location - 1;
			while(index > 0) {
				unichar car = [str characterAtIndex: index];
				if (car == ' ' || car == '\t' || car == '\n') {
					index++;
					break;
				}
				if (punctuation == NO && (car == '.' || car == '>' || car == ':')) {
					punctuation = YES;
					punctuationIndex = index + 1;
				}
				index--;
			}

			int completionPos = index;
			if (punctuation) {
				completionPos = punctuationIndex;
			}

			SCKCodeCompletionResult* completion = [sourceFile completeAtLocation: completionPos];
			NSArray* completions = [completion completions];		

			NSString* toComplete = [str substringWithRange:
				 NSMakeRange(completionPos, aRange.location - completionPos)];
			NSLog(@"toComplete: <%@>", toComplete);

			NSMutableArray* array = [[NSMutableArray new] autorelease];
			if ([completions count] < 3000) {
				NSLog(@"found %d results", [completions count]);
				for (id c in completions)
					NSLog(@"found %@", c);
			}
			for (id c in completions) {
				if ([toComplete length] == 0 || [[c string] hasPrefix: toComplete]) {
					[array addObject: [c string]];
				}
			}
			if ([array count]) {
				completionRange = NSMakeRange(completionPos, aRange.location - completionPos);
				[self performSelector: @selector(showCompletionMenu:)
				     withObject: array];
				return;
			} 
			
		}
	}
	[super keyDown: theEvent];
}

- (void) showCompletionMenu: (NSArray*) completions
{
	for (NSString* c in completions)
		NSLog(@"found many completion: <%@>", c);

	NSUInteger nbRects = 0;
	NSRectArray rects = [[self layoutManager]
		 rectArrayForCharacterRange: NSMakeRange(completionRange.location + completionRange.length -1, 1)
	       withinSelectedCharacterRange: NSMakeRange(0, 0)
			    inTextContainer: [self textContainer]
				  rectCount: &nbRects];
	if (nbRects < 1)
		return;

	NSPoint cursorPosition = rects[0].origin;
	[self showCompletionMenuAtPosition: cursorPosition
				 withArray: completions];
}

- (NSUInteger) indentationForPosition: (NSUInteger) aPosition
{
	// FIXME: rather less than efficient approach
	NSString* str = [[self textStorage] string];
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
	NSString* str = [[self textStorage] string];
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
	BOOL allow = true;
        BOOL needParsing = false;

	if ([aString isEqualToString: @"\n"]) {
		NSUInteger indent = [self indentationForPosition: aRange.location];
		if (indent > 0) {
			NSString* str = [self stringWithNumberOfTabs: indent]; 
			NSAttributedString* astr = [[NSAttributedString alloc] initWithString:
				[NSString stringWithFormat: @"\n%@", str]];
			[[self textStorage] replaceCharactersInRange: aRange withAttributedString: astr];
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
			 	[[self textStorage] replaceCharactersInRange:
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

	if (delegate && delegate != self
		 && [delegate respondsToSelector:
			 @selector(textView:shouldChangeTextInRange:replacementString:)]) {
		allow = [delegate textView: aTextView
			  shouldChangeTextInRange: aRange
			        replacementString: aString];
	}

	if (allow)
		[self setVersion: [self version] + 1];

	[self queueParsingNow: needParsing];

	return allow;
}

- (void) queueParsing
{
	[conditionLock lock];
	[copiedText release];
	copiedText = [[NSTextStorage alloc] initWithString: [[self textStorage] string]];
	queuedVersion = version;
	// signal the parsing thread that we have new content to parse...
	[conditionLock unlockWithCondition: NEW_TEXT];
}

- (void) queueParsingNow: (BOOL) immediate
{
	if (queuedVersion == version)
		return;

	if (immediate) {
		[self queueParsing];
	} else {
		// let's queue a parsing in the future
		[NSObject cancelPreviousPerformRequestsWithTarget: self
					  	         selector: @selector(queueParsing)
						           object: nil];
		[self performSelector: @selector(queueParsing)
			   withObject: nil
			   afterDelay: 0.2];
	}
}

// This method runs in its own thread
- (void) parseThread
{
	int preversion = -1;
	while (true) {
		NSAutoreleasePool* pool = [NSAutoreleasePool new];

		// New content, let's grab it!
		[conditionLock lockWhenCondition: NEW_TEXT];
		NSTextStorage* text = copiedText;
		int textVersion = queuedVersion;
		[text retain];
		[conditionLock unlockWithCondition: NO_TEXT];

		@try{
			// we parse...
			BOOL doneParsing = [self llvmParsing: text
			      withVersion: textVersion];
			if (!doneParsing) {
				[text release];
				text = nil;
			}
		} @catch(NSException* e) {
			[text release];
			text = nil;
		}

		if (text) {
			// send back the parsed text to the UI
			[self performSelectorOnMainThread: @selector(applyParsedContent:)
					       withObject: D(text, @"text",
						 [NSNumber numberWithInt: textVersion], @"version")
					    waitUntilDone: YES];
		}
		[text release];
		
		[pool release];
	}
}

- (BOOL) llvmParsing: (NSTextStorage*) storage withVersion: (unsigned int) currentVersion
{
	[parsedSourceFile setSource: storage];
	[parsedSourceFile reparse];

	if ([self version] != currentVersion)
		return NO;

	[parsedSourceFile syntaxHighlightFile];
	if ([self version] != currentVersion)
		return NO;

	[parsedSourceFile collectDiagnostics];
	if ([self version] != currentVersion)
		return NO;

	[highlighter transformString: storage];
	if ([self version] != currentVersion)
		return NO;

	NSDictionary* dictionary = [NSDictionary dictionaryWithObject:
		[NSFont userFixedPitchFontOfSize: [NSFont systemFontSize]]
	  	forKey: @"NSFontAttributeName"];

	[storage addAttribute: @"NSFontAttributeName"
		value: [NSFont userFixedPitchFontOfSize: [NSFont systemFontSize]]
		range: NSMakeRange(0, [storage length])];

	if ([self version] != currentVersion)
		return NO;

	return YES;
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

// Running on the UI thread
- (void) applyParsedContent: (NSDictionary*) content
{
	BOOL applyParse = NO;
	NSTextStorage* text = [content objectForKey: @"text"];
	int textVersion = [[content objectForKey: @"version"] intValue];

	if (text != nil && textVersion == version)
		applyParse = YES;

	if (applyParse) {
		[[self textStorage] removeAttribute: NSForegroundColorAttributeName range:
			 NSMakeRange(0, [[self textStorage] length])];
		[[self textStorage] removeAttribute: NSBackgroundColorAttributeName range:
			 NSMakeRange(0, [[self textStorage] length])];
		[self applyAttributesFrom: text to: [self textStorage]];
	} else {
		// queue a parsing in the future
		[self queueParsingNow: NO];
	}

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
}

@end

