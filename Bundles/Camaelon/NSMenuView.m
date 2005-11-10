#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GSDrawFunctions.h"

@implementation NSMenuView (theme)
- (void) setNeedsDisplayForItemAtIndex: (int)index
{
  NSRect aRect;

  aRect = [self rectOfItemAtIndex: index];
  //aRect = _addLeftBorderOffsetToRect(aRect);
  [self setNeedsDisplayInRect: _bounds];
}
- (void) drawRect: (NSRect)rect
{
  int        i;
  int        howMany = [_itemCells count];
  NSRectEdge sides[] = {NSMinXEdge, NSMaxYEdge};
  float      grays[] = {NSDarkGray, NSDarkGray};

  // Draw the dark gray upper left lines.
  //NSDrawTiledRects(rect, rect, sides, grays, 2);
//  [[NSColor clearColor] set];
//  NSRectFillUsingOperation (rect, NSCompositeClear);
  [THEME drawMenu: rect inView: self];

  // Draw the menu cells.
  for (i = 0; i < howMany; i++)
    {
      NSRect            aRect;
      NSMenuItemCell    *aCell;

      aRect = [self rectOfItemAtIndex: i];
      if (NSIntersectsRect(rect, aRect) == YES)
        {
          aCell = [_itemCells objectAtIndex: i];
          [aCell drawInteriorWithFrame: aRect inView: self];
        }
    }
}
@end
