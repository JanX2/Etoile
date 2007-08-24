/*
	IKCompositorOperation.m

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

#import "IKCompat.h"
#import <IconKit/IKCompositorOperation.h>

@implementation IKCompositorOperation

- (void) dealloc
{
	[image release];
	[path release];
	[super dealloc];
}

- (id) initWithPropertyList: (NSDictionary *)propertyList
{
	NSNumber* number = nil;
	NSDictionary* rectangle = nil;

	path = [propertyList objectForKey: @"path"];
	[path retain];

	if (path != nil) image = [[NSImage alloc] initWithContentsOfFile: path];

	number = [propertyList objectForKey: @"position"];
	if (number != nil) position = [number intValue];

	number = [propertyList objectForKey: @"operation"];
	if (number != nil) operation = [number intValue];

	rectangle = [propertyList objectForKey: @"rectangle"];
	if (rectangle != nil)
	{
		float x, y, width, height;

		number = [rectangle objectForKey: @"x"];
		if (number != nil) x = [number floatValue];		

		number = [rectangle objectForKey: @"y"];
		if (number != nil) y = [number floatValue];		

		number = [rectangle objectForKey: @"width"];
		if (number != nil) width = [number floatValue];		

		number = [rectangle objectForKey: @"height"];
		if (number != nil) height = [number floatValue];		

		rect = NSMakeRect (x, y, width, height);
	}

	number = [propertyList objectForKey: @"alpha"];
	if (number != nil) alpha = [number floatValue];

	return self;
}

- (id) initWithImage: (NSImage *)anImage
            position: (IKCompositedImagePosition)aPosition
           operation: (NSCompositingOperation)anOperation 
               alpha: (float) anAlpha
{
	ASSIGN (image, anImage);
	position = aPosition;
	operation = anOperation;
	alpha = anAlpha;

	return self;
}

- (id) initWithImage: (NSImage *)anImage
                rect: (NSRect)aRect 
           operation: (NSCompositingOperation)anOperation  
               alpha: (float)anAlpha
{
	ASSIGN (image, anImage);
	rect = aRect;
	operation = anOperation;
	alpha = anAlpha;

	return self;
}

- (NSImage *) image { return image; }

- (IKCompositedImagePosition) position { return position; }

- (NSCompositingOperation) operation { return operation; }

- (float) alpha { return alpha; }

- (NSRect) rect { return rect; }

- (void) setImage: (NSImage *)anImage { ASSIGN (image, anImage); }

- (void) setPosition: (IKCompositedImagePosition)aPosition { position = aPosition; }

- (void) setOperation: (NSCompositingOperation)anOperation { operation = anOperation; }

- (void) setAlpha: (float)anAlpha { alpha = anAlpha; }

- (void) setRect: (NSRect)aRect { rect = aRect; }

- (NSDictionary *) propertyList
{
	NSMutableDictionary* dictionary = [[NSMutableDictionary alloc] init];
	NSMutableDictionary* dictRect = [[NSMutableDictionary alloc] init];
	if (path != nil) [dictionary setObject: path forKey: @"path"];
	[dictionary setObject: [NSNumber numberWithInt: position] forKey: @"position"];
	[dictionary setObject: [NSNumber numberWithInt: operation] forKey: @"operation"];
	[dictRect setObject: [NSNumber numberWithFloat: rect.origin.x] forKey: @"x"];
	[dictRect setObject: [NSNumber numberWithFloat: rect.origin.y] forKey: @"y"];
	[dictRect setObject: [NSNumber numberWithFloat: rect.size.width] forKey: @"width"];
	[dictRect setObject: [NSNumber numberWithFloat: rect.size.height] forKey: @"height"];
	[dictionary setObject: dictRect forKey: @"rectangle"];
	[dictionary setObject: [NSNumber numberWithFloat: alpha] forKey: @"alpha"];
	[dictRect release];
	return [dictionary autorelease];
}

@end
