#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

@protocol alternateRows
- (BOOL) drawAlternateRows;
- (float) alternateRowHeight;
@end

@implementation NSClipView (theme)

- (void) drawRect: (NSRect)rect
{
  if (_drawsBackground)
    {
	     if ([_documentView respondsToSelector: @selector (drawAlternateRows)])
		 {
			if ([(id <alternateRows>)_documentView drawAlternateRows])
			{
				float rowHeight = [(id<alternateRows>)_documentView alternateRowHeight];
		 		BOOL draw = YES;
		 		
				int i;
		 		for (i = 0; i < _bounds.size.height; i += rowHeight)
		 		{
					NSRect cell = NSMakeRect (_bounds.origin.x, _bounds.origin.y + i,
							_bounds.size.width, rowHeight);
					if (draw)
					{	
						[[NSColor alternateRowBackgroundColor] set];
						draw = NO;
					}
					else
					{
						[[NSColor rowBackgroundColor] set];
						draw = YES;
					}
					NSRectFill (cell);
		 		}
			}
		}
		else
		{
      		[_backgroundColor set];
      		NSRectFill(rect);
	  	}
    }
}

@end
