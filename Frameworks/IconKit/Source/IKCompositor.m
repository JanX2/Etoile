/*
	IKCompositor.m

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

#import "IKCompositor.h"

@implementation IKCompositor

- (void) dealloc
{
	[operations release];
	[super dealloc];
}

- (id) initWithSize: (NSSize)size
{
	operations = [NSMutableArray new];
	originalSize = size;
	compositingSize = originalSize;

	return self;
}

- (id) initWithImage: (NSImage *)image
{
	operations = [NSMutableArray new];
	
	if (image != nil)
	{
		originalSize = [image size];
		compositingSize = originalSize;

		IKCompositorOperation* initialOperation = [[IKCompositorOperation alloc] 
			initWithImage: image
			position: IKCompositedImagePositionCenter
			operation: NSCompositeSourceOver
			alpha: 1.0];

		[operations addObject: initialOperation];

		[initialOperation release];
	}

	return self;
}

- (id) initWithPropertyList: (NSDictionary *)propertyList
{
	operations = [NSMutableArray new];

	if (propertyList != nil)
	{
		NSNumber* number = nil;
		NSDictionary* dict = nil;
		NSArray* array = nil;
		dict = [propertyList objectForKey: @"originalSize"];
		if (dict != nil)
		{
			float x, y, width, height;

			number = [dict objectForKey: @"width"];
			if (number != nil) width = [number floatValue];		

			number = [dict objectForKey: @"height"];
			if (number != nil) height = [number floatValue];		

			originalSize = NSMakeSize (width, height);
		}
		dict = [propertyList objectForKey: @"compositingSize"];
		if (dict != nil)
		{
			float x, y, width, height;

			number = [dict objectForKey: @"width"];
			if (number != nil) width = [number floatValue];		

			number = [dict objectForKey: @"height"];
			if (number != nil) height = [number floatValue];		

			compositingSize = NSMakeSize (width, height);
		}
		array = [propertyList objectForKey: @"operations"];
		if (array != nil)
		{
			int i;
			for (i=0; i<[array count]; i++)
			{
				NSDictionary* item = [array objectAtIndex: i];
				IKCompositorOperation* op = [[IKCompositorOperation alloc] 
					initWithPropertyList: item];
				[operations addObject: op];
				[op release];
			}
		}
	}
		
	return self;
}

- (NSSize) size { return originalSize; }

- (NSSize) compositingSize { return compositingSize; }

- (void) setCompositingSize: (NSSize)size { compositingSize = size; }

- (void) compositeImage: (NSImage *)source 
           withPosition: (IKCompositedImagePosition) position
{
	[self compositeImage: source withPosition: position 
		operation: NSCompositeSourceOver alpha: 1.0];
}

- (void) compositeImage: (NSImage *)source 
                 inRect:(NSRect)rect
{
	[self compositeImage: source inRect: rect 
		operation: NSCompositeSourceOver alpha: 1.0];
}

- (void) compositeImage: (NSImage *)source 
           withPosition: (IKCompositedImagePosition)position
              operation: (NSCompositingOperation)operation
                  alpha: (float)a
{
        IKCompositorOperation* op = [[IKCompositorOperation alloc] 
			initWithImage: source
			position: position
			operation: operation
			alpha: a];
	[operations addObject: op];
	[op release];
}

- (void) compositeImage: (NSImage *)source 
                 inRect: (NSRect)rect
              operation: (NSCompositingOperation)operation 
                  alpha: (float)a
{
        IKCompositorOperation* op = [[IKCompositorOperation alloc] 
			initWithImage: source
			rect: rect
			operation: operation
			alpha: a];
	[operations addObject: op];
	[op release];
}

- (NSImage *) render
{
	int i;
	NSImage* image = [[NSImage alloc] initWithSize: originalSize];
	[image lockFocus];
	for (i=0; i<[operations count]; i++)
	{
		IKCompositorOperation* op = [operations objectAtIndex: i];
		NSImage* compositedImage = [op image];
		[compositedImage setScalesWhenResized: YES];
		[compositedImage setSize: [op rect].size];
		[compositedImage compositeToPoint: [op rect].origin 
			operation: [op operation]];	
	}
	NSBitmapImageRep* rep = [[NSBitmapImageRep alloc] 
		initWithFocusedViewRect: NSMakeRect (0,0,compositingSize.width, compositingSize.height)];
	[image unlockFocus];
	return [rep autorelease];
}

- (NSDictionary *) propertyList
{
	NSMutableDictionary* dictionary = [[NSMutableDictionary alloc] init];
	NSMutableDictionary* dictOriginalSize = [[NSMutableDictionary alloc] init];
	NSMutableDictionary* dictCompositingSize = [[NSMutableDictionary alloc] init];
	NSMutableArray* arrayOperations = [[NSMutableArray alloc] init];

	[dictOriginalSize setObject: [NSNumber numberWithFloat: originalSize.width] forKey: @"width"];
	[dictOriginalSize setObject: [NSNumber numberWithFloat: originalSize.height] forKey: @"height"];
	[dictionary setObject: dictOriginalSize forKey: @"originalSize"];
	[dictOriginalSize release];
	[dictCompositingSize setObject: [NSNumber numberWithFloat: compositingSize.width] forKey: @"width"];
	[dictCompositingSize setObject: [NSNumber numberWithFloat: compositingSize.height] forKey: @"height"];
	[dictionary setObject: dictCompositingSize forKey: @"compositingSize"];
	[dictCompositingSize release];

	int i;
	for (i=0; i<[operations count]; i++)
	{
		IKCompositorOperation* item = [operations objectAtIndex: i];
		[arrayOperations addObject: [item propertyList]];		
	}
	[dictionary setObject: arrayOperations forKey: @"operations"];
	[arrayOperations release];
	return [dictionary autorelease];
}

@end
