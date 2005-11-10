#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GSDrawFunctions.h"

@interface NSColorWell (theme)
@end

@implementation NSColorWell (theme)
- (void) drawRect: (NSRect)clipRect
{
  NSRect aRect = _bounds;

  if (NSIntersectsRect(aRect, clipRect) == NO)
    {
      return;
    }

  if (_is_bordered == YES)
    {
      if (_is_active == YES)
        {
          [THEME drawButton: aRect inView: self style: NSRegularSquareBezelStyle highlighted: YES];
        }
      else
        {
          [THEME drawButton: aRect inView: self style: NSRegularSquareBezelStyle highlighted: NO];
        }

      /*
       * Set an inset rect for the color area
       */
      _wellRect = NSInsetRect(_bounds, 8.0, 8.0);
    }
  else
    {
      _wellRect = _bounds;
    }

  aRect = _wellRect;

  /*
   * OpenStep 4.2 behavior is to omit the inner border for
   * non-enabled NSColorWell objects.
   */
  if ([self isEnabled])
    {
      /*
       * Draw inner frame.
       */
      [THEME drawGrayBezel: aRect : clipRect];
      aRect = NSInsetRect(aRect, 2.0, 2.0);
    }

  [self drawWellInside: NSIntersectionRect(aRect, clipRect)];
}
@end
