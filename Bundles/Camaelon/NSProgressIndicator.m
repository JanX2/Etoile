#include "GSDrawFunctions.h"

@interface NSProgressIndicator (theme)
@end

@implementation NSProgressIndicator (theme)

- (void)drawRect:(NSRect)rect
{
   NSRect       r;

   // Draw the Bezel
   if (_isBezeled)
     {
       // Calc the inside rect to be drawn
        //r = [GSDrawFunctions drawGrayBezelRound: _bounds :rect];
	[GSDrawFunctions drawProgressIndicator: rect];
	r = _bounds;
     }
   else
     r = _bounds;

   if (_isIndeterminate)                // Draw indeterminate
     {
       // FIXME: Do nothing at this stage
     }
   else                         // Draw determinate 
     {
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
           r = NSIntersectionRect(r,rect);
           if (!NSIsEmptyRect(r))
             {
		//r.size.height-=1;
		//r.origin.y -=2;
		NSImage* img = [NSImage imageNamed: @"ProgressBar/ProgressBar-horizontal-indicator.tiff"];
		float deltaY = (r.size.height - [img size].height)/2.0;
		r.origin.y += deltaY;
		[GraphicToolbox fillHorizontalRect: r withImage: img];
             }
         }
     }
}

@end
