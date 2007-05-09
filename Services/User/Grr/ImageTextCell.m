/*
**  ImageTextCell.m
**
**  Copyright (c) 2003-2004
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**
**
**  This application is free software; you can redistribute it and/or 
**  modify it under the terms of the MIT license. See COPYING.
**
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
