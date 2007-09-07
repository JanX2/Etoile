/*
	IKCompositorOperation.h

	IKCompositor helper class that represents the operations which can be combined 
	and applied with the Icon Kit compositor

	Copyright (C) 2004 Nicolas Roard <nicolas@roard.com>
	                   Quentin Mathe <qmathe@club-internet.fr>	                   

	Author:   Nicolas Roard <nicolas@roard.com>
	          Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2004

    This application is free software; you can redistribute it and/or 
    modify it under the terms of the 3-clause BSD license. See COPYING.
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

typedef enum _IKCompositedImagePosition
{
  IKCompositedImagePositionCenter,
  IKCompositedImagePositionLeft,
  IKCompositedImagePositionTopLeft,
  IKCompositedImagePositionTop,
  IKCompositedImagePositionTopRight,
  IKCompositedImagePositionRight,
  IKCompositedImagePositionBottomRight,
  IKCompositedImagePositionBottom,
  IKCompositedImagePositionBottomLeft,
} IKCompositedImagePosition;
  
@interface IKCompositorOperation : NSObject
{
    NSImage *image;
    NSString *path;
    IKCompositedImagePosition position;
    NSCompositingOperation operation;
    NSRect rect;
    float alpha;
}

- (id) initWithPropertyList: (NSDictionary *)propertyList;
- (id) initWithImage: (NSImage *)image
            position: (IKCompositedImagePosition)position
           operation: (NSCompositingOperation)operation 
               alpha: (float) alpha;
- (id) initWithImage: (NSImage *)image
            rect: (NSRect)rect 
           operation: (NSCompositingOperation)operation  
               alpha: (float) alpha;
- (NSImage*) image;
- (IKCompositedImagePosition) position;
- (NSCompositingOperation) operation;
- (float) alpha;
- (NSRect) rect;
- (void) setImage: (NSImage *)image;
- (void) setPosition: (IKCompositedImagePosition)position;
- (void) setOperation: (NSCompositingOperation)operation;
- (void) setAlpha: (float)alpha;
- (void) setRect: (NSRect)rect;
- (NSDictionary *) propertyList;

@end
