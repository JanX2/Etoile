#include "GSDrawFunctions.h"

@implementation NSTableHeaderCell (theme)

//Would be nice to correct that on -gui... it should use _text_color

- (NSColor *)textColor
{
      return [NSColor blackColor];
}
  

- (void) drawInteriorWithFrame: (NSRect)cellFrame
                        inView: (NSView*)controlView
{
/*
  NSColor* startColor = [NSColor colorWithCalibratedRed: 0.16 green: 0.26 blue: 0.4 alpha: 1.0];
  NSColor* endColor = [NSColor colorWithCalibratedRed: 0.7 green: 0.75 blue: 0.83 alpha: 1.0];
  NSColor* startColorH = [NSColor colorWithCalibratedRed: 0.36 green: 0.46 blue: 0.6 alpha: 1.0];
  NSColor* endColorH = [NSColor colorWithCalibratedRed: 0.8 green: 0.85 blue: 0.93 alpha: 1.0];
*/

  NSColor* startColor = [NSColor colorWithCalibratedRed: 0.5 green: 0.5 blue: 0.5 alpha: 1.0];
  NSColor* endColor = [NSColor colorWithCalibratedRed: 0.7 green: 0.7 blue: 0.7 alpha: 1.0];
  NSColor* startColorH = [NSColor colorWithCalibratedRed: 0.9 green: 0.9 blue: 0.9 alpha: 1.0];
  NSColor* endColorH = [NSColor colorWithCalibratedRed: 0.9 green: 0.9 blue: 0.9 alpha: 1.0];
  NSGraphicsContext *ctxt = GSCurrentContext();

//if (_textfieldcell_draws_background)
{
  if (_cell.is_highlighted == YES)
  {
    //[GraphicToolbox drawVerticalGradientOnRect: cellFrame
    //  withStartColor: startColorH
    //  andEndColor: endColorH];
    //[GraphicToolbox drawVerticalGradientOnRect: NSMakeRect (cellFrame.origin.x - 1, 
	//cellFrame.origin.y, cellFrame.size.width + 2, cellFrame.size.height)
      //withStartColor: startColor
      //andEndColor: endColor];
	NSBezierPath* path = [NSBezierPath bezierPath];
//	[path appendBezierPathWithRoundedRectangle: cellFrame withRadius: 8.0];
//	[[NSColor colorWithCalibratedRed: 0.9 green: 0.9 blue: 0.9 alpha: 1.0] set];
	[path fill];
	[GSDrawFunctions drawTableHeaderCellInRect: cellFrame highlighted: YES]; 
  }
  else
  {
	[GSDrawFunctions drawTableHeaderCellInRect: cellFrame highlighted: NO]; 
//    [GraphicToolbox drawVerticalGradientOnRect: cellFrame
//      withStartColor: startColor
//      andEndColor: endColor];
  }
}
  _textfieldcell_draws_background = NO;

  switch (_cell.type)
    {
    case NSTextCellType:
      [self setTextColor: [NSColor blueColor]];
      [super drawInteriorWithFrame: cellFrame inView: controlView];
      break;

    case NSImageCellType:
      //
      // Taken (with modifications) from NSCell
      //

      // Initialize static colors if needed
      //if (clearCol == nil)
        {
          //bgCol = RETAIN([NSColor selectedControlColor]);
          //hbgCol = RETAIN([NSColor controlBackgroundColor]);
          //clearCol = RETAIN([NSColor clearColor]);
        }
      // Prepare to draw
      cellFrame = [self drawingRectForBounds: cellFrame];
      // Deal with the background
      if ([self isOpaque])
        {
          NSColor *bg;

          //if (_cell.is_highlighted)
            //bg = bgCol;
          //else
            //bg = hbgCol;
          [bg set];
          //NSRectFill (cellFrame);
          if (_cell_image)
            [_cell_image setBackgroundColor: bg];
        }
      else
        {
          //if (_cell_image)
            //[_cell_image setBackgroundColor: clearCol];
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
          [_cell_image compositeToPoint: position operation: NSCompositeCopy];
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
  NSGraphicsContext *ctxt = GSCurrentContext();
/*
  if (NSIsEmptyRect (cellFrame) || ![controlView window])
    return;
*/
/*
  [GraphicToolbox drawButtonOnRect: cellFrame 
    pushed: GSWViewIsFlipped(ctxt)];
*/
//  cellFrame.size.width = cellFrame.size.width - 1;
/*
	NSBezierPath* path = [NSBezierPath bezierPath];
	[path appendBezierPathWithRoundedRectangle: cellFrame withRadius: 8.0];
	[[NSColor colorWithCalibratedRed: 0.6 green: 0.6 blue: 0.7 alpha: 1.0] set];
	[path fill];
*/
/*
  NSColor* startColor = [NSColor colorWithCalibratedRed: 0.5 green: 0.5 blue: 0.5 alpha: 1.0];
  NSColor* endColor = [NSColor colorWithCalibratedRed: 0.5 green: 0.5 blue: 0.5 alpha: 1.0];
  NSColor* startColorH = [NSColor colorWithCalibratedRed: 0.9 green: 0.9 blue: 0.9 alpha: 1.0];
  NSColor* endColorH = [NSColor colorWithCalibratedRed: 0.9 green: 0.9 blue: 0.9 alpha: 1.0];
    [GraphicToolbox drawVerticalGradientOnRect: cellFrame
      withStartColor: startColor
      andEndColor: endColor];
*/
  [self drawInteriorWithFrame: cellFrame inView: controlView];

}

@end

