#include <AppKit/AppKit.h>
#import <SourceCodeKit/SourceCodeKit.h>

@interface IDETextView : NSTextView
{
	NSPopUpButtonCell* popup;
	NSRange completionRange;
	NSConditionLock* conditionLock;
	NSLock* lock;

        SCKSyntaxHighlighter* highlighter;
        SCKSourceFile* parsedSourceFile; // used in a different thread
    	bool queuedParsing;
    	NSTextStorage* copiedText;
    	unsigned queuedVersion;
}
@property (nonatomic, retain) SCKSourceFile* sourceFile;
@property (retain) id delegate;
@property (atomic) unsigned version;

- (void) setHighlighterColors;

// autocompletion methods

- (void) showCompletionMenuAtPosition: (NSPoint) position
                            withArray: (NSArray*) completions;
- (void) goNextCompletion;
- (void) complete: (id) sender;
- (void) keyDown: (NSEvent*) theEvent;
- (void) showCompletionMenu: (NSArray*) completions;

// autoindent

- (NSUInteger) indentationForPosition: (NSUInteger) aPosition;
- (NSUInteger) tabsBeforePosition: (NSUInteger) aPosition;
- (NSString*) stringWithNumberOfTabs: (NSUInteger) tabs;

// NSTextView delegate methods

- (BOOL) textView: (NSTextView*) aTextView shouldChangeTextInRange: (NSRange) aRange
                                                replacementString: (NSString*) aString;

// LLVM parsing

- (void) queueParsing;
- (void) queueParsingNow: (BOOL) immediate;
- (void) parseThread;
- (BOOL) llvmParsing: (NSTextStorage*) storage withVersion: (unsigned int) currentVersion;
- (void) applyAttributesFrom: (NSTextStorage*) a to: (NSTextStorage*) b;
- (void) applyParsedContent: (NSDictionary*) content;

@end
