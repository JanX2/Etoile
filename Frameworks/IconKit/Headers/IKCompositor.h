/*
	IKCompositor.h

	IconKit compositor core class which implements compositing facilities with 
	NSImage class

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
#import <IconKit/IKCompositorOperation.h>

@interface IKCompositor : NSObject
{
    NSSize originalSize;
    NSSize compositingSize;
    NSMutableArray *operations;
}

- (id) initWithSize: (NSSize)size;
- (id) initWithImage: (NSImage *)image;
- (id) initWithPropertyList: (NSDictionary *)plist;

- (NSSize) size;
- (NSSize) compositingSize;
- (void) setCompositingSize: (NSSize)size;

- (void) compositeImage: (NSImage *)source 
           withPosition: (IKCompositedImagePosition)position;
- (void) compositeImage: (NSImage *)source 
                 inRect: (NSRect)rect;

- (void) compositeImage: (NSImage *)source 
           withPosition: (IKCompositedImagePosition)position
              operation: (NSCompositingOperation)op 
                  alpha: (float)a;
- (void) compositeImage: (NSImage *)source 
                 inRect: (NSRect)rect
              operation: (NSCompositingOperation)op 
                  alpha: (float)a;

- (NSImage *) render;
- (NSDictionary *) propertyList;

@end
