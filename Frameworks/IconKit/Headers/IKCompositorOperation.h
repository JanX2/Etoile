/*
	IKCompositorOperation.h

	IKCompositor helper class that represents the operations which can be combined 
	and applied with the Icon Kit compositor

	Copyright (C) 2004 Nicolas Roard <nicolas@roard.com>
	                   Quentin Mathe <qmathe@club-internet.fr>	                   

	Author:   Nicolas Roard <nicolas@roard.com>
	          Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2004

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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

typedef enum _IKCompositedIconPosition
{
  IKCompositedIconPositionCenter,
  IKCompositedIconPositionLeft,
  IKCompositedIconPositionTopLeft,
  IKCompositedIconPositionTop,
  IKCompositedIconPositionTopRight,
  IKCompositedIconPositionRight,
  IKCompositedIconPositionBottomRight,
  IKCompositedIconPositionBottom,
  IKCompositedIconPositionBottomLeft,
} IKCompositedIconPosition;
  
@interface IKCompositorOperation : NSObject
{
    NSImage *image;
    NSString *path;
    IKCompositedIconPosition position;
    NSCompositingOperation operation;
    NSRect rect;
    float alpha;
}

- (id) initWithPropertyList: (NSDictionary *)propertyList;
- (id) initWithImage: (NSImage *)image
            position: (IKCompositedIconPosition)position
           operation: (NSCompositingOperation)operation 
               alpha: (float) alpha;
- (id) initWithImage: (NSImage *)image
            rect: (NSRect)rect 
           operation: (NSCompositingOperation)operation  
               alpha: (float) alpha;
- (NSImage*) image;
- (IKCompositedIconPosition) position;
- (NSCompositingOperation) operation;
- (float) alpha;
- (NSRect) rect;
- (void) setImage: (NSImage *)image;
- (void) setPosition: (IKCompositedIconPosition)position;
- (void) setOperation: (NSCompositingOperation)operation;
- (void) setAlpha: (float)alpha;
- (void) setRect: (NSRect)rect;
- (NSDictionary *) propertyList;

@end
