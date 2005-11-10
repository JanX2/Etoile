#include "GSBrowserMatrix.h"

@implementation GSBrowserMatrix

- (BOOL) drawAlternateRows { return YES; }
- (float) alternateRowHeight { return _cellSize.height; }
- (void) drawRect: (NSRect)rect
{
  int i, j;
  int row1, col1;       // The cell at the upper left corner
  int row2, col2;       // The cell at the lower right corner

  if (_drawsBackground)
    {
//      [_backgroundColor set];
//	[[NSColor blueColor] set];
//      NSRectFill(rect);
    }

  if (!_numRows || !_numCols)
    return;

  row1 = rect.origin.y / (_cellSize.height + _intercell.height);
  col1 = rect.origin.x / (_cellSize.width + _intercell.width);
  row2 = NSMaxY(rect) / (_cellSize.height + _intercell.height);
  col2 = NSMaxX(rect) / (_cellSize.width + _intercell.width);

  if (_rFlags.flipped_view == NO)
    {
      row1 = _numRows - row1 - 1;
      row2 = _numRows - row2 - 1;
    }

  if (row1 < 0)
    row1 = 0;
  else if (row1 >= _numRows)
    row1 = _numRows - 1;

  if (col1 < 0)
    col1 = 0;
  else if (col1 >= _numCols)
    col1 = _numCols - 1;

  if (row2 < 0)
    row2 = 0;
  else if (row2 >= _numRows)
    row2 = _numRows - 1;

  if (col2 < 0)
    col2 = 0;
  else if (col2 >= _numCols)
    col2 = _numCols - 1;

  /* Draw the cells within the drawing rectangle. */
  for (i = row1; i <= row2 && i < _numRows; i++)
    for (j = col1; j <= col2 && j < _numCols; j++)
      {
	  	// Test ...
	  	if (i % 2)
		{
	  		[[NSColor redColor] set];
		}
		else
		{
			[[NSColor greenColor] set];
		}
		//NSRectFill (rect);
        [self _drawCellAtRow: i column: j];
      }
}

@end
