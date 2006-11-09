#import "PreferencePane.h"

@implementation PreferencePane

- (void) removeDateAction: (id) sender
{
  NSLog(@"%@ (%d)", sender, [sender tag]);
}

- (id) init 
{
  self = [super init];

  if ([NSBundle loadNibNamed: @"PreferencePane" owner: self] == NO) {
    [self dealloc];
    return nil;
  }

  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
         @"01General", @"identifier",
         @"General", @"name",
         @"01General", @"path",
         [NSValue valueWithPointer: [self class]], @"class",
         self, @"instance", nil];
  [[PKPreferencePaneRegistry sharedRegistry] addPlugin: dict];
  
  return self;
}

- (void) dealloc
{
  [super dealloc];
}

@end

