#import <PaneKit/PaneKit.h>

@interface PreferencePane: PKPreferencePane
{
  NSTextField *intervalField;
  NSSlider *intervalSlider;
  NSButton *fetchAtStartupButton;

  NSPopUpButton *removeDateButton;
  NSTextField *webBrowserField;

  NSUserDefaults *defaults;
  BOOL anythingChanged;
}

- (void) fetchAtStartupAction: (id) sender;
- (void) intervalAction: (id) sender;
- (void) removeDateAction: (id) sender;

- (void) webBrowserAction: (id) sender;
- (void) testWebBrowserAction: (id) sender;
@end

