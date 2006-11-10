#import <PaneKit/PaneKit.h>

@interface PreferencePane: PKPreferencePane
{
  NSPopUpButton *removeDateButton;
  NSTextField *webBrowserField;
  NSUserDefaults *defaults;
}

- (void) removeDateAction: (id) sender;

- (void) webBrowserAction: (id) sender;
- (void) testWebBrowserAction: (id) sender;
@end

