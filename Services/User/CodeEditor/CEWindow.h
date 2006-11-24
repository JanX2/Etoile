#import <AppKit/AppKit.h>

@class CETextView;

@interface CEWindow: NSWindow
{
  NSMutableArray *textViews;
  NSTabView *tabView;
}

/* Path may be nil */
- (CETextView *) createNewTextViewWithFileAtPath: (NSString *) path;
- (NSArray *) textViews;
- (CETextView *) mainTextView;
- (void) removeTextView: (CETextView *) textView; /* Does not ask unsaved document */

- (void) setTitleWithPath: (NSString *) p;

- (void) previousTab: (id) sender;
- (void) nextTab: (id) sender;

@end

