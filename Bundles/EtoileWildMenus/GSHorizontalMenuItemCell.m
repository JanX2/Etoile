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

#import "GSHorizontalMenuItemCell.h"

#import <AppKit/NSGraphics.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSParagraphStyle.h>
#import <AppKit/NSMenuView.h>
#import <AppKit/PSOperators.h>
#import <AppKit/NSColor.h>

#import "MenuBarHeight.h"

@implementation GSHorizontalMenuItemCell

static NSImage * arrowImage = nil;

+ (void) initialize
{
  if (self == [GSHorizontalMenuItemCell class])
    {
      arrowImage = [[NSImage imageNamed: @"common_3DArrowDown"] copy];
    }
}

- (id) init
{
  [super init];
  _target = nil;
  _highlightsByMask = NSChangeBackgroundCellMask;
  _showAltStateMask = NSNoCellMask;
  _cell.image_position = NSNoImage;
  [self setAlignment: NSCenterTextAlignment];
  [self setFont: [NSFont systemFontOfSize: 0]];

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
  cellFrame.size.height = [[self font] defaultLineHeightForFont];
  cellFrame.origin.y = (MenuBarHeight - NSHeight(cellFrame)) / 2;

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
      [[NSColor colorWithCalibratedRed: 0.0
                                 green: 0.0
                                  blue: 1
                                 alpha: 0.3] set];

      NSRectFill(cellFrame);
    }
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
    {
      [self drawImageWithFrame: cellFrame inView: controlView];
    }
     
  // Draw the title
  if (_titleWidth > 0)
    [self drawTitleWithFrame: cellFrame inView: controlView];

  // Draw the key equivalent
  if (_keyEquivalentWidth > 0)
    {
//      [self drawKeyEquivalentWithFrame: cellFrame inView: controlView];
    }



  // draw the borders of the menu item

  [[NSColor colorWithCalibratedWhite: 1.0 alpha: 0.35] set];
  PSmoveto(NSMinX(cellFrame), NSMinY(cellFrame));
  PSrlineto(0, cellFrame.size.height);
  PSstroke();

  [[NSColor colorWithCalibratedWhite: 0.67 alpha: 0.3] set];
  PSmoveto(NSMaxX(cellFrame) - 1, NSMinY(cellFrame));
  PSrlineto(0, cellFrame.size.height);
  PSstroke();
}

- (void) drawKeyEquivalentWithFrame:(NSRect)cellFrame
                            inView:(NSView *)controlView
{
  if ([_menuItem hasSubmenu])
    {
      NSSize    size;
      NSPoint   position;

      size = [arrowImage size];
      position.x = NSMaxX(cellFrame) - size.width - 5;
      position.y = MAX(NSMidY(cellFrame) - (size.height/2.0), 0.0);
      /*
       * Images are always drawn with their bottom-left corner at the origin
       * so we must adjust the position to take account of a flipped view.
       */
      if ([controlView isFlipped])
        position.y += size.height;

      [arrowImage compositeToPoint: position operation: NSCompositeSourceOver];
    }
  /* FIXME/TODO here - decide a consistent policy for images.
   *
   * The reason of the following code is that we draw the key
   * equivalent, but not if we are a popup button and are displaying
   * an image (the image is displayed in the title or selected entry
   * in the popup, it's the small square on the right). In that case,
   * the image will be drawn in the same position where the key
   * equivalent would be, so we do not display the key equivalent,
   * else they would be displayed one over the other one.
   */
  else if (![[_menuView menu] _ownedByPopUp])
    {    
      [self _drawText: [_menuItem keyEquivalent] inFrame: cellFrame];
    }
  else if (_imageToDisplay == nil)
    {
      [self _drawText: [_menuItem keyEquivalent] inFrame: cellFrame];
    }
}

- (void) drawTitleWithFrame:(NSRect)cellFrame
                    inView:(NSView *)controlView
{
  id value = [NSMutableParagraphStyle defaultParagraphStyle];
  NSDictionary *attr;
  NSRect cf = [self titleRectForBounds: cellFrame];
  NSSize titleSize;
  NSColor * color;

  if ([self isHighlighted])
    {
      color = [NSColor whiteColor];
    }
  else
    {
      color = [NSColor controlTextColor];
    }

  [value setAlignment: NSCenterTextAlignment];

  attr = [[NSDictionary alloc] initWithObjectsAndKeys:
                               value, NSParagraphStyleAttributeName,
                               _font, NSFontAttributeName,
                               color, NSForegroundColorAttributeName,
                               nil];

  if ([_menuItem isEnabled])
    _cell.is_disabled = NO;
  else
    _cell.is_disabled = YES;

  [[_menuItem title] drawInRect: cf withAttributes: attr];

  RELEASE(attr);
}

- (void) calcSize
{
  NSSize   componentSize;
  NSImage *anImage = nil;
  float    neededMenuItemHeight = 20;
 
  // Check if _mcell_belongs_to_popupbutton = NO while cell owned by 
  // popup button. FIXME
  if (!_mcell_belongs_to_popupbutton && [[_menuView menu] _ownedByPopUp])
    {
      _mcell_belongs_to_popupbutton = YES;
      [self setImagePosition: NSImageRight];
    }

  // State Image
  if ([_menuItem changesState])
    {
      // NSOnState
      if ([_menuItem onStateImage])
        componentSize = [[_menuItem onStateImage] size];
      else
        componentSize = NSMakeSize(0,0);
      _stateImageWidth = componentSize.width;
      if (componentSize.height > neededMenuItemHeight)
        neededMenuItemHeight = componentSize.height;

      // NSOffState
      if ([_menuItem offStateImage])
        componentSize = [[_menuItem offStateImage] size];
      else
        componentSize = NSMakeSize(0,0);
      if (componentSize.width > _stateImageWidth)
        _stateImageWidth = componentSize.width;
      if (componentSize.height > neededMenuItemHeight)
        neededMenuItemHeight = componentSize.height;

      // NSMixedState
      if ([_menuItem mixedStateImage])
        componentSize = [[_menuItem mixedStateImage] size];
      else
        componentSize = NSMakeSize(0,0);
      if (componentSize.width > _stateImageWidth)
        _stateImageWidth = componentSize.width;
      if (componentSize.height > neededMenuItemHeight)
        neededMenuItemHeight = componentSize.height;
    }
  else
    {
      _stateImageWidth = 0.0;
    }

  // Image
  if ((anImage = [_menuItem image]) && _cell.image_position == NSNoImage)
    [self setImagePosition: NSImageLeft];
  if (anImage)
    {
      componentSize = [anImage size];
      _imageWidth = componentSize.width;
      if (componentSize.height > neededMenuItemHeight)
        neededMenuItemHeight = componentSize.height;
    }
  else
    {
      _imageWidth = 0.0;
    }

  // Title and Key Equivalent
  componentSize = [self _sizeText: [_menuItem title]];

   // add a slight border around horizontal menu items
  componentSize.width += 8;

  _titleWidth = componentSize.width;
  if (componentSize.height > neededMenuItemHeight)
    neededMenuItemHeight = componentSize.height;

  componentSize = [self _sizeText: [_menuItem keyEquivalent]];
  _keyEquivalentWidth = componentSize.width;
  if (componentSize.height > neededMenuItemHeight)
    neededMenuItemHeight = componentSize.height;

  // Cache definitive height
  _menuItemHeight = neededMenuItemHeight;

  // At the end we set sizing to NO.
  _needs_sizing = NO;
}

@end
