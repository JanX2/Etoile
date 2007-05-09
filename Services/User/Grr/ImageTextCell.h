/*
**  ImageTextCell.h
**
**  Copyright (c) 2003-2004
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**
**
**  This application is free software; you can redistribute it and/or 
**  modify it under the terms of the MIT license. See COPYING.
*/

#ifndef _GNUMail_H_ImageTextCell
#define _GNUMail_H_ImageTextCell

#import <AppKit/AppKit.h>

@interface ImageTextCell : NSTextFieldCell
{
  NSImage *_image;
}

- (void) setImage: (NSImage *) theImage;
- (void) drawWithFrame: (NSRect) theFrame 
               inView: (NSView *) theView;
- (NSSize) cellSize;

@end

#endif // _GNUMail_H_ImageTextCell
