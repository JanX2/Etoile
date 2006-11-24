#import <PaneKit/PaneKit.h>

extern NSString *const CodeEditorShowLineNumberDefaults;

@interface ViewPreferencePane: PKPreferencePane
{
  NSButton *showLineNumberButton;
  BOOL anythingChanged;
  NSUserDefaults *defaults;
}

- (void) showLineNumberAction: (id) sender;

@end

