#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GNUstepGUI/GSTheme.h"
#include "GSDrawFunctions.h"

@interface NSTableView (theme) // declare some private methods used by gnustep..
- (void) _willDisplayCell: (NSCell*) cell
	   forTableColumn: (NSTableColumn *) tb
		      row: (int) index;
@end

@implementation NSTableView (theme)

@class GSTableCornerView;

- (id) initWithFrame: (NSRect)frameRect
{
	self = [super initWithFrame: frameRect];
	_drawsGrid        = YES;
	_rowHeight        = 16.0;
	_intercellSpacing = NSMakeSize (2.0, 3.0);
	ASSIGN (_gridColor, [NSColor gridColor]); 
	ASSIGN (_backgroundColor, [NSColor controlBackgroundColor]);
	ASSIGN (_tableColumns, [NSMutableArray array]);
	ASSIGN (_selectedColumns, [NSMutableIndexSet indexSet]);
	ASSIGN (_selectedRows, [NSMutableIndexSet indexSet]);
	_allowsEmptySelection = YES;
	_allowsMultipleSelection = NO;
	_allowsColumnSelection = YES;
	_allowsColumnResizing = YES;
	_allowsColumnReordering = YES;
	_autoresizesAllColumnsToFit = NO;
	_editedColumn = -1;
	_editedRow = -1;
	_selectedColumn = -1;
	_selectedRow = -1;
	_highlightedTableColumn = nil;
	_headerView = [NSTableHeaderView new];
	float height = [THEME ListHeaderHeight]; 
	[_headerView setFrameSize: NSMakeSize (frameRect.size.width, height)];
	[_headerView setTableView: self];
	_cornerView = [GSTableCornerView new];
	[self tile];
	return self;
}

- (void) highlightSelectionInClipRect: (NSRect)clipRect
{
  if (_selectingColumns == NO)
    {
      int selectedRowsCount;
      int row;
      int startingRow, endingRow;
      
      selectedRowsCount = [_selectedRows count];
      
      if (selectedRowsCount == 0)
	return;
      
      /* highlight selected rows */
      startingRow = [self rowAtPoint: NSMakePoint(0, NSMinY(clipRect))];
      endingRow   = [self rowAtPoint: NSMakePoint(0, NSMaxY(clipRect))];
      
      if (startingRow == -1)
	startingRow = 0;
      if (endingRow == -1)
	endingRow = _numberOfRows - 1;
      
      row = [_selectedRows indexGreaterThanOrEqualToIndex: startingRow];
      while ((row != NSNotFound) && (row <= endingRow))
	{
	  //NSHighlightRect(NSIntersectionRect([self rectOfRow: row],
	    //						 clipRect));
	  [[NSColor selectedRowBackgroundColor] set];
	  NSRectFill(NSIntersectionRect([self rectOfRow: row], clipRect));
	  row = [_selectedRows indexGreaterThanIndex: row];
	}	  
    }
  else // Selecting columns
    {
      unsigned int selectedColumnsCount;
      unsigned int column;
      int startingColumn, endingColumn;
      
      selectedColumnsCount = [_selectedColumns count];
      
      if (selectedColumnsCount == 0)
	return;
      
      /* highlight selected columns */
      startingColumn = [self columnAtPoint: NSMakePoint(NSMinX(clipRect), 0)];
      endingColumn = [self columnAtPoint: NSMakePoint(NSMaxX(clipRect), 0)];

      if (startingColumn == -1)
	startingColumn = 0;
      if (endingColumn == -1)
	endingColumn = _numberOfColumns - 1;

      column = [_selectedColumns indexGreaterThanOrEqualToIndex: startingColumn];
      while ((column != NSNotFound) && (column <= endingColumn))
	{
	  //NSHighlightRect(NSIntersectionRect([self rectOfColumn: column],
	  //				     clipRect));
	  [[NSColor selectedRowBackgroundColor] set];
	  NSRectFill(NSIntersectionRect([self rectOfColumn: column], clipRect));
	  column = [_selectedColumns indexGreaterThanIndex: column];
	}	  
    }
}

- (void) drawGridInClipRect: (NSRect)aRect
{
  float minX = NSMinX (aRect);
  float maxX = NSMaxX (aRect);
  float minY = NSMinY (aRect);
  float maxY = NSMaxY (aRect);
  int i;
  float x_pos;
  int startingColumn;
  int endingColumn;

  NSGraphicsContext *ctxt = GSCurrentContext ();
  float position;

  int startingRow    = [self rowAtPoint:
                               NSMakePoint (_bounds.origin.x, minY)];
  int endingRow      = [self rowAtPoint:
                               NSMakePoint (_bounds.origin.x, maxY)];

  /* Using columnAtPoint:, rowAtPoint: here calls them only twice 

     per drawn rect */
  x_pos = minX;
  i = 0;
  while ((i < _numberOfColumns) && (x_pos > _columnOrigins[i]))
    {
      i++;
    }
  startingColumn = (i - 1);

  x_pos = maxX;
  // Nota Bene: we do *not* reset i
  while ((i < _numberOfColumns) && (x_pos > _columnOrigins[i]))
    {
      i++;
    }
  endingColumn = (i - 1);

  if (endingColumn == -1)
    endingColumn = _numberOfColumns - 1;
  /*
  int startingColumn = [self columnAtPoint: 
                               NSMakePoint (minX, _bounds.origin.y)];
  int endingColumn   = [self columnAtPoint: 
                               NSMakePoint (maxX, _bounds.origin.y)];
  */
  DPSgsave (ctxt);
  DPSsetlinewidth (ctxt, 1);
  [_gridColor set];

  if (_numberOfRows > 0)
    {
      /* Draw horizontal lines */
      if (startingRow == -1)
        startingRow = 0;
      if (endingRow == -1)
        endingRow = _numberOfRows - 1;

      position = _bounds.origin.y;
      position += startingRow * _rowHeight;
      for (i = startingRow; i <= endingRow + 1; i++)
        {
          DPSmoveto (ctxt, minX, position);
          DPSlineto (ctxt, maxX, position);
          DPSstroke (ctxt);
          position += _rowHeight;
        }
    }

  if (_numberOfColumns > 0)
    {
      /* Draw vertical lines */
      if (startingColumn == -1)
        startingColumn = 0;
      if (endingColumn == -1)
        endingColumn = _numberOfColumns - 1;

      for (i = startingColumn; i <= endingColumn; i++)
        {
          DPSmoveto (ctxt, _columnOrigins[i], minY);
          DPSlineto (ctxt, _columnOrigins[i], maxY);
          DPSstroke (ctxt);
        }
      position =  _columnOrigins[endingColumn];
      position += [[_tableColumns objectAtIndex: endingColumn] width];
      /* Last vertical line must moved a pixel to the left */
      if (endingColumn == (_numberOfColumns - 1))
        position -= 1;
      DPSmoveto (ctxt, position, minY);
      DPSlineto (ctxt, position, maxY);
      DPSstroke (ctxt);
    }

  DPSgrestore (ctxt);
}

- (void) drawBackgroundInClipRect: (NSRect)clipRect
{
  // FIXME
 /*  
  [_backgroundColor set];
  NSRectFill (clipRect);
  */
 BOOL draw = YES;
 int i;
 for (i = 0; i < _bounds.size.height; i += _rowHeight)
 {
 	NSRect cell = NSMakeRect (_bounds.origin.x, _bounds.origin.y + i,
		_bounds.size.width, _rowHeight);
	if (draw)
	{	
		[[NSColor alternateRowBackgroundColor] set];
		draw = NO;
	}
	else
	{
		[[NSColor rowBackgroundColor] set];
		draw = YES;
	}
	NSRectFill (cell);
 }
}

- (BOOL) drawAlternateRows { return YES; }
- (float) alternateRowHeight { return _rowHeight; }

- (void) drawRect: (NSRect)aRect
{
  int startingRow; 
  int endingRow;
  int i;

  /* Draw background */
  [self drawBackgroundInClipRect: aRect];

  if ((_numberOfRows == 0) || (_numberOfColumns == 0))
    {
      return;
    }

  /* Draw selection */
  //    [self highlightSelectionInClipRect: aRect];

  /* Draw grid */
  if (_drawsGrid)
    {
      [self drawGridInClipRect: aRect];
    }
  
  /* Draw visible cells */
  /* Using rowAtPoint: here calls them only twice per drawn rect */
  startingRow = [self rowAtPoint: NSMakePoint (0, NSMinY (aRect))];
  endingRow   = [self rowAtPoint: NSMakePoint (0, NSMaxY (aRect))];

  if (startingRow == -1)
    {
      startingRow = 0;
    }
  if (endingRow == -1)
    {
      endingRow = _numberOfRows - 1;
    }
  //  NSLog(@"drawRect : %d-%d", startingRow, endingRow);
  {
    SEL sel = @selector(drawRow:clipRect:);
    IMP imp = [self methodForSelector: sel];

    NSRect localBackground;
    localBackground = aRect;
    localBackground.size.height = _rowHeight;
    localBackground.origin.y = _bounds.origin.y + (_rowHeight * startingRow);

    for (i = startingRow; i <= endingRow; i++)
      {
 //       [_backgroundColor set];
 //       NSRectFill (localBackground);
        [self highlightSelectionInClipRect: localBackground];
        if (_drawsGrid)
          {
            [self drawGridInClipRect: localBackground];
          }
        localBackground.origin.y += _rowHeight;
        (*imp)(self, sel, i, aRect);
      }

    if (NSMaxY(aRect) > NSMaxY(localBackground) - _rowHeight)
      {
 //       [_backgroundColor set];
        localBackground.size.height =
          aRect.size.height - aRect.origin.y + localBackground.origin.y;
 //       NSRectFill (localBackground);
      }
  }
}

- (void) drawRow: (int)rowIndex clipRect: (NSRect)clipRect
{
  int startingColumn;
  int endingColumn;
  NSTableColumn *tb;
  NSRect drawingRect;
  NSCell *cell;
  int i;
  float x_pos;

  if (_dataSource == nil)
    {
      return;
    }

  /* Using columnAtPoint: here would make it called twice per row per drawn
     rect - so we avoid it and do it natively */

  /* Determine starting column as fast as possible */
  x_pos = NSMinX (clipRect);
  i = 0;
  while ((i < _numberOfColumns) && (x_pos > _columnOrigins[i]))
    {
      i++;
    }
  startingColumn = (i - 1);

  if (startingColumn == -1)
    startingColumn = 0;

  /* Determine ending column as fast as possible */
  x_pos = NSMaxX (clipRect);
  // Nota Bene: we do *not* reset i
  while ((i < _numberOfColumns) && (x_pos > _columnOrigins[i]))
    {
      i++;
    }
  endingColumn = (i - 1);

  if (endingColumn == -1)
    endingColumn = _numberOfColumns - 1;
  /* Draw the row between startingColumn and endingColumn */
  for (i = startingColumn; i <= endingColumn; i++)
    {
      if (i != _editedColumn || rowIndex != _editedRow)
    {
      tb = [_tableColumns objectAtIndex: i];
      cell = [tb dataCellForRow: rowIndex];
      [self _willDisplayCell: cell
        forTableColumn: tb
        row: rowIndex];
      [cell setObjectValue: [_dataSource tableView: self
                         objectValueForTableColumn: tb
                         row: rowIndex]];
      drawingRect = [self frameOfCellAtColumn: i
                  row: rowIndex];
	  if ([_selectedRows containsIndex: rowIndex])
	  {
		if ([cell respondsToSelector: @selector(setTextColor:)])
		{
			[cell setHighlighted: YES];
			[(NSTextFieldCell *)cell setTextColor: [NSColor selectedRowTextColor]];
		}
	  }
	  else 
	  {
		[cell setHighlighted: NO]; 
		if ([cell respondsToSelector: @selector(setTextColor:)])
			[(NSTextFieldCell *)cell setTextColor: [NSColor rowTextColor]];
 	  }
      [cell drawWithFrame: drawingRect inView: self];
    }
    }
}



@end

