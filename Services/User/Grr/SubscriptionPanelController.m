#import "SubscriptionPanelController.h"
#import "GNUstep.h"

static SubscriptionPanelController *sharedInstance;

@implementation SubscriptionPanelController

+ (SubscriptionPanelController *) subscriptionPanelController
{
  if (sharedInstance == nil) {
    sharedInstance = [[SubscriptionPanelController alloc] init];
  }
  return sharedInstance;

}

- (void) ok: (id) sender
{
  [NSApp stopModalWithCode: NSOKButton];
  [panel close];
}

- (void) cancel: (id) sender
{
  [NSApp stopModalWithCode: NSCancelButton];
  [panel close];
}

- (int) runPanelInModal
{
  if (panel == nil) {
    [NSBundle loadNibNamed: @"AddFeedPanel" owner: self];
  }
  return [NSApp runModalForWindow: panel];
}

- (NSURL *) url
{
  NSString *s = [URLTextField stringValue];
  ASSIGN(url, [NSURL URLWithString: s]);
  return url;
}

- (void) dealloc
{
  DESTROY(url);
  DESTROY(URLTextField);
  [super dealloc];
}

@end
