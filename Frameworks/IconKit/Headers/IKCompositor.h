/*
	IKCompositor.h

	IconKit compositor core class which implements compositing facilities with 
	NSImage class

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
#import "IKCompositorOperation.h"

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
           withPosition: (IKCompositedIconPosition)position;
- (void) compositeImage: (NSImage *)source 
                 inRect: (NSRect)rect;

- (void) compositeImage: (NSImage *)source 
           withPosition: (IKCompositedIconPosition)position
              operation: (NSCompositingOperation)op 
                  alpha: (float)a;
- (void) compositeImage: (NSImage *)source 
                 inRect: (NSRect)rect
              operation: (NSCompositingOperation)op 
                  alpha: (float)a;

- (NSImage *) render;
- (NSDictionary *) propertyList;

@end
