/*
	IKCompositorOperation.m

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

#import "IKCompositorOperation.h"

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
