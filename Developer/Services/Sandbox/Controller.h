#include <AppKit/AppKit.h>

@interface Controller : NSObject
{
    id window;
    NSTextStorage* textStorage;

    SCKSourceCollection* project;
    SCKSyntaxHighlighter* highlighter;
    SCKSourceFile* sourceFile;

    bool queuedParsing;
    NSTextStorage* copiedText;

    unsigned version;
    unsigned queuedVersion;
}

- (void) parse;
- (void) llvmParsing;
- (void) afterParse;
- (void) copyText;
- (void) applyAttributesFrom: (NSTextStorage*) a to: (NSTextStorage*) b;
- (NSUInteger) indentationForPosition: (NSUInteger) aPosition;
- (NSUInteger) tabsBeforePosition: (NSUInteger) aPosition;
- (NSString*) stringWithNumberOfTabs: (NSUInteger) tabs;
@end
