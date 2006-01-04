#include "PKMatrixView.h"

@implementation PKMatrixView

- (id) initWithFrame: (NSRect) frame
       numberOfButtons: (int) c
{
  self = [super initWithFrame: frame];
  NSRect rect = NSZeroRect;
  count = c;

  matrix = [[NSMatrix alloc] initWithFrame: NSMakeRect(0, 0, 64*30, 64)
	mode: NSRadioModeMatrix cellClass: [NSButtonCell class]
	numberOfRows: 1 numberOfColumns: 0];
  [matrix setCellSize: NSMakeSize(64, 64)];
  [matrix setIntercellSpacing: NSZeroSize];
  [matrix setAllowsEmptySelection: YES];

  rect.size = [NSScrollView frameSizeForContentSize: [matrix bounds].size
                       hasHorizontalScroller: YES
                       hasVerticalScroller: NO
                       borderType: NSBezelBorder];
  scrollView = [[NSScrollView alloc] initWithFrame: rect];
  [scrollView setDocumentView: matrix];
  [scrollView setHasHorizontalScroller: YES];
  [scrollView setHasVerticalScroller: NO];
  [scrollView setAutoresizingMask: NSViewWidthSizable];
  [scrollView setBorderType: NSBezelBorder];
  [self addSubview: scrollView];

  contentView = [[NSView alloc] initWithFrame: NSMakeRect(0, rect.size.height, frame.size.width, frame.size.height-rect.size.height)];
  [contentView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
  [self addSubview: contentView];

  return self;
}

- (NSSize) frameSizeForContentSize: (NSSize) size
{
  NSSize s = size;
  s.height += [scrollView bounds].size.height;
  return s;
}

- (void) addButtonCell: (NSButtonCell *) button
{
  [matrix addColumnWithCells: [NSArray arrayWithObject: button]];
  [matrix sizeToCells];
}

- (NSButtonCell *) selectedButtonCell
{
  return [matrix selectedCell];
}

- (NSView *) contentView
{
	return contentView;
}

- (void) resizeWithOldSuperviewSize: (NSSize) oldBoundsSize
{

  NSRect rect = [scrollView frame];
  rect.size.width = [self bounds].size.width;
  rect.origin.y = rect.size.height;
  rect.size.height = [self bounds].size.height-rect.origin.y;
  [contentView setFrame: rect];
}

- (BOOL) isFlipped
{
  return YES;
}

@end
