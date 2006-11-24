#import <AppKit/AppKit.h>

extern NSString *const CETextViewFileChangedNotification;

@class CELineNumberView;

@interface CETextView: NSTextView
{
  NSString *path;
  NSString *displayName;
  NSFont *font;
  BOOL isEdited;
  BOOL showLineNumber;

  CELineNumberView *lineNumberView;

  NSUserDefaults *defaults;
}

- (void) saveFileAtPath: (NSString *) absolute_path;
- (void) loadFileAtPath: (NSString *) absolute_path;

- (NSString *) path;
- (NSString *) displayName;
- (BOOL) isEdited;
- (void) setShowLineNumber: (BOOL) show;

/* Action */
- (void) showLineNumber: (id) sender;
- (void) save: (id) sender;
- (void) saveAs: (id) sender;
- (void) saveTo: (id) sender;
- (void) showFindPanel: (id) sender;

@end

