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

#import "GSHorizontalMenuView.h"
#import <AppKit/AppKit.h>
#import "GSHorizontalMenuItemCell.h"
#import "EtoileMenuUtilities.h"
#import "MenuBarHeight.h"

typedef struct _GSCellRect {
  NSRect rect;
} GSCellRect;

#define GSI_ARRAY_TYPES         0
#define GSI_ARRAY_TYPE          GSCellRect

#define GSI_ARRAY_NO_RETAIN
#define GSI_ARRAY_NO_RELEASE

#ifdef GSIArray
#undef GSIArray
#endif
#include <GNUstepBase/GSIArray.h>

@implementation GSHorizontalMenuView
- (id) initWithFrame: (NSRect)aFrame
{
  NSZone *zone;
  
  self = [super initWithFrame: aFrame];
  zone = [self zone];
  _cellRects = NSZoneMalloc(zone, sizeof(GSIArray_t));
  GSIArrayInitWithZoneAndCapacity(_cellRects, zone, 8);

  return self;
}

- (void) dealloc
{
  GSIArrayEmpty(_cellRects);
  NSZoneFree([self zone], _cellRects);
  [super dealloc];
}

- (void) itemAdded: (NSNotification*)notification
{
  int         index  = [[[notification userInfo] 
                          objectForKey: @"NSMenuItemIndex"] intValue];
  NSMenuItem *anItem = [[[self menu] itemArray] objectAtIndex: index];
  id          aCell  = [GSHorizontalMenuItemCell new];
  int wasHighlighted = _highlightedItemIndex;

  [aCell setMenuItem: anItem];
  [aCell setMenuView: self];

  if (index > 0)
    {
      [aCell setFont: _font];
    }
  else
    {
      [aCell setFont: [NSFont boldSystemFontOfSize: 0]];
    }

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

- (void) setFrame: (NSRect) r
{
  [super setFrame: r];
}

- (void) sizeToFit
{
  if (!_horizontal) // if we are not horizontal use the original code
    {
      [super sizeToFit];
      return;
    }
  else 
    {
      unsigned i;
      unsigned howMany = [_itemCells count];
      float currentX = 0;
      NSRect scRect = [[NSScreen mainScreen] frame];

      GSIArrayRemoveAllItems(_cellRects);

       // TODO - this is dirty - cannot set the menu bar width later
       // because the drawing disappears. Why? Have to figure it out...
      scRect.size.height = MenuBarHeight;
      scRect.size.width = 1024;
      [self setFrameSize: scRect.size];

      _cellSize.height = scRect.size.height;

      for (i = 0; i < howMany; i++)
	{
      	  GSCellRect elem;
      	  NSMenuItemCell *aCell = [_itemCells objectAtIndex: i];
	  float titleWidth = [aCell titleWidth];

	  if ([aCell keyEquivalentWidth])
	    {
              titleWidth += [aCell keyEquivalentWidth] + GSCellTextImageXDist;
	    }

	  elem.rect = NSMakeRect (currentX, 0,
                             (titleWidth + (2 * _horizontalEdgePad)),
                             _cellSize.height);
  	  GSIArrayAddItem(_cellRects, (GSIArrayItem)elem);

	  currentX += titleWidth + (2 * _horizontalEdgePad);
	}

      scRect.size.width = currentX;
      scRect.size.width += 2;
      [self setFrameSize: scRect.size];
    }
}

- (NSRect) rectOfItemAtIndex: (int)index
{
  GSCellRect aRect;

  if (_needsSizing == YES)
    {
      [self sizeToFit];
    } 

  aRect = GSIArrayItemAtIndex(_cellRects, index).ext;

  aRect.rect.origin.x += 1;

  return aRect.rect;
}

/* This method is an exception and returns a non-autoreleased
   dictionary, so that calling methods can deallocate it immediately
   using release.  Otherwise if many cells are drawn/their size
   computed, we pile up hundreds or thousands of these objects before they 
   are deallocated at the end of the run loop. */
- (NSDictionary*) menuTextAttributes
{
  NSDictionary *attr;
  NSColor *color;
  NSMutableParagraphStyle *paragraphStyle;

  color = [NSColor blackColor];
  /* Note: there are only 6 possible paragraph styles for cells.  
     TODO: Create them once at the beginning, and reuse them for the whole 
     app lifetime. */
  paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];

      [paragraphStyle setLineBreakMode: NSLineBreakByClipping];

  [paragraphStyle setAlignment: NSCenterTextAlignment];

  attr = [[NSDictionary alloc] initWithObjectsAndKeys: 
                                   [NSFont boldSystemFontOfSize: 0], NSFontAttributeName,
			       color, NSForegroundColorAttributeName,
			       paragraphStyle, NSParagraphStyleAttributeName,
			       nil];
  RELEASE (paragraphStyle);
  return [attr autorelease];
}

- (void) drawRect: (NSRect)rect
{
  static NSImage * menuBackgroundImage = nil;
  static float imageStep;

  int        i;
  int        howMany = [_itemCells count];
  NSRectEdge sides[] = {NSMinYEdge, NSMinYEdge};  
  float      grays[] = {NSBlack, NSDarkGray};
  float offset;

  NSDrawTiledRects(_bounds, rect, sides, grays, 2);

  if (menuBackgroundImage == nil)
    {
      ASSIGN(menuBackgroundImage, FindImageInBundle(self, @"MenuBarFiller"));

      imageStep = [menuBackgroundImage size].width;

       // handle the case in which the image isn't available so we don't
       // end up in an endless loop here
      if (imageStep <= 0)
        {
          imageStep = 100;
        }
    }

  // tile the menu background image on the background
  for (offset = NSMinX(rect); offset < NSMaxX(rect); offset += imageStep)
    {
      [menuBackgroundImage compositeToPoint: NSMakePoint(offset, 0)
                                  operation: NSCompositeCopy];
    }

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

  NSRect myFrame = [self frame];

  [[NSColor colorWithCalibratedWhite: 0.67 alpha: 0.3] set];
  PSmoveto(0, 1);
  PSrlineto(0, NSHeight(myFrame));
  PSstroke();

  [[NSColor colorWithCalibratedWhite: 1.0 alpha: 0.35] set];
  PSmoveto(NSMaxX(myFrame) - 1, 1);
  PSrlineto(0, NSHeight(myFrame));
  PSstroke();
}

- (void) update
{
  [self sizeToFit];
}

@end
