#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GraphicToolbox.h"
#include "GSDrawFunctions.h"

@implementation NSTextFieldCell (theme)
/*
- (NSColor*) highlightColorWithFrame: (NSRect) cellFrame inView: (NSView*) controlView
{
	return [NSColor greenColor];
}
*/

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
    //  [[NSColor greenColor] set];
    //  NSRectFill ([self drawingRectForBounds: cellFrame]);
  if (_textfieldcell_draws_background)
    {
      [_background_color set];
//      [[NSColor redColor] set];
      NSRectFill ([self drawingRectForBounds: cellFrame]);
/*
      NSBezierPath* path = [NSBezierPath bezierPath];
      [path appendBezierPathWithRoundedRectangle: [self drawingRectForBounds: cellFrame] withRadius: 2.0];
      [path fill];
*/
    }
  [super drawInteriorWithFrame: cellFrame inView: controlView];
}

- (void) drawWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  // do nothing if cell's frame rect is zero
  if (NSIsEmptyRect(cellFrame) || ![controlView window])
    return;

  if (_control_view != controlView)
    _control_view = controlView;

  // draw the border if needed
  if (_cell.is_bordered || _cell.is_bezeled)
    {
/*
	NSBezierPath* path = [NSBezierPath bezierPath];
	[path appendBezierPathWithRoundedRectangle: cellFrame withRadius: 2.0];
	[[NSColor colorWithCalibratedRed: 0.7 green: 0.7 blue: 0.7 alpha: 1.0] set];
	[[NSColor blackColor] set];
	[path fill];
*/
	BOOL focus = NO;
	//if (_cell.shows_first_responder
        //  && [[controlView window] firstResponder] == controlView)
	if (_cell.shows_first_responder)
  	{
		focus = YES;
	}


	[THEME drawTextField: cellFrame focus: focus flipped: [controlView isFlipped]];
    }

  [self drawInteriorWithFrame: cellFrame inView: controlView];
}

@end

