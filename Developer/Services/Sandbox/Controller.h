#include <AppKit/AppKit.h>
#include "IDETextView.h"

@interface Controller : NSObject
{
    id window;
    IDETextView* textView;
    NSScrollView* scrollView;

    NSTextStorage* textStorage;

    SCKSourceCollection* project;
    SCKSyntaxHighlighter* highlighter;
    SCKSourceFile* sourceFile;
    SCKSourceFile* parsedSourceFile; // used in a different thread

    bool queuedParsing;
    NSTextStorage* copiedText;
    NSLock* lock;

    unsigned queuedVersion;
}

- (void) setHighlighterColors;
- (void) parse;
- (void) llvmParsing: (NSTextStorage*) storage withVersion: (unsigned) version;
- (BOOL) isValidVersion: (unsigned int) version;
- (void) afterParse;
- (void) copyText;
- (void) applyAttributesFrom: (NSTextStorage*) a to: (NSTextStorage*) b;
- (NSUInteger) indentationForPosition: (NSUInteger) aPosition;
- (NSUInteger) tabsBeforePosition: (NSUInteger) aPosition;
- (NSString*) stringWithNumberOfTabs: (NSUInteger) tabs;
@end
