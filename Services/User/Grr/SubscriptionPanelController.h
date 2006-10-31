#import <AppKit/AppKit.h>

@interface SubscriptionPanelController: NSObject
{
  NSPanel *panel;
  NSTextField *URLTextField;
  NSURL *url;
}

+ (SubscriptionPanelController *) subscriptionPanelController;
- (int) runPanelInModal;
- (NSURL *) url;
@end
