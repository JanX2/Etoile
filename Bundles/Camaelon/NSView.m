#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GraphicToolbox.h"
#include "GSDrawFunctions.h"

@implementation NSView (theme)
- (void) _setNeedsDisplay_real: (NSNumber *)n
{
  BOOL flag = [n boolValue];
  float margin = 8;
  NSRect new_bounds = NSMakeRect(_bounds.origin.x - margin, _bounds.origin.y - margin, 
			_bounds.size.width + margin*2, _bounds.size.height + margin*2);

  if (flag)
    {
      [self setNeedsDisplayInRect: new_bounds];
    }
  else
    {
      _rFlags.needs_display = NO;
      _invalidRect = NSZeroRect;
    }
}
- (void) _setNeedsDisplayInRect_real: (NSValue *)v
{
  NSRect invalidRect = [v rectValue];
  NSView *currentView = _super_view;
  
  /*
   *    Limit to bounds, combine with old _invalidRect, and then check to see
   *    if the result is the same as the old _invalidRect - if it isn't then
   *    set the new _invalidRect.
   */
  
  float margin = 8;
  NSRect new_bounds = NSMakeRect(_bounds.origin.x - margin, _bounds.origin.y - margin, 
			_bounds.size.width + margin*2, _bounds.size.height + margin*2);

  invalidRect = NSIntersectionRect(invalidRect, new_bounds);
  invalidRect = NSUnionRect(_invalidRect, invalidRect);
  invalidRect = new_bounds;

  if (NSEqualRects(invalidRect, _invalidRect) == NO)
    {
      NSView    *firstOpaque = [self opaqueAncestor];

      _rFlags.needs_display = YES;
      _invalidRect = invalidRect;
      if (firstOpaque == self)
        {
          [_window setViewsNeedDisplay: YES];
        }
      else
        {
          invalidRect = [firstOpaque convertRect: _invalidRect fromView: self];
          [firstOpaque setNeedsDisplayInRect: invalidRect];
        }
    }
  /*
   * Must make sure that superviews know that we need display.
   * NB. we may have been marked as needing display and then moved to another
   * parent, so we can't assume that our parent is marked simply because we are.
   */
  while (currentView)
    {
      currentView->_rFlags.needs_display = YES;
      currentView = currentView->_super_view;
    }
}


@end
