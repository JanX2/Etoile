#import "BKOutlineView.h"

@implementation BKOutlineView

- (BOOL) becomeFirstResponder
{
  activeView = YES;
  return [super becomeFirstResponder];
}

- (BOOL) resignFirstResponder
{
  activeView = NO;
  return [super resignFirstResponder];
}

- (BOOL) active
{
  return activeView;
}

@end

