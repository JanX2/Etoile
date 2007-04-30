#import "OSShelfCell.h"

@implementation OSShelfCell
- (void) setObject: (id) o
{
  ASSIGN(object, o);
  if ([object isKindOfClass: [NSNull class]])
  {
  }
  else
  {
    [self setImage: [object icon]];
    [self setTitle: [object name]];
  }
}

- (id) object
{
  return object;
}

@end

