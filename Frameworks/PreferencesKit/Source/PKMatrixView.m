/*
	PKMatrixView.m
 
	Matrix view enclosed in a scroll view (with pane displayed in a content subview)
 
	Copyright (C) 2005 Yen-Ju Chen, Quentin Mathe 
 
	Author:  Yen-Ju Chen
	Date:  December 2005
 
	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.
 
	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
	Lesser General Public License for more details.
 
	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import "PKMatrixView.h"
#import "GNUstep.h"

@implementation PKMatrixView

- (id) initWithFrame: (NSRect) frame
       numberOfButtons: (int) c
{
  self = [super initWithFrame: frame];
    
  NSRect rect = NSZeroRect;
  count = c;
    
  matrix = [[NSMatrix alloc] initWithFrame: NSMakeRect(0, 0, 64*30, 64)
                             mode: NSRadioModeMatrix
                             cellClass: [NSButtonCell class]
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
  RELEASE(scrollView);
  RELEASE(contentView);
  RELEASE(matrix);
    
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

- (BOOL) isFlipped
{
  return YES;
}

@end
