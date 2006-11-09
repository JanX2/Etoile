#import "PreferencePane.h"

@implementation PreferencePane

- (id) init
{
  self = [super init];
 
  _mainView = [[NSTextField alloc] initWithFrame: NSMakeRect(0, 0, 300, 200)];
  [(NSTextField *)_mainView setStringValue: @"This is a simple preference panel"];

  PKPreferencePaneRegistry *registry = [PKPreferencePaneRegistry sharedRegistry];
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
        @"PreferenceIdentifier", @"identifier",
	@"Preference", @"name",
	@"PreferenceIdentifier", @"path",
	[NSValue valueWithPointer: [self class]], @"class",
	self, @"instance", nil];
  [registry addPlugin: dict];

  return self;
}

- (void) dealloc
{
  [_mainView dealloc];
  [super dealloc];
}

@end
