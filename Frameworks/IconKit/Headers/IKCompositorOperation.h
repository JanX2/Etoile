/*
	IKCompositorOperation.h

	IKCompositor helper class that represents the operations which can be combined 
	and applied with the Icon Kit compositor

	Copyright (C) 2004 Nicolas Roard <nicolas@roard.com>
	                   Quentin Mathe <qmathe@club-internet.fr>	                   

	Author:   Nicolas Roard <nicolas@roard.com>
	          Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2004

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	1. Redistributions of source code must retain the above copyright notice,
	   this list of conditions and the following disclaimer.
	2. Redistributions in binary form must reproduce the above copyright notice,
	   this list of conditions and the following disclaimer in the documentation
	   and/or other materials provided with the distribution.
	3. The name of the author may not be used to endorse or promote products
	   derived from this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
	WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
	MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
	EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
	EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
	OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
	IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
	OF SUCH DAMAGE.
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
