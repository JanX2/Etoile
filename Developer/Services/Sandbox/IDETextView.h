#include <AppKit/AppKit.h>
#import <SourceCodeKit/SourceCodeKit.h>

@interface IDETextView : NSTextView
{
	NSPopUpButtonCell* popup;
	NSRange completionRange;
}
@property (retain) SCKSourceFile* sourceFile;
@property unsigned version;

- (void) showCompletionMenuAtPosition: (NSPoint) position
                            withArray: (NSArray*) completions;
- (void) showCompletionMenu: (NSArray*) completions;
- (void) changeText;
@end
