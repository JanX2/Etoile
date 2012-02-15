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

@synthesize sourceFile, version;

- (id) initWithFrame: (NSRect) frame textContainer: (NSTextContainer*) container
{
	self = [super initWithFrame: frame textContainer: container];
	popup = nil;
	version = 0;
	return self;
}

- (void) dealloc
{
	[super dealloc];
	[popup release];
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
	[self changeText];
}

- (void) changeText
{
	version++;
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

@end

