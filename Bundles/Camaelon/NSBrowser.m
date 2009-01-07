#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GSDrawFunctions.h"
#include "GraphicToolbox.h"
#import "GSBrowserMatrix.h"

//static float scrollerWidth; // == [NSScroller scrollerWidth]
#define NSBR_COLUMN_SEP 4
#define NSBR_VOFFSET 2
//#define NSBR_COLUMN_IS_VISIBLE(i) YES // JUST FOR TEST

@class GSBrowserTitleCell;

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

@interface NSBrowser (gsprivate) // declare some private methods used by gnustep..
- (NSBrowserColumn*) _createColumn;
- (void) _remapColumnSubviews: (BOOL) flag;
@end

@implementation NSBrowserColumn (theme)
- (id) initWithCoder: (NSCoder *)aDecoder
{
  int dummy = 0;

  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_isLoaded];
  _columnScrollView = [aDecoder decodeObject];
  if (_columnScrollView)
    RETAIN(_columnScrollView);
  _columnMatrix = [aDecoder decodeObject];
  _columnMatrix = (GSBrowserMatrix*) _columnMatrix;
  if (_columnMatrix)
    RETAIN(_columnMatrix);
  [aDecoder decodeValueOfObjCType: @encode(int) at: &dummy];
  _columnTitle = [aDecoder decodeObject];
  if (_columnTitle)
    RETAIN(_columnTitle);
  return self;
}

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

static NSTextFieldCell *titleCell;

@implementation NSBrowser (theme)
- (id) initWithFrame: (NSRect)rect
{
  NSSize bs;
  //NSScroller *hs;
  float scrollerWidth = [NSScroller scrollerWidth];

  /* Created the shared titleCell if it hasn't been created already. */
  if (!titleCell)
    {
      titleCell = [GSBrowserTitleCell new];
    }

  self = [super initWithFrame: rect];

  // Class setting
  _browserCellPrototype = [[[NSBrowser cellClass] alloc] init];
  _browserMatrixClass = [GSBrowserMatrix class];

  // Default values
  _pathSeparator = @"/";
  _allowsBranchSelection = YES;
  _allowsEmptySelection = YES;
  _allowsMultipleSelection = YES;
  _reusesColumns = NO;
  _separatesColumns = YES;
  _isTitled = YES;
  _takesTitleFromPreviousColumn = YES;
  _hasHorizontalScroller = YES;
  _isLoaded = NO;
  _acceptsArrowKeys = YES;
  _acceptsAlphaNumericalKeys = YES;
  _lastKeyPressed = 0.;
  _charBuffer = nil;
  _sendsActionOnArrowKeys = YES;
  _sendsActionOnAlphaNumericalKeys = YES;
  _browserDelegate = nil;
  _passiveDelegate = YES;
  _doubleAction = NULL;
  bs = [[GSTheme theme] sizeForBorderType: NSBezelBorder];
  _minColumnWidth = scrollerWidth + (2 * bs.width);
  if (_minColumnWidth < 100.0)
    _minColumnWidth = 100.0;

  // Horizontal scroller
  _scrollerRect.origin.x = bs.width;
  _scrollerRect.origin.y = bs.height;
  _scrollerRect.size.width = _frame.size.width - (2 * bs.width);
  _scrollerRect.size.height = scrollerWidth;
  _horizontalScroller = [[NSScroller alloc] initWithFrame: _scrollerRect];
  [_horizontalScroller setTarget: self];
  [_horizontalScroller setAction: @selector(scrollViaScroller:)];
  [self addSubview: _horizontalScroller];
  _skipUpdateScroller = NO;

  // Columns
  _browserColumns = [[NSMutableArray alloc] init];

  // Create a single column
  _lastColumnLoaded = -1;
  _firstVisibleColumn = 0;
  _lastVisibleColumn = 0;
  _maxVisibleColumns = 3;
  [self _createColumn];

  return self;
}

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
//  [THEME drawWindowBackground: rect];

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
   	      [THEME drawBrowserHeaderInRect: titleRect];
              [self drawTitleOfColumn: i
                    inRect: titleRect];
            }
        }
    }
  
  // Draws scroller border
  if (_hasHorizontalScroller)
    {
      NSRect scrollerBorderRect = _scrollerRect;
      NSSize bs = [[GSTheme theme] sizeForBorderType: NSBezelBorder];
  

      scrollerBorderRect.origin.x = 0;
      scrollerBorderRect.origin.y = 0; 
      scrollerBorderRect.size.width += 2 * bs.width - 1;
      scrollerBorderRect.size.height += (2 * bs.height) -1;

  [[NSColor colorWithCalibratedRed: 0.6 green: 0.6 blue: 0.6 alpha: 1.0] set];
  //[[NSColor redColor] set];
  NSRectFill(scrollerBorderRect);


      if ((NSIntersectsRect (scrollerBorderRect, rect) == YES) && _window)
        {
//      [THEME drawScrollViewFrame: scrollerBorderRect on: self];
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
  NSSize bs = [[GSTheme theme] sizeForBorderType: NSBezelBorder];
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
