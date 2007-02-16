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

#include "GSHorizontalMenuView.h"

#include <Foundation/Foundation.h>

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
  zone = GSObjCZone(self);
  _cellRects = NSZoneMalloc(zone, sizeof(GSIArray_t));
  GSIArrayInitWithZoneAndCapacity(_cellRects, zone, 8);

  return self;
}

- (void) dealloc
{
  GSIArrayEmpty(_cellRects);
  NSZoneFree(GSObjCZone(self), _cellRects);
  [super dealloc];
}

- (void) setMenu: (NSMenu*)menu
{
  [super setMenu: menu];

  {
    /* regenerate all the necessary cells */
    int i;
    for (i = 0; i < [[[self menu] itemArray] count]; i++)
      {
  	NSDictionary *d = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: i]
          forKey: @"NSMenuItemIndex"];

        [self itemAdded: [NSNotification
                 notificationWithName: NSMenuDidAddItemNotification
                 object: self
                 userInfo: d]];
      }
  }
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
//  [aCell setFont: _font];

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
  if (!_horizontal) // if we are not horizontal use the original code
    {
      [super sizeToFit];
      return;
    }
  else 
    {
      unsigned i;
      unsigned howMany = [_itemCells count];
      float currentX = 8;
      NSRect scRect = [[NSScreen mainScreen] frame];

      GSIArrayRemoveAllItems(_cellRects);

      scRect.size.height = [NSMenuView menuBarHeight];
      [self setFrameSize: scRect.size];
      _cellSize.height = scRect.size.height;

      for (i = 0; i < howMany; i++)
	{
      	  GSCellRect elem;
      	  NSMenuItemCell *aCell = [_itemCells objectAtIndex: i];
	  float titleWidth = [aCell titleWidth];

	  if ([aCell imageWidth])
	    {
	      titleWidth += [aCell imageWidth] + GSCellTextImageXDist;
	    }

	  elem.rect = NSMakeRect (currentX,
			     0,
			     (titleWidth + (2 * _horizontalEdgePad)),
			     _cellSize.height);
  	  GSIArrayAddItem(_cellRects, (GSIArrayItem)elem);

	  currentX += titleWidth + (2 * _horizontalEdgePad);
	}
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

  /* FIXME: handle vertical case? */

  return aRect.rect;
}

- (void) drawRect: (NSRect)rect
{
  int        i;
  int        howMany = [_itemCells count];
  NSRectEdge sides[] = {NSMinYEdge, NSMinYEdge};  
  float      grays[] = {NSBlack, NSDarkGray};

  NSDrawTiledRects(_bounds, rect, sides, grays, 2);

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
}
@end
