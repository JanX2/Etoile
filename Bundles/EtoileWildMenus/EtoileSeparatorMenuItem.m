
#import <Foundation/NSString.h>
#import "EtoileSeparatorMenuItem.h"

// NOTE: This implementation is based on GSMenuSeparator private class
@implementation EtoileSeparatorMenuItem

- (id) init
{
  self = [super initWithTitle: @"-----------"
                       action: NULL
                keyEquivalent: @""];
  _enabled = NO;
  _changesState = NO;

  return self;
}

- (BOOL) isSeparatorItem
{
  return YES;
}

@end
