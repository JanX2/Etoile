#include "GSDrawFunctions.h"

@implementation NSTableHeaderCell (theme)

//Would be nice to correct that on -gui... it should use _text_color

- (NSColor *)textColor
{
      return [NSColor blackColor];
}

static NSColor* bgCol;
static NSColor* hbgCol;
static NSColor* clearCol;
  
// Override drawInteriorWithFrame:inView: to be able 
// to display images as NSCell does
- (void) drawInteriorWithFrame: (NSRect)cellFrame 
			inView: (NSView*)controlView
{
  [THEME drawTableHeaderCellInRect: cellFrame
	highlighted: _cell.is_highlighted];
  _textfieldcell_draws_background = NO;

  switch (_cell.type)
    {
    case NSTextCellType:
      [super drawInteriorWithFrame: cellFrame inView: controlView];
      break;
      
    case NSImageCellType:
      //
      // Taken (with modifications) from NSCell
      //

      // Initialize static colors if needed
      if (clearCol == nil)
	{
	  bgCol = RETAIN([NSColor controlShadowColor]);
	  hbgCol = RETAIN([NSColor controlHighlightColor]);
	  clearCol = RETAIN([NSColor clearColor]);
	}
      // Prepare to draw
      cellFrame = [self drawingRectForBounds: cellFrame];
      // Deal with the background
      if ([self isOpaque])
	{
	  NSColor *bg;
	  
	  if (_cell.is_highlighted)
	    bg = hbgCol;
	  else
	    bg = bgCol;
	  [bg set];
	  //NSRectFill (cellFrame);//NRO
	}
      // Draw the image
      if (_cell_image)
	{
	  NSSize size;
	  NSPoint position;
	  
	  size = [_cell_image size];
	  position.x = MAX (NSMidX (cellFrame) - (size.width/2.), 0.);
	  position.y = MAX (NSMidY (cellFrame) - (size.height/2.), 0.);
	  if ([controlView isFlipped])
	    position.y += size.height;
	  [_cell_image compositeToPoint: position operation: NSCompositeSourceOver];
	}
      // End the drawing
      break;
      
    case NSNullCellType:
      break;
    }
}

- (void) drawWithFrame: (NSRect)cellFrame
                inView: (NSView *)controlView
{
  [self drawInteriorWithFrame: cellFrame inView: controlView];
  NSBezierPath *border = [NSBezierPath bezierPathWithRect:cellFrame];
  [border stroke];
}

@end

