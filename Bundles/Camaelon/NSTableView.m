#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GNUstepGUI/GSDrawFunctions.h"

@interface GSDrawFunctions (theme)
+ (float) ListHeaderHeight;
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
	float height = [GSDrawFunctions ListHeaderHeight]; 
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
	  NSHighlightRect(NSIntersectionRect([self rectOfColumn: column],
					     clipRect));
	  column = [_selectedColumns indexGreaterThanIndex: column];
	}	  
    }
}

@end

