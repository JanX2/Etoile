#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GSDrawFunctions.h"
#include "GraphicToolbox.h"

@implementation NSBox (theme)

- (BOOL) isOpaque { return NO; }

- (void) drawRect: (NSRect)rect
{
  NSColor *color = [_window backgroundColor];
  rect = NSIntersectionRect(_bounds, rect);
  // Fill inside
  [color set];
  NSRectFill(rect);

  // Draw border
  switch (_border_type)
    {
    case NSNoBorder:
      break;
    case NSLineBorder:
      [[NSColor controlDarkShadowColor] set];
      NSFrameRect(_border_rect);
      break;
    case NSBezelBorder:
      [GSDrawFunctions drawDarkBezel: _border_rect : rect];
      break;
    case NSGrooveBorder: // default on gnustep
      //[GSDrawFunctions drawGroove: _border_rect : rect];
      [GSDrawFunctions drawBox: _border_rect on: self];
      break;
    }

  
  // Draw title
  
  NSRect _final_title_rect = _title_rect;
  float addBorderHeight = [GSDrawFunctions boxBorderHeight] / 2.0;
  
  if (_title_position != NSNoTitle)
    {

       if ((_border_type != NSNoBorder) &&
          ((_title_position == NSAtTop) ||
           (_title_position == NSAtBottom)))
       	{
	       if (_title_position == NSAtTop)
	       	{
		       _final_title_rect.origin.y -= addBorderHeight;
		}
	       else
	       	{
			_final_title_rect.origin.y += addBorderHeight;
		}
	
       	}
       // If the title is on the border, clip a hole in the later
       if ((_border_type != NSNoBorder) &&
          ((_title_position == NSAtTop) ||
           (_title_position == NSAtBottom)))
        {
          [color set];
          NSRectFill(_final_title_rect);
        }
      [_cell drawWithFrame: _final_title_rect inView: self];
    }
}


@end

