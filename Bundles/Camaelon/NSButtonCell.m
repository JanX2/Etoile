#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GraphicToolbox.h"
#include "GSDrawFunctions.h"

@implementation NSButtonCell (theme)
- (BOOL) isOpaque {
    return NO;
}

- (void) drawWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  // Save last view drawn to
  if (_control_view != controlView)
    _control_view = controlView;

  // transparent buttons never draw
  if (_buttoncell_is_transparent)
    return;

  // do nothing if cell's frame rect is zero
  if (NSIsEmptyRect(cellFrame))
    return;

  if ((_cell.is_bordered) &&
      (!_shows_border_only_while_mouse_inside || _mouse_inside))
  {
	
//	[GSDrawFunctions drawButton: cellFrame : NSZeroRect];
	[GSDrawFunctions drawButton: cellFrame inView: controlView 
			highlighted: _cell.is_highlighted];
  }
  else if (_cell.is_highlighted)
  {
  	NSColor	*backgroundColor = nil;
	backgroundColor = [NSColor selectedControlColor];
      	if (backgroundColor != nil) 
	{
	  [backgroundColor set];
	  NSRectFill (cellFrame);
	}
  }

  [self drawInteriorWithFrame: cellFrame inView: controlView];

/*
  if (_cell.shows_first_responder
	  && [[controlView window] firstResponder] == controlView)
  {
	[GSDrawFunctions drawFocusFrame: cellFrame];
  }
*/
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  unsigned	mask;
  NSImage	*imageToDisplay;
  NSRect	imageRect;
  NSAttributedString	*titleToDisplay;
  NSRect	titleRect;
  NSSize	imageSize = {0, 0};
  NSSize        titleSize = {0, 0};
  NSColor	*backgroundColor = nil;
  BOOL		flippedView = [controlView isFlipped];
  NSCellImagePosition ipos = _cell.image_position;

  // transparent buttons never draw
  if (_buttoncell_is_transparent)
    return;

  _control_view = controlView;

  cellFrame = [self drawingRectForBounds: cellFrame];

  if (_cell.is_highlighted)
    {
      mask = _highlightsByMask;

      if (_cell.state)
	mask &= ~_showAltStateMask;
    }
  else if (_cell.state)
    mask = _showAltStateMask;
  else
    mask = NSNoCellMask;

  /* Pushed in buttons contents are displaced to the bottom right 1px.  */
  if (ipos != NSImageAbove)
      cellFrame = NSOffsetRect(cellFrame, 1., flippedView ? 1. : -1.);
  if (_cell.is_bordered && (mask & NSPushInCellMask))
    {
      cellFrame = NSOffsetRect(cellFrame, 1., flippedView ? 1. : -1.);
    }

  /* Draw the cell's background color.  
     We draw when there is a border or when highlightsByMask
     is NSChangeBackgroundCellMask or NSChangeGrayCellMask,
     as required by our nextstep-like look and feel.  */
/*
  if (_cell.is_bordered 
      || (_highlightsByMask & NSChangeBackgroundCellMask)
      || (_highlightsByMask & NSChangeGrayCellMask))
    {
      // Determine the background color. 
      if (mask & (NSChangeGrayCellMask | NSChangeBackgroundCellMask))
        {
          backgroundColor = [NSColor selectedControlColor];
        }
      else if (_cell.is_bordered) 
        {
          backgroundColor = [NSColor controlBackgroundColor];
        }
      
      if (backgroundColor != nil) 
        {
          [backgroundColor set];
          NSRectFill (cellFrame);
        }
      
    }
*/

  /*
   * Determine the image and the title that will be
   * displayed. If the NSContentsCellMask is set the
   * image and title are swapped only if state is 1 or
   * if highlighting is set (when a button is pushed it's
   * content is changed to the face of reversed state).
   */
  if (mask & NSContentsCellMask)
    {
      imageToDisplay = _altImage;
      if (!imageToDisplay)
        {
	  imageToDisplay = _cell_image;
	}
      titleToDisplay = [self attributedAlternateTitle];
      if (titleToDisplay == nil || [titleToDisplay length] == 0)
        {
	  titleToDisplay = [self attributedTitle];
	}
    }
  else
    {
      imageToDisplay = _cell_image;
      titleToDisplay = [self attributedTitle];
    }

  if (imageToDisplay && ipos != NSNoImage)
    {
      imageSize = [imageToDisplay size];
    }

  if (titleToDisplay && ipos != NSImageOnly)
    {
      titleSize = [titleToDisplay size];
    }

  if (flippedView == YES)
    {
      if (ipos == NSImageAbove)
	{
	  ipos = NSImageBelow;
	}
      else if (ipos == NSImageBelow)
	{
	  ipos = NSImageAbove;
	}
    }
  
  /*
  The size calculations here should be changed very carefully, and _must_ be
  kept in sync with -cellSize. Changing the calculations to require more
  space isn't OK; this breaks interfaces designed using the old sizes by
  clipping away parts of the title.

  The current size calculations ensure that for bordered or bezeled cells,
  there's always at least a three point margin between the size returned by
  -cellSize and the minimum size required not to clip text. (In other words,
  the text can become three points wider (due to eg. font mismatches) before
  you lose the last character.)
  */
  switch (ipos)
    {
      case NSNoImage: 
	imageToDisplay = nil;
	titleRect = cellFrame;
	if (titleSize.width + 6 <= titleRect.size.width)
	  {
	    titleRect.origin.x += 3;
	    titleRect.size.width -= 6;
	  }
	break;

      case NSImageOnly: 
	titleToDisplay = nil;
	imageRect = cellFrame;
	break;

      case NSImageLeft: 
	imageRect.origin = cellFrame.origin;
	imageRect.size.width = imageSize.width;
	imageRect.size.height = cellFrame.size.height;
	if (_cell.is_bordered || _cell.is_bezeled) 
	  {
	    imageRect.origin.x += 3;
	  }
	titleRect = imageRect;
	titleRect.origin.x += imageSize.width + GSCellTextImageXDist;
	titleRect.size.width = NSMaxX(cellFrame) - titleRect.origin.x;
	if (titleSize.width + 3 <= titleRect.size.width)
	  {
	    titleRect.size.width -= 3;
	  }
	break;

      case NSImageRight: 
	imageRect.origin.x = NSMaxX(cellFrame) - imageSize.width;
	imageRect.origin.y = cellFrame.origin.y;
	imageRect.size.width = imageSize.width;
	imageRect.size.height = cellFrame.size.height;
	if (_cell.is_bordered || _cell.is_bezeled) 
	  {
	    imageRect.origin.x -= 3;
	  }
	titleRect.origin = cellFrame.origin;
	titleRect.size.width = imageRect.origin.x - titleRect.origin.x - GSCellTextImageXDist;
	titleRect.size.height = cellFrame.size.height;
	if (titleSize.width + 3 <= titleRect.size.width)
	  {
	    titleRect.origin.x += 3;
	    titleRect.size.width -= 3;
	  }
	break;

      case NSImageAbove: 
	/*
         * In this case, imageRect is all the space we can allocate
	 * above the text. 
	 * The drawing code below will then center the image in imageRect.
	 */
	titleRect.origin.x = cellFrame.origin.x;
	titleRect.origin.y = cellFrame.origin.y + GSCellTextImageYDist;
	titleRect.size.width = cellFrame.size.width;
	titleRect.size.height = titleSize.height;

	imageRect.origin.x = cellFrame.origin.x;
	imageRect.origin.y = NSMaxY(titleRect);
	imageRect.size.width = cellFrame.size.width;
	imageRect.size.height = NSMaxY(cellFrame) - imageRect.origin.y;

	if (_cell.is_bordered || _cell.is_bezeled) 
	  {
	    imageRect.origin.y -= 1;
	  }
	if (titleSize.width + 6 <= titleRect.size.width)
	  {
	    titleRect.origin.x += 3;
	    titleRect.size.width -= 6;
	  }
	break;

      case NSImageBelow: 
	/*
	 * In this case, imageRect is all the space we can allocate
	 * below the text. 
	 * The drawing code below will then center the image in imageRect.
	 */
	titleRect.origin.x = cellFrame.origin.x;
	titleRect.origin.y = NSMaxY(cellFrame) - titleSize.height;
	titleRect.size.width = cellFrame.size.width;
	titleRect.size.height = titleSize.height;

	imageRect.origin.x = cellFrame.origin.x;
	imageRect.origin.y = cellFrame.origin.y;
	imageRect.size.width = cellFrame.size.width;
	imageRect.size.height = titleRect.origin.y - GSCellTextImageYDist - imageRect.origin.y;

	if (_cell.is_bordered || _cell.is_bezeled) 
	  {
	    imageRect.origin.y += 1;
	  }
	if (titleSize.width + 6 <= titleRect.size.width)
	  {
	    titleRect.origin.x += 3;
	    titleRect.size.width -= 6;
	  }
	break;

      case NSImageOverlaps: 
	imageRect = cellFrame;
	titleRect = cellFrame;
	if (titleSize.width + 6 <= titleRect.size.width)
	  {
	    titleRect.origin.x += 3;
	    titleRect.size.width -= 6;
	  }
	break;
    }

  // Draw gradient
  if (!_cell.is_highlighted && _gradient_type != NSGradientNone)
    {
    	//NRO: this thing SHOULD NOT BE THERE --> a call to GSDrawFunctions would be better. 
        //BUG: Fix this in GNUstep cvs
      [self drawGradientWithFrame: cellFrame inView: controlView];
    }
    
  // Draw image
  if (imageToDisplay != nil)
    {
      NSSize size;
      NSPoint position;

      size = [imageToDisplay size];
      position.x = MAX(NSMidX(imageRect) - (size.width / 2.), 0.);
      position.y = MAX(NSMidY(imageRect) - (size.height / 2.), 0.);
      /*
       * Images are always drawn with their bottom-left corner at the origin
       * so we must adjust the position to take account of a flipped view.
       */
      if (flippedView)
	{
	  position.y += size.height;
	}
	
      if (_cell.is_disabled && _image_dims_when_disabled)
	{
	  [imageToDisplay dissolveToPoint: position fraction: 0.5];
	}
      else
	{
	  [imageToDisplay compositeToPoint: position 
	                         operation: NSCompositeSourceOver];
	}
    }

  // Draw title
  if (titleToDisplay != nil)
    {
      [self _drawAttributedText: titleToDisplay inFrame: titleRect];
    }

  // Draw first responder
/*
  if (_cell.shows_first_responder
      && [[controlView window] firstResponder] == controlView)
    {
      NSDottedFrameRect(cellFrame);
    }
*/
}

@end
