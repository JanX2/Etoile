#import <PaneKit/PaneKit.h>

@interface PreferencePane: PKPreferencePane
{
  NSTextField *intervalField;
  NSSlider *intervalSlider;

  NSPopUpButton *removeDateButton;
  NSTextField *webBrowserField;

  NSUserDefaults *defaults;
}

- (void) intervalAction: (id) sender;
- (void) removeDateAction: (id) sender;

- (void) webBrowserAction: (id) sender;
- (void) testWebBrowserAction: (id) sender;
@end

