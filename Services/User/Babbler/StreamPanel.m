#import "StreamPanel.h"

static StreamPanel *sharedInstance;

@implementation StreamPanel
+ (StreamPanel *) streamPanel
{
  if (sharedInstance == nil) {
    sharedInstance = [[StreamPanel alloc] init];
  }
  return sharedInstance;
}

- (id) init
{
  self = [super init];
  [NSBundle loadNibNamed: @"StreamPanel" owner: self];
  return self;
}

- (void) awakeFromNib
{
  NSLog(@"Awake %@", NSStringFromRect([window frame]));
}

- (int) runModal
{
  return [NSApp runModalForWindow: window];
}

- (void) okAction: (id) sender
{
  [window close];
  [NSApp stopModalWithCode: NSOKButton];
}

- (void) cancelAction: (id) sender
{
  [window close];
  [NSApp stopModalWithCode: NSCancelButton];
}

- (NSURL *) URL
{
  return [NSURL URLWithString: [urlField stringValue]];
}

@end
