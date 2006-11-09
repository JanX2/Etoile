#import <PaneKit/PaneKit.h>

@interface PreferencePane: PKPreferencePane
{
  NSPopUpButton *removeDateButton;
}

- (void) removeDateAction: (id) sender;
@end

