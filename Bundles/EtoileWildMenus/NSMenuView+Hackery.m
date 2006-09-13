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

#include "MHMenuItemCell.h"
#include "NSMenuView+Hackery.h"

#import <AppKit/NSApplication.h>
#import <AppKit/PSOperators.h>

#import "EtoileMenuTitleView.h"
#import "MenuBarHeight.h"

enum {
  BottomBorderOffset = 1
};

@implementation NSMenuView (Hackery)
- (NSRect) rectOfItemAtIndex: (int)index
{
  NSRect theRect;
      
  if (_needsSizing == YES)
    {
      [self sizeToFit];
    }
      
  /* Fiddle with the origin so that the item rect is shifted 1 pixel over
   */
  theRect.size = _cellSize;

  if (_horizontal == NO)
    { 
      if (![_attachedMenu _ownedByPopUp])
        {
          theRect.origin.y = 1 + (_cellSize.height * ([_itemCells count] - 
						  index - 1));
          theRect.origin.x = 1;
          theRect.size.width -= 1;
        }
      else
        {
          theRect.origin.y = _cellSize.height * ([_itemCells count] - index - 1);
      	  theRect.origin.x = _leftBorderOffset;
        }
    }
  else
    {
      // FIXME: or remove?
      theRect.origin.x = _cellSize.width * (index + 1);
      theRect.origin.y = 0;
    }
      
  /* NOTE: This returns the correct NSRect for drawing cells, but nothing
   * else (unless we are a popup). This rect will have to be modified for
   * event calculation, etc..
   */ 
  return theRect;
}

- (NSPoint) locationForSubmenu: (NSMenu *)aSubmenu
{
  NSRect frame = [_window frame];
  NSRect submenuFrame;  
     
  if (_needsSizing)
    [self sizeToFit];

  if (aSubmenu)
    submenuFrame = [[[aSubmenu menuRepresentation] window] frame];
  else
    submenuFrame = NSZeroRect;
            
  if (_horizontal == YES)
    {
      NSRect aRect = [self rectOfItemAtIndex:
                       [_attachedMenu indexOfItemWithSubmenu: aSubmenu]];
      NSPoint subOrigin = [_window convertBaseToScreen:
                                    NSMakePoint(NSMinX(aRect),
                                    NSMinY(aRect))];
          
      return NSMakePoint(subOrigin.x, subOrigin.y - NSHeight(submenuFrame));
    }
  else
    {
      NSRect aRect = [self rectOfItemAtIndex:
            [_attachedMenu indexOfItemWithSubmenu: aSubmenu]];
      NSPoint subOrigin = [_window convertBaseToScreen:
            NSMakePoint(aRect.origin.x, aRect.origin.y)];

      return NSMakePoint (NSMaxX(frame),
        subOrigin.y - NSHeight(submenuFrame) + aRect.size.height +
        [EtoileMenuTitleView height]);
    }
}

- (void) itemAdded: (NSNotification*)notification
{
  int         index  = [[[notification userInfo] 
                          objectForKey: @"NSMenuItemIndex"] intValue];
  NSMenuItem *anItem = [_items_link objectAtIndex: index];
  id          aCell;
  int wasHighlighted = _highlightedItemIndex;

  if (![_attachedMenu _ownedByPopUp])
    aCell = [MHMenuItemCell new];
  else
    aCell = [NSMenuItemCell new];

  [aCell setMenuItem: anItem];
  [aCell setMenuView: self];
  [aCell setFont: _font];

  /* Unlight the previous highlighted cell if the index of the highlighted
   * cell will be ruined up by the insertion of the new cell.  */
  if (wasHighlighted >= index)
    {
      [self setHighlightedItemIndex: -1];
    }
 
  [_itemCells insertObject: aCell atIndex: index];
                          
  /* Restore the highlighted cell, with the new index for it.  */
  if (wasHighlighted >= index)
    {
      /* Please note that if wasHighlighted == -1, it shouldn't be possible
       * to be here.  */
      [self setHighlightedItemIndex: ++wasHighlighted];
    }

  [aCell setNeedsSizing: YES];
  RELEASE(aCell);

  // Mark the menu view as needing to be resized.
  [self setNeedsSizing: YES];
}

- (void) sizeToFit
{
  unsigned i;
  unsigned howMany = [_itemCells count];
  unsigned wideTitleView = 1;
  float    neededImageAndTitleWidth = 0.0;
  float    neededKeyEquivalentWidth = 0.0;
  float    neededStateImageWidth = 0.0;
  float    accumulatedOffset = 0.0;
  float    popupImageWidth = 0.0;

  // Popup menu doesn't need title bar
  if (![_attachedMenu _ownedByPopUp])
    {
        if ([_attachedMenu supermenu] != nil)
        {
//             @try
//             {
//                 NSMenuItemCell *msr = [[[_attachedMenu supermenu] menuRepresentation] 
//                                           menuItemCellForItemAtIndex:
//                                               [[_attachedMenu supermenu] indexOfItemWithTitle: [_attachedMenu title]]];
//                 neededImageAndTitleWidth += [msr titleWidth] + GSCellTextImageXDist;
//             }
//             @catch(id e)
//             {
                neededImageAndTitleWidth += 100;
//             }
        }
    }

  for (i = 0; i < howMany; i++)
    {
      float aStateImageWidth;
      float aTitleWidth;
      float anImageWidth;
      float anImageAndTitleWidth;
      float aKeyEquivalentWidth;
      NSMenuItemCell *aCell = [_itemCells objectAtIndex: i];
     
      // State image area.
      aStateImageWidth = [aCell stateImageWidth];
     
      // Title and Image area.
      aTitleWidth = [aCell titleWidth];
      anImageWidth = [aCell imageWidth]; 
     
      // Key equivalent area.
      aKeyEquivalentWidth = [aCell keyEquivalentWidth];
     
      switch ([aCell imagePosition])
        {
        case NSNoImage:  
          anImageAndTitleWidth = aTitleWidth;
          break;
      
        case NSImageOnly:
          anImageAndTitleWidth = anImageWidth;
          break;
     
        case NSImageLeft:
        case NSImageRight:
          anImageAndTitleWidth = anImageWidth + aTitleWidth + GSCellTextImageXDist;
          break;

        case NSImageBelow:
        case NSImageAbove:
        case NSImageOverlaps:
        default:
          if (aTitleWidth > anImageWidth)
            anImageAndTitleWidth = aTitleWidth;
          else  
            anImageAndTitleWidth = anImageWidth;
          break;
        }
          
      if (aStateImageWidth > neededStateImageWidth)
        neededStateImageWidth = aStateImageWidth;
        
      if (anImageAndTitleWidth > neededImageAndTitleWidth)
        neededImageAndTitleWidth = anImageAndTitleWidth;

      if (aKeyEquivalentWidth > neededKeyEquivalentWidth)
        neededKeyEquivalentWidth = aKeyEquivalentWidth;
        
      // Title view width less than item's left part width
      if ((anImageAndTitleWidth + aStateImageWidth)
          > neededImageAndTitleWidth)
        wideTitleView = 0;
      
      // Popup menu has only one item with nibble or arrow image
      if (anImageWidth)
        popupImageWidth = anImageWidth;
    }
        
  // Cache the needed widths.
  _stateImageWidth = neededStateImageWidth;
  _imageAndTitleWidth = neededImageAndTitleWidth;
  _keyEqWidth = neededKeyEquivalentWidth;
      
  accumulatedOffset = _horizontalEdgePad;
  if (howMany)
    {
      // Calculate the offsets and cache them.
      if (neededStateImageWidth)
        {
          _stateImageOffset = accumulatedOffset;
          accumulatedOffset += neededStateImageWidth += _horizontalEdgePad;
        }
        
      if (neededImageAndTitleWidth)
        {
          _imageAndTitleOffset = accumulatedOffset;
          accumulatedOffset += neededImageAndTitleWidth;
        }

      if (wideTitleView)
        {
          _keyEqOffset = accumulatedOffset = neededImageAndTitleWidth
            + (3 * _horizontalEdgePad);
        }
      else
        {
          _keyEqOffset = accumulatedOffset += (2 * _horizontalEdgePad);
        }
      accumulatedOffset += neededKeyEquivalentWidth + _horizontalEdgePad;
        
      if ([_attachedMenu supermenu] != nil && neededKeyEquivalentWidth < 8)
        {
          accumulatedOffset += 8 - neededKeyEquivalentWidth;
        }
    }
  else
    {
      accumulatedOffset += neededImageAndTitleWidth + 3 + 2;
      if ([_attachedMenu supermenu] != nil)
        accumulatedOffset += 15;
        accumulatedOffset += 15;
    }

  // Calculate frame size.
  if (![_attachedMenu _ownedByPopUp])
    {
      // Add the border width: 1 for left, 2 for right sides
      _cellSize.width = accumulatedOffset + 3;
    }
  else   
    {
      _keyEqOffset = _cellSize.width - _keyEqWidth - popupImageWidth;
    }

  if (_horizontal == YES)
    {
      [self setFrameSize: NSMakeSize(((howMany + 1) * _cellSize.width),
                                     _cellSize.height + _leftBorderOffset)];
      [_titleView setFrame: NSMakeRect (0, 0,
                                        _cellSize.width, _cellSize.height + 1)];
    }
  else
    {
      [self setFrameSize: NSMakeSize(_cellSize.width + _leftBorderOffset,
        (howMany * _cellSize.height) + [EtoileMenuTitleView height] +
        BottomBorderOffset)];
      [_titleView setFrame: NSMakeRect (0, howMany * _cellSize.height +
        BottomBorderOffset, NSWidth (_bounds), [EtoileMenuTitleView height])];
    }
     
  _needsSizing = NO;
}

- (void) update
{
  if ([self isHorizontal])
    {
      if (_titleView != nil)
        {
          [_titleView removeFromSuperview];
          _titleView = nil;
        }
    }
  else
    {
      if (![_attachedMenu _ownedByPopUp] && !_titleView)
        {
          _titleView = [[EtoileMenuTitleView alloc]
            initWithOwner:_attachedMenu];
          [self addSubview: _titleView];
          RELEASE(_titleView);
        }
      else if ([_attachedMenu _ownedByPopUp] && _titleView)
        {
          [_titleView removeFromSuperview];
          _titleView = nil;
        }

      [self sizeToFit];

      if ([_attachedMenu _ownedByPopUp] == NO)
        {
          if ([_attachedMenu isTornOff] && ![_attachedMenu isTransient])
            {
              [_titleView
                addCloseButtonWithAction: @selector(_performMenuClose:)];
              [_titleView setTitleVisible: YES];
            }
          else
            {
              [_titleView removeCloseButton];
              [_titleView setTitleVisible: NO];
            }
        }
    }
}

- (void) drawRect: (NSRect)rect
{
  NSRect myFrame;
  int        i;
  int        howMany = [_itemCells count];

  if (![_attachedMenu _ownedByPopUp])
    {
      NSDrawButton (_bounds, rect);
    }
  else
    {
      NSRectEdge sides[] = {NSMinXEdge, NSMaxYEdge};
      float      grays[] = {NSDarkGray, NSDarkGray}; 
      // Draw the dark gray upper left lines.
//      NSDrawTiledRects(_bounds, rect, sides, grays, 2);
    }

  PSsetgray(0.9);
  NSRectFill(rect);

  // Draw the menu cells.
  for (i = 0; i < howMany; i++)
    {
      NSRect            aRect;
      NSMenuItemCell    *aCell;
 
      aRect = [self rectOfItemAtIndex: i];
      if (NSIntersectsRect(rect, aRect) == YES)
        {
          aCell = [_itemCells objectAtIndex: i];
          [aCell drawWithFrame: aRect inView: self];
        }
    }

  myFrame = [self frame];

  [[NSColor whiteColor] set];
  PSmoveto(0, 0);
  PSrlineto(0, NSHeight(myFrame));
  PSrlineto(NSWidth(myFrame), 0);
  PSstroke();

  [[NSColor darkGrayColor] set];
  PSmoveto(NSMaxX(myFrame) - 1, NSMaxY(myFrame));
  PSrlineto(0, -(NSHeight(myFrame) - 1));
  PSrlineto(-NSWidth(myFrame), 0);
  PSstroke();
}

- (void) mouseDown: (NSEvent*)theEvent
{
  NSRect	currentFrame;
  NSRect	originalFrame;
  NSPoint	currentTopLeft;
  NSPoint	originalTopLeft = NSZeroPoint; /* Silence compiler.  */
  BOOL          restorePosition;
  /*
   * Only for non transient menus do we want
   * to remember the position.
   */ 
  restorePosition = ![_attachedMenu isTransient];

  if (restorePosition)
    { // store old position;
      originalFrame = [_window frame];
      originalTopLeft = originalFrame.origin;
      originalTopLeft.y += originalFrame.size.height;
    }
  
  [NSEvent startPeriodicEventsAfterDelay: 0.1 withPeriod: 0.01];
  [self trackWithEvent: theEvent];
  [NSEvent stopPeriodicEvents];

  if (restorePosition)
    {
      currentFrame = [_window frame];
      currentTopLeft = currentFrame.origin;
      currentTopLeft.y += currentFrame.size.height;

      if (NSEqualPoints(currentTopLeft, originalTopLeft) == NO)
        {
          NSPoint	origin = currentFrame.origin;
          
          origin.x += (originalTopLeft.x - currentTopLeft.x);
          origin.y += (originalTopLeft.y - currentTopLeft.y);
          [_attachedMenu nestedSetFrameOrigin: origin];
        }
    }
}

@end
