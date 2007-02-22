/*
**  ImageTextCell.m
**
**  Copyright (c) 2003-2004
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**
**  This program is free software; you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation; either version 2 of the License, or
**  (at your option) any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU General Public License
**  along with this program; if not, write to the Free Software
**  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include "ImageTextCell.h"

#include <math.h>

//
//
//
@implementation ImageTextCell

- (void) dealloc 
{
  DESTROY(_image);
  [super dealloc];
}


- (id) copyWithZone: (NSZone *) theZone 
{
  ImageTextCell *aCell;

  aCell = [[ImageTextCell alloc] init];
  [aCell setImage: _image];
  
  return aCell;
}


//
//
//
- (void) setImage: (NSImage *) theImage 
{
  if (theImage)
    {
      ASSIGN(_image, theImage);
    }
  else
    {
      DESTROY(_image);
    }
}


//
//
//
- (void) drawWithFrame: (NSRect) theFrame 
		inView: (NSView *) theView 
{
  if (_image) 
    {
      NSRect aFrame;
      NSSize aSize;
      
      aSize = [_image size];
      NSDivideRect(theFrame, &aFrame, &theFrame, 3+aSize.width, NSMinXEdge);
      
      if ([self drawsBackground]) 
	{
	  [[self backgroundColor] set];
	  NSRectFill(aFrame);
	}
      
      aFrame.size = aSize;
      
      if ([theView isFlipped])
	{
	  aFrame.origin.y += ceil((theFrame.size.height + aFrame.size.height) / 2);
	}
      else
	{
	  aFrame.origin.y += ceil((theFrame.size.height - aFrame.size.height) / 2);
	}
      
      [_image compositeToPoint: aFrame.origin 
	      operation: NSCompositeSourceOver];
    }
  
  [super drawWithFrame: theFrame 
	 inView: theView];
}


//
//
//
- (NSSize) cellSize 
{
  NSSize aSize;
  
  aSize = [super cellSize];
  aSize.width += (_image ? [_image size].width : 0);// + 3;
  
  return aSize;
}


//
//
//
- (BOOL) isEditable
{
  return YES;
}


//
//
//
- (BOOL) isSelectable
{
  return YES;
}

@end
