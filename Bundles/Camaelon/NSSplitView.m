#include "GSDrawFunctions.h"

@interface NSSplitView (theme)
@end

@implementation NSSplitView (theme)

- (BOOL) isOpaque { return NO; }
/*
- (void) drawRect: (NSRect)r
{
  NSArray *subs = [self subviews];
  int i, count = [subs count];
  id v;
  NSRect divRect;

  if ([self isOpaque])
    {
      [_backgroundColor set];
      NSRectFill(r);
    }

  for (i = 0; i < (count-1); i++)
    {
      v = [subs objectAtIndex: i];
      divRect = [v frame];
      if (_isVertical == NO)
        {
          divRect.origin.y = NSMaxY (divRect);
          divRect.size.height = _dividerWidth;
        }
      else
        {
          divRect.origin.x = NSMaxX (divRect);
          divRect.size.width = _dividerWidth;
        }
      [self drawDividerInRect: divRect];
    }
}
*/


@end
