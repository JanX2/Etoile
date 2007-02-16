/*
   Copyright (C) 2004 Michael Hanni.

   Author: Michael Hanni <mhanni@yahoo.com>
   Date: 2004

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#include <AppKit/NSGraphics.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSParagraphStyle.h>

#include "GSHorizontalMenuItemCell.h"

@implementation GSHorizontalMenuItemCell
- (id) init
{
  [super init];
  _target = nil;
  _highlightsByMask = NSChangeBackgroundCellMask;
  _showAltStateMask = NSNoCellMask;
  _cell.image_position = NSNoImage;
  [self setAlignment: NSCenterTextAlignment];
  [self setFont: [NSFont boldSystemFontOfSize: 0]];

  return self;
}

- (NSRect) drawingRectForBounds: (NSRect)theRect
{
  return NSMakeRect (theRect.origin.x,
                     theRect.origin.y + 2,
                     theRect.size.width,
                     theRect.size.height - 2);
}

- (NSRect) imageRectForBounds:(NSRect)cellFrame
{
  switch (_cell.image_position)
    {
    case NSNoImage:
      cellFrame = NSZeroRect;
      break;
      
    case NSImageOnly:
    case NSImageOverlaps:
      break;
      
    case NSImageLeft:
      cellFrame.origin.x  += 4.; // _horizontalEdgePad
      cellFrame.size.width = _imageWidth;
      break;
  
    case NSImageRight:
      cellFrame.origin.x  += _titleWidth;
      cellFrame.size.width = _imageWidth;
      break;
     
    case NSImageBelow:
      cellFrame.size.height /= 2;
      break;
      
    case NSImageAbove:
      cellFrame.size.height /= 2;
      cellFrame.origin.y += cellFrame.size.height;
      break;
    }
      
  return cellFrame;
} 

- (NSRect) titleRectForBounds:(NSRect)cellFrame
{
  /* This adjust will center us within the menubar. */

  cellFrame.size.height -= 2;

  switch (_cell.image_position)
    {
      case NSNoImage:
      case NSImageOverlaps:
        break;
  
      case NSImageOnly:
        cellFrame = NSZeroRect;
        break;
    
      case NSImageLeft:
        cellFrame.origin.x  += _imageWidth + GSCellTextImageXDist + 4;
        cellFrame.size.width = _titleWidth;
        break;
        
      case NSImageRight:
        cellFrame.size.width = _titleWidth;
        break;
                 
      case NSImageBelow:
        cellFrame.size.height /= 2;
        cellFrame.origin.y += cellFrame.size.height;
        break;

      case NSImageAbove:
        cellFrame.size.height /= 2;
        break;
    }

  return cellFrame;
}

- (void) drawBorderAndBackgroundWithFrame: (NSRect)cellFrame
                                  inView: (NSView *)controlView
{
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  unsigned  mask;
  NSColor *backgroundColor = nil;

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

  /* 
   * Determine the background color and cache it in an ivar so that the
   * low-level drawing methods don't need to do it again.
   */
  if (mask & (NSChangeGrayCellMask | NSChangeBackgroundCellMask))
    {
      backgroundColor = [NSColor selectedMenuItemColor];
    }
  if (backgroundColor == nil)
    backgroundColor = [NSColor controlBackgroundColor];

  // Set cell's background color
  [backgroundColor set];
  NSRectFill(cellFrame);
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
      [self setImagePosition: NSImageLeft];
    }
      
  // Draw the image
  if (_imageWidth > 0)
    [self drawImageWithFrame: cellFrame inView: controlView];
     
  // Draw the title
  if (_titleWidth > 0)
    [self drawTitleWithFrame: cellFrame inView: controlView];
}

- (void) drawTitleWithFrame:(NSRect)cellFrame
                    inView:(NSView *)controlView
{
  id value = [NSMutableParagraphStyle defaultParagraphStyle];
  NSDictionary *attr;
  NSRect cf = [self titleRectForBounds: cellFrame];
  NSSize titleSize;

  if (!_imageWidth)
    [value setAlignment: NSCenterTextAlignment];

  attr = [[NSDictionary alloc] initWithObjectsAndKeys:
                               value, NSParagraphStyleAttributeName,
                               _font, NSFontAttributeName,
                               [NSColor controlTextColor], NSForegroundColorAttributeName,
                               nil];

  if ([_menuItem isEnabled])
    _cell.is_disabled = NO;
  else
    _cell.is_disabled = YES;

  [[_menuItem title] drawInRect: cf
          withAttributes: attr];

  RELEASE(attr);
}
@end
