#include "GSDrawFunctions.h"

@interface NSProgressIndicator (theme)
@end

@implementation NSProgressIndicator (theme)

- (void)drawRect:(NSRect)rect
{
   NSRect       r = _bounds;

   [THEME drawProgressIndicatorBackgroundOn: self];

   if (_doubleValue > _minValue)
   {
	double val;
        if (_doubleValue > _maxValue)
             val = _maxValue - _minValue;
        else  
             val = _doubleValue - _minValue;
  
        if (_isVertical)
             r.size.height = NSHeight(r) * (val / (_maxValue - _minValue));
        else
             r.size.width = NSWidth(r) * (val / (_maxValue - _minValue));

	[THEME drawProgressIndicatorForegroundInRect: r];
   }
}

@end
