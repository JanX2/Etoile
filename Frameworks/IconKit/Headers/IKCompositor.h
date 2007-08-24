/*
	IKCompositor.h

	IconKit compositor core class which implements compositing facilities with 
	NSImage class

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
