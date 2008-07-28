#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "NSColor.h"

//static NSNotificationCenter *nc = nil;
static const int current_version = 1;
static NSImage *collapsed = nil;
static NSImage *unexpandable = nil;
static NSImage *expanded  = nil;

@interface NSOutlineView (gstheme) // declare some private methods used by gnustep..
- (void) _willDisplayCell: (NSCell*) cell
	   forTableColumn: (NSTableColumn *) tb
		      row: (int) index;
@end

@implementation NSOutlineView (theme)

- (void)drawRow: (int)rowIndex clipRect: (NSRect)aRect
{
  int startingColumn; 
  int endingColumn;
  NSTableColumn *tb;
  NSRect drawingRect;
  NSCell *cell;
  NSCell *imageCell = nil;
  NSRect imageRect;
  int i; 
  float x_pos;

  if (collapsed == nil) collapsed = [NSImage imageNamed: @"common_outlineCollapsed.tiff"];
  if (expanded == nil) expanded = [NSImage imageNamed: @"common_outlineExpanded.tiff"];
  if (unexpandable == nil) unexpandable = [NSImage imageNamed: @"common_outlineUnexpandable.tiff"];

  if (_dataSource == nil)
    {
      return;
    }

  // Using columnAtPoint: here would make it called twice per row per drawn
  //   rect - so we avoid it and do it natively 

  if(rowIndex >= _numberOfRows)
    {
      return;
    }

  // Determine starting column as fast as possible 
  
  x_pos = NSMinX (aRect);
  i = 0;
  while ((x_pos > _columnOrigins[i]) && (i < _numberOfColumns))
    {
      i++;
    }
  startingColumn = (i - 1);

  if (startingColumn == -1)
    startingColumn = 0;

  // Determine ending column as fast as possible 

  x_pos = NSMaxX (aRect);
  // Nota Bene: we do *not* reset i
  while ((x_pos > _columnOrigins[i]) && (i < _numberOfColumns))
    {
      i++;
    }
  endingColumn = (i - 1);

  if (endingColumn == -1)
    endingColumn = _numberOfColumns - 1;

  // Draw the row between startingColumn and endingColumn 

  for (i = startingColumn; i <= endingColumn; i++)
    {
      if (i != _editedColumn || rowIndex != _editedRow)
    {
      id item = [self itemAtRow: rowIndex];

      tb = [_tableColumns objectAtIndex: i];
      cell = [tb dataCellForRow: rowIndex];
      [self _willDisplayCell: cell
        forTableColumn: tb
        row: rowIndex];
      [cell setObjectValue: [_dataSource outlineView: self
                         objectValueForTableColumn: tb
                         byItem: item]];
      drawingRect = [self frameOfCellAtColumn: i
                  row: rowIndex];

      if(tb == _outlineTableColumn)
        {
          NSImage *image = nil;
          int level = 0;
          float indentationFactor = 0.0;
          // float originalWidth = drawingRect.size.width;

          // display the correct arrow...
          if([self isItemExpanded: item])
        {
          image = expanded;
        }
          else
        {
          image = collapsed;
        }

          if(![self isExpandable: item])
        {
          image = unexpandable;
        }
         level = [self levelForItem: item];
          indentationFactor = _indentationPerLevel * level;
          imageCell = [[NSCell alloc] initImageCell: image];

          if(_indentationMarkerFollowsCell)
        {
          imageRect.origin.x = drawingRect.origin.x + indentationFactor;
          imageRect.origin.y = drawingRect.origin.y;
        }
          else
        {
          imageRect.origin.x = drawingRect.origin.x;
          imageRect.origin.y = drawingRect.origin.y;
        }

          if ([_delegate respondsToSelector: @selector(outlineView:willDisplayOutlineCell:forTableColumn:item:)])
        {
          [_delegate outlineView: self
                 willDisplayOutlineCell: imageCell
                 forTableColumn: tb
                 item: item];
        }

          // Do not indent if the delegate set the image to nil. 

          if ( [imageCell image] )
        {
          imageRect.size.width = [image size].width;
          imageRect.size.height = [image size].height;
          [imageCell drawWithFrame: imageRect inView: self];
          drawingRect.origin.x += indentationFactor + [image size].width + 5;
          drawingRect.size.width -= indentationFactor + [image size].width + 5;
        }
          else
        {
          drawingRect.origin.x += indentationFactor;
          drawingRect.size.width -= indentationFactor;
        }

          RELEASE(imageCell);
        }

	  if ([_selectedRows containsIndex: rowIndex])
	  {
		if ([cell respondsToSelector: @selector(setTextColor:)])
		{
//			[cell setHighlighted: YES];
			[(NSTextFieldCell *)cell setTextColor: [NSColor selectedRowTextColor]];
		}
	  }
	  else 
	  {
		//[cell setHighlighted: NO]; 
		if ([cell respondsToSelector: @selector(setTextColor:)])
			[(NSTextFieldCell *)cell setTextColor: [NSColor rowTextColor]];
 	  }
      [cell drawWithFrame: drawingRect inView: self];
    }
    }
}



@end
