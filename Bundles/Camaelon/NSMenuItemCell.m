#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GSDrawFunctions.h"

static NSImage  *arrowImageUnselected = nil; 
static NSImage  *arrowImageSelected = nil; 
static NSImage  *arrowImageCurrent = nil;

@implementation NSMenuItemCell (theme)
- (void) drawBorderAndBackgroundWithFrame: (NSRect)cellFrame
                                  inView: (NSView *)controlView
{
//  if (!_cell.is_bordered)
//    return;

  if (_cell.is_highlighted && (_highlightsByMask & NSPushInCellMask))
    {
      //[THEME drawGrayBezel: cellFrame : NSZeroRect];
      [THEME drawButton: cellFrame inView: nil style: NSRegularSquareBezelStyle highlighted: YES];
    }
  else
    {
      [THEME drawButton: cellFrame inView: nil style: NSRegularSquareBezelStyle highlighted: NO];
    }

}
- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  unsigned  mask;

  // Transparent buttons never draw
  if (_buttoncell_is_transparent)
    return;

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

  // pushed in buttons contents are displaced to the bottom right 1px
  if (_cell.is_bordered && (mask & NSPushInCellMask))
    {
      cellFrame = NSOffsetRect(cellFrame, 1., [controlView isFlipped] ? 1. : -1.);
    }
  /*
   * Determine the background color and cache it in an ivar so that the
   * low-level drawing methods don't need to do it again.
   */
  if (arrowImageSelected == nil) 
	arrowImageSelected = [[NSImage imageNamed: @"Arrows/hierarchical-arrows-selected.tiff"] retain];
  if (arrowImageUnselected == nil) 
	arrowImageUnselected = [[NSImage imageNamed: @"Arrows/hierarchical-arrows-unselected.tiff"] retain];

  if (mask & (NSChangeGrayCellMask | NSChangeBackgroundCellMask))
    {
      	_backgroundColor = [NSColor selectedMenuItemColor];
	arrowImageCurrent = arrowImageSelected;
  	[_backgroundColor set];
  	NSRectFill(cellFrame);
    }
  else
    {
	// not selected..
	arrowImageCurrent = arrowImageUnselected;
    }

  if (_backgroundColor == nil)
    _backgroundColor = [NSColor controlBackgroundColor];

  // Set cell's background color
 // [_backgroundColor set];
 // NSRectFill(cellFrame);

  /*
   * Determine the image and the title that will be
   * displayed. If the NSContentsCellMask is set the
   * image and title are swapped only if state is 1 or
   * if highlighting is set (when a button is pushed it's
   * content is changed to the face of reversed state).
   * The results are saved in two ivars for use in other
   * drawing methods.
   */
  if (mask & NSContentsCellMask)
    {
      _imageToDisplay = _altImage;
      if (!_imageToDisplay)
        _imageToDisplay = [_menuItem image];
      _titleToDisplay = _altContents;
      if (_titleToDisplay == nil || [_titleToDisplay isEqual: @""])
        _titleToDisplay = [_menuItem title];
    }
  else
    {
      _imageToDisplay = [_menuItem image];
      _titleToDisplay = [_menuItem title];
    }

  if (_imageToDisplay)
    {
      _imageWidth = [_imageToDisplay size].width;
    }

  // Draw the state image
  if (_stateImageWidth > 0)
    [self drawStateImageWithFrame: cellFrame inView: controlView];

  // Draw the image
  if (_imageWidth > 0)
    [self drawImageWithFrame: cellFrame inView: controlView];

  // Draw the title
  if (_titleWidth > 0)
    [self drawTitleWithFrame: cellFrame inView: controlView];

  // Draw the key equivalent
  if (_keyEquivalentWidth > 0)
    [self drawKeyEquivalentWithFrame: cellFrame inView: controlView];

  _backgroundColor = nil;
}


/*
- (void) idrawWithFrame: (NSRect) cellFrame inView: (NSView*) controlView
{
	[super drawWithFrame: cellFrame inView: controlView];
}
    
- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  unsigned  mask;

  // Transparent buttons never draw
  if (_buttoncell_is_transparent)
    return;

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

  // pushed in buttons contents are displaced to the bottom right 1px
  if (_cell.is_bordered && (mask & NSPushInCellMask))
    {
      cellFrame = NSOffsetRect(cellFrame, 1., [controlView isFlipped] ? 1. : -1.);
    }

  if (mask & (NSChangeGrayCellMask | NSChangeBackgroundCellMask))
  {
      [[NSColor selectedMenuItemColor] set];
      NSRectFill(cellFrame);
  }
  else
  {
/*
      NSColor* startColor = [NSColor colorWithCalibratedRed: 0.65 green: 0.65 blue: 0.65 alpha: 1.0];
      NSColor* endColor = [NSColor colorWithCalibratedRed: 0.9 green: 0.9 blue: 0.9 alpha: 1.0];
      if ([[self controlView] isKindOfClass: [NSPopUpButton class]])
      {
        //NSColor* startColor = [NSColor colorWithCalibratedRed: 0.75 green: 0.75 blue: 0.75 alpha: 1.0];
	/*
        NSColor* startColor = [NSColor colorWithCalibratedRed: 0.8 green: 0.8 blue: 0.8 alpha: 1.0];
        NSColor* endColor = [NSColor colorWithCalibratedRed: 0.8 green: 0.8 blue: 0.8 alpha: 1.0];
        [GraphicToolbox drawVerticalGradientOnRect: cellFrame 
          withStartColor: startColor
          andEndColor: endColor];
*/
/*
      NSColor* startColor = [NSColor colorWithCalibratedRed: 0.8 green: 0.8 blue: 0.8 alpha: 1.0];
      NSColor* endColor = [NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 1.0 alpha: 1.0];

		NSBezierPath* cadre1 = [NSBezierPath bezierPath];
		[cadre1 moveToPoint: NSMakePoint (cellFrame.origin.x + 3, cellFrame.origin.y)];
		[cadre1 lineToPoint: NSMakePoint (cellFrame.origin.x + cellFrame.size.width, cellFrame.origin.y)];
		[cadre1 lineToPoint: NSMakePoint (cellFrame.origin.x + cellFrame.size.width, cellFrame.origin.y + cellFrame.size.height - 3)];
		[[NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.0 alpha: 0.10] set];
		[cadre1 setLineWidth: 0];
		[cadre1 stroke];
		
		NSBezierPath* cadre2 = [NSBezierPath bezierPath];
		[cadre2 moveToPoint: NSMakePoint (cellFrame.origin.x + 2, cellFrame.origin.y + 1)];
		[cadre2 lineToPoint: NSMakePoint (cellFrame.origin.x + cellFrame.size.width - 1, cellFrame.origin.y + 1)];
		[cadre2 lineToPoint: NSMakePoint (cellFrame.origin.x + cellFrame.size.width - 1, cellFrame.origin.y + cellFrame.size.height - 2)];
		[[NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.0 alpha: 0.30] set];
		[cadre2 setLineWidth: 0];
		[cadre2 stroke];

		NSBezierPath* cadre = [NSBezierPath bezierPathWithRect: NSMakeRect (cellFrame.origin.x, cellFrame.origin.y + 2, 
			cellFrame.size.width - 2, cellFrame.size.height - 2)];
		[[NSColor colorWithCalibratedRed: 0.4 green: 0.4 blue: 0.4 alpha: 1.00] set];
		[cadre setLineWidth: 0];
		[cadre stroke];

		NSRect rect = NSMakeRect (cellFrame.origin.x + 1, cellFrame.origin.y + 2, cellFrame.size.width - 4, cellFrame.size.height - 4);

	      [GraphicToolbox drawVerticalGradientOnRect: rect
	      	withStartColor: startColor
	      	andEndColor: endColor];

	      [GraphicToolbox drawVerticalGradientOnRect: NSMakeRect (rect.origin.x, rect.origin.y, 2, rect.size.height)
	      	withStartColor: endColor
	      	andEndColor: startColor];

	      [GraphicToolbox drawVerticalGradientOnRect: NSMakeRect (rect.origin.x + rect.size.width - 2, rect.origin.y, 2, rect.size.height)
	      	withStartColor: endColor
	      	andEndColor: startColor];
      }
      else
      {
        [GraphicToolbox drawHorizontalGradientOnRect: cellFrame 
          withStartColor: endColor
          andEndColor: startColor];
      }
//

  }

  //
   * Determine the image and the title that will be
   * displayed. If the NSContentsCellMask is set the
   * image and title are swapped only if state is 1 or
   * if highlighting is set (when a button is pushed it's
   * content is changed to the face of reversed state).
   * The results are saved in two ivars for use in other
   * drawing methods.
   //
  if (mask & NSContentsCellMask)
    {
      _imageToDisplay = _altImage;
      if (!_imageToDisplay)
        _imageToDisplay = [_menuItem image];
      _titleToDisplay = _altContents;
      if (_titleToDisplay == nil || [_titleToDisplay isEqual: @""])
        _titleToDisplay = [_menuItem title];
    }
  else
    {
      _imageToDisplay = [_menuItem image];
      _titleToDisplay = [_menuItem title];
    }

  if (_imageToDisplay)
    {
      _imageWidth = [_imageToDisplay size].width;
    }

  // Draw the state image
  if (_stateImageWidth > 0)
    [self drawStateImageWithFrame: cellFrame inView: controlView];

  // Draw the image
  if (_imageWidth > 0)
    [self drawImageWithFrame: cellFrame inView: controlView];

  // Draw the title
  if (_titleWidth > 0)
    [self drawTitleWithFrame: cellFrame inView: controlView];

  // Draw the key equivalent
  if (_keyEquivalentWidth > 0)
    [self drawKeyEquivalentWithFrame: cellFrame inView: controlView];

  _backgroundColor = nil;
}
*/

- (void) drawKeyEquivalentWithFrame:(NSRect)cellFrame
                            inView:(NSView *)controlView
{
  cellFrame = [self keyEquivalentRectForBounds: cellFrame];

  if ([_menuItem hasSubmenu])
    {
      NSSize    size;
      NSPoint   position;

      size = [arrowImageCurrent size];
      position.x = cellFrame.origin.x + cellFrame.size.width - size.width;
      position.y = MAX(NSMidY(cellFrame) - (size.height/2.), 0.);
      /*
 *        * Images are always drawn with their bottom-left corner at the origin
 *               * so we must adjust the position to take account of a flipped view.
 *                      */
      if ([controlView isFlipped])
        position.y += size.height;

      [arrowImageCurrent compositeToPoint: position operation: NSCompositeSourceOver];
    }
  /* FIXME/TODO here - decide a consistent policy for images.
 *    *
 *       * The reason of the following code is that we draw the key
 *          * equivalent, but not if we are a popup button and are displaying
 *             * an image (the image is displayed in the title or selected entry
 *                * in the popup, it's the small square on the right). In that case,
 *                   * the image will be drawn in the same position where the key
 *                      * equivalent would be, so we do not display the key equivalent,
 *                         * else they would be displayed one over the other one.
 *                            */
  else if (![[_menuView menu] _ownedByPopUp])
    {
      [self _drawText: [_menuItem keyEquivalent] inFrame: cellFrame];
    }
  else if (_imageToDisplay == nil)
    {
      [self _drawText: [_menuItem keyEquivalent] inFrame: cellFrame];
    }
}

@end
