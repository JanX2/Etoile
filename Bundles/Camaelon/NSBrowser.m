#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GSDrawFunctions.h"
#include "GraphicToolbox.h"

//static float scrollerWidth; // == [NSScroller scrollerWidth]
#define NSBR_COLUMN_SEP 4
#define NSBR_VOFFSET 2
//#define NSBR_COLUMN_IS_VISIBLE(i) YES // JUST FOR TEST

@interface NSBrowserColumn : NSObject <NSCoding>
{
@public
  BOOL _isLoaded;
  id _columnScrollView;
  id _columnMatrix;
  NSString *_columnTitle;
}

- (void) setIsLoaded: (BOOL)flag;
- (BOOL) isLoaded;
- (void) setColumnScrollView: (id)aView;
- (id) columnScrollView;
- (void) setColumnMatrix: (id)aMatrix;
- (id) columnMatrix;
- (void) setColumnTitle: (NSString *)aString;
- (NSString *) columnTitle;
@end


@implementation NSBrowserColumn (theme)
/*
- (void) setColumnMatrix: (id)aMatrix
{
  ASSIGN(_columnMatrix, aMatrix);
  [_columnMatrix setBackgroundColor: [NSColor whiteColor]];
  //[_columnMatrix setDrawsBackground: YES];
}
- (id) columnMatrix
{
  [_columnMatrix setBackgroundColor: [NSColor whiteColor]];
  //[_columnMatrix setDrawsBackground: YES];
  return _columnMatrix;
}
*/
@end


@implementation NSBrowser (theme)

- (BOOL) isOpaque { return NO; }

- (void) drawRect: (NSRect)rect
{
//[[NSColor blueColor] set];
//NSRectFill (rect);
//return;
/*
  NSRectClip(rect);
  [[_window backgroundColor] set];
  NSRectFill(rect);
*/
//  [GSDrawFunctions drawWindowBackground: rect];

  // Load the first column if not already done
  if (!_isLoaded)
    {
      [self loadColumnZero];
    }

  //_isTitled = YES; // JUST FOR TEST :-)

  // Draws titles
  if (_isTitled)
    {
      int i;

      for (i = _firstVisibleColumn; i <= _lastVisibleColumn; ++i)
        {
          NSRect titleRect = [self titleFrameOfColumn: i];
          if (NSIntersectsRect (titleRect, rect) == YES)
            {
   	      [GSDrawFunctions drawBrowserHeaderInRect: titleRect];
              [self drawTitleOfColumn: i
                    inRect: titleRect];
            }
        }
    }
  
  // Draws scroller border
  if (_hasHorizontalScroller)
    {
      NSRect scrollerBorderRect = _scrollerRect;
      NSSize bs = _sizeForBorderType (NSBezelBorder);
  

      scrollerBorderRect.origin.x = 0;
      scrollerBorderRect.origin.y = 0; 
      scrollerBorderRect.size.width += 2 * bs.width - 1;
      scrollerBorderRect.size.height += (2 * bs.height) -1;

  [[NSColor colorWithCalibratedRed: 0.6 green: 0.6 blue: 0.6 alpha: 1.0] set];
  //[[NSColor redColor] set];
  NSRectFill(scrollerBorderRect);


      if ((NSIntersectsRect (scrollerBorderRect, rect) == YES) && _window)
        {
//      [GSDrawFunctions drawScrollViewFrame: scrollerBorderRect on: self];
        }
    }

/*
  if (!_separatesColumns)
    {
      NSPoint p1,p2;
      NSRect  browserRect;
      int     i, visibleColumns;
      float   hScrollerWidth = _hasHorizontalScroller ? [NSScroller scrollerWidth] : 0;
    
      // Columns borders
      browserRect = NSMakeRect(0, 0, rect.size.width, rect.size.height);
      NSDrawGrayBezel (browserRect, rect);

      [[NSColor blackColor] set];
      visibleColumns = [self numberOfVisibleColumns];
      for (i = 1; i < visibleColumns; i++)
        {
          p1 = NSMakePoint((_columnSize.width * i) + 2 + (i-1),
                           _columnSize.height + hScrollerWidth + 2);
          p2 = NSMakePoint((_columnSize.width * i) + 2 + (i-1),
                           hScrollerWidth + 2);
          [NSBezierPath strokeLineFromPoint: p1 toPoint: p2];
        }

      // Horizontal scroller border
      if (_hasHorizontalScroller)
        {
          p1 = NSMakePoint(2, hScrollerWidth + 2);
          p2 = NSMakePoint(rect.size.width - 2, hScrollerWidth + 2);
          [NSBezierPath strokeLineFromPoint: p1 toPoint: p2];
        }
    }
*/
}

- (void) tile
{
  NSSize bs = _sizeForBorderType (NSBezelBorder);
  int i, num, columnCount, delta;
  float  frameWidth;

  float scrollerWidth = [NSScroller scrollerWidth];

  _columnSize.height = _frame.size.height;

  // Titles (there is no real frames to resize)
  if (_isTitled)
    {
      _columnSize.height -= [self titleHeight] + NSBR_VOFFSET;
    }

  // Horizontal scroller
  if (_hasHorizontalScroller)
    {
      _scrollerRect.origin.x = bs.width - 1;
      //_scrollerRect.origin.y = bs.height - 1;
      _scrollerRect.origin.y = bs.height - 1;
      _scrollerRect.size.width = (_frame.size.width - (2 * bs.width)) + 2;
      _scrollerRect.size.height = scrollerWidth - 1;

      if (_separatesColumns)
        _columnSize.height -= (scrollerWidth - 1) + (2 * bs.height)
          + NSBR_VOFFSET;
      else
        _columnSize.height -= scrollerWidth + (2 * bs.height);

	_columnSize.height -= 2;

      if (!NSEqualRects(_scrollerRect, [_horizontalScroller frame]))
        {
          [_horizontalScroller setFrame: _scrollerRect];
        }
    }
  else
    {
      _scrollerRect = NSZeroRect;
      _columnSize.height -= 2 * bs.width;
    }
  num = _lastVisibleColumn - _firstVisibleColumn + 1;

  if (_minColumnWidth > 0)
    {
      float colWidth = _minColumnWidth + scrollerWidth;

      if (_separatesColumns)
        colWidth += NSBR_COLUMN_SEP;

      if (_frame.size.width > colWidth)
        {
          columnCount = (int)(_frame.size.width / colWidth);
        }
      else
        columnCount = 1;
    }
  else
    columnCount = num;

  if (_maxVisibleColumns > 0 && columnCount > _maxVisibleColumns)
    columnCount = _maxVisibleColumns;

  if (columnCount != num)
    {
      if (num > 0)
        delta = columnCount - num;
      else
        delta = columnCount - 1;

      if ((delta > 0) && (_lastVisibleColumn <= _lastColumnLoaded))
        {
          _firstVisibleColumn = (_firstVisibleColumn - delta > 0) ?
            _firstVisibleColumn - delta : 0;
        }

      for (i = [_browserColumns count]; i < columnCount; i++)
        [self _createColumn];

      _lastVisibleColumn = _firstVisibleColumn + columnCount - 1;
    }
  // Columns
  if (_separatesColumns)
    frameWidth = _frame.size.width - ((columnCount - 1) * NSBR_COLUMN_SEP);
  else
    frameWidth = _frame.size.width - (columnCount + (2 * bs.width));

  _columnSize.width = (int)(frameWidth / (float)columnCount);

  if (_columnSize.height < 0)
    _columnSize.height = 0;

  for (i = _firstVisibleColumn; i <= _lastVisibleColumn; i++)
    {
      id bc, sc;
      id matrix;

      // FIXME: in some cases the column is not loaded
      while (i >= [_browserColumns count]) [self _createColumn];

      bc = [_browserColumns objectAtIndex: i];

      if (!(sc = [bc columnScrollView]))
        {
          NSLog(@"NSBrowser error, sc != [bc columnScrollView]");
          return;
        }

      [sc setFrame: [self frameOfColumn: i]];
      matrix = [bc columnMatrix];

      // Adjust matrix to fit in scrollview if column has been loaded
      if (matrix && [bc isLoaded])
        {
          NSSize cs, ms;

          cs = [sc contentSize];
          ms = [matrix cellSize];
          ms.width = cs.width;
          [matrix setCellSize: ms];
          [sc setDocumentView: matrix];
        }
    }

  if (columnCount != num)
    {
      [self updateScroller];
      [self _remapColumnSubviews: YES];
      //      [self _setColumnTitlesNeedDisplay];
      [self setNeedsDisplay: YES];
    }
}

@class GSBrowserTitleCell;
/** Draws the title for the column at index column within the rectangle
    defined by aRect. */
- (void) drawTitle: (NSString *)title
            inRect: (NSRect)aRect
          ofColumn: (int)column
{
  if (!_isTitled)// || !NSBR_COLUMN_IS_VISIBLE(column))
    return;

  NSTextFieldCell* titleCell = [GSBrowserTitleCell new];
  [titleCell setStringValue: title];
  [titleCell drawWithFrame: aRect inView: self];
}



@end
