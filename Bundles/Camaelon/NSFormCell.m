#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GraphicToolbox.h"
#include "GSDrawFunctions.h"

@interface NSFormCell (theme)
@end

@implementation NSFormCell (theme)
- (void) drawWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{   
  NSRect titleFrame = cellFrame;
  NSRect borderedFrame = cellFrame;
    
  // Save last view drawn to
  if (_control_view != controlView)
    _control_view = controlView;

  // do nothing if cell's frame rect is zero
  if (NSIsEmptyRect(cellFrame))
    return;

  // Safety check
  if (_displayedTitleWidth == -1)
    _displayedTitleWidth = [self titleWidth];

  //
  // Draw title
  //
  titleFrame.size.width = _displayedTitleWidth;
  [_titleCell drawWithFrame: titleFrame inView: controlView];

  //
  // Leave unfilled the space between titlecell and editable text.
  // 

  //
  // Draw border
  //
  borderedFrame.origin.x   += _displayedTitleWidth + 3;
  borderedFrame.size.width -= _displayedTitleWidth + 3;

  if (NSIsEmptyRect(borderedFrame))
    return;
/*
  if (_cell.is_bordered)
    {
      [shadowCol set];
      NSFrameRect(borderedFrame);
    }
  else if (_cell.is_bezeled)
    {
      NSRect frame = [THEME drawWhiteBezel: borderedFrame : NSZeroRect];
      [[NSColor textBackgroundColor] set];
      NSRectFill (frame);
    }
*/

  if (_cell.is_bordered || _cell.is_bezeled)
  {
	BOOL focus = NO;
	//if (_cell.shows_first_responder
        //  && [[controlView window] firstResponder] == controlView)
	if (_cell.shows_first_responder)
  	{
		focus = YES;
	}
	[THEME drawTextField: borderedFrame focus: focus flipped: [controlView isFlipped]];
  }

  if (_cell.is_bezeled)
  {
	if (_cell.is_highlighted)
		[[NSColor selectedTextBackgroundColor] set];
	else
		[[NSColor textBackgroundColor] set];
	NSRect frame = NSMakeRect (borderedFrame.origin.x + 2, borderedFrame.origin.y + 2, borderedFrame.size.width - 4, borderedFrame.size.height - 4);
 	NSRectFill (frame);	
  }
  _cell.state = NSOffState;

  //
  // Draw interior
  //
  [self drawInteriorWithFrame: cellFrame inView: controlView];
}
@end
