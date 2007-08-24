/*
	IKCompositor.m

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

#import "IKCompat.h"
#import <IconKit/IKCompositor.h>

@implementation IKCompositor

- (void) dealloc
{
	RELEASE(operations);
	[super dealloc];
}

- (id) initWithSize: (NSSize)size
{
	if ((self = [super init]) != nil)
	{
		operations = [[NSMutableArray alloc] init];
		originalSize = size;
		compositingSize = originalSize;
		
		return self;
	}

	return nil;
}

- (id) initWithImage: (NSImage *)image
{
	if (image == nil)
	{
		RELEASE(self); // May be we should raise an exception
	}
	else
	{
		if ((self = [self initWithSize: [image size]]) != nil)
		{
			IKCompositorOperation* initialOperation = [[IKCompositorOperation alloc] 
				initWithImage: image
				position: IKCompositedImagePositionCenter
				operation: NSCompositeSourceOver
				alpha: 1.0];

			[operations addObject: initialOperation];

			RELEASE(initialOperation);
			return self;
		}
	}

	return nil;
}

- (id) initWithPropertyList: (NSDictionary *)propertyList
{
	NSNumber* number = nil;
	NSDictionary* dict = nil;
	NSArray *array = nil;
	NSSize size;
	
	if (propertyList == nil)
	{
		RELEASE(self);
		return nil; // May be we should raise an exception
	}
	
	dict = [propertyList objectForKey: @"originalSize"];
		
	if (dict != nil)
	{
		float width, height;

		number = [dict objectForKey: @"width"];
		if (number != nil) width = [number floatValue];		

		number = [dict objectForKey: @"height"];
		if (number != nil) height = [number floatValue];		

		size = NSMakeSize (width, height);
	}
	
	if ((self = [self initWithSize: size]) != nil)
	{

		dict = [propertyList objectForKey: @"compositingSize"];

		if (dict != nil)
		{
			float width, height;

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

			for (i = 0; i<  [array count]; i++)
			{
				NSDictionary* item = [array objectAtIndex: i];
				IKCompositorOperation* op = [[IKCompositorOperation alloc] 
					    initWithPropertyList: item];

				[operations addObject: op];
				RELEASE(op);
			}
		}
		
		return self;
	}
		
	return nil;
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
	RELEASE(op);
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
	RELEASE(op);
}

- (NSImage *) render
{
	int i;
	NSImage* image = [[NSImage alloc] initWithSize: originalSize];
	NSBitmapImageRep* rep;
	
	[image lockFocus];
	
	for (i = 0; i < [operations count]; i++)
	{
		IKCompositorOperation* op = [operations objectAtIndex: i];
		NSImage* compositedImage = [op image];
		
		[compositedImage setScalesWhenResized: YES];
		[compositedImage setSize: [op rect].size];
		[compositedImage compositeToPoint: [op rect].origin 
			operation: [op operation]];	
	}
	
	rep = [[NSBitmapImageRep alloc] 
		initWithFocusedViewRect: NSMakeRect (0,0,compositingSize.width, compositingSize.height)];
	[image unlockFocus];
	
	[image addRepresentation: rep];
	RELEASE(rep);
	
	return AUTORELEASE(image);
}

- (NSDictionary *) propertyList
{
	NSMutableDictionary* dictionary = [[NSMutableDictionary alloc] init];
	NSMutableDictionary* dictOriginalSize = [[NSMutableDictionary alloc] init];
	NSMutableDictionary* dictCompositingSize = [[NSMutableDictionary alloc] init];
	NSMutableArray* arrayOperations = [[NSMutableArray alloc] init];
	int i;

	[dictOriginalSize setObject: [NSNumber numberWithFloat: originalSize.width] forKey: @"width"];
	[dictOriginalSize setObject: [NSNumber numberWithFloat: originalSize.height] forKey: @"height"];
	[dictionary setObject: dictOriginalSize forKey: @"originalSize"];
	RELEASE(dictOriginalSize);
	[dictCompositingSize setObject: [NSNumber numberWithFloat: compositingSize.width] forKey: @"width"];
	[dictCompositingSize setObject: [NSNumber numberWithFloat: compositingSize.height] forKey: @"height"];
	[dictionary setObject: dictCompositingSize forKey: @"compositingSize"];
	RELEASE(dictCompositingSize);

	for (i = 0; i < [operations count]; i++)
	{
		IKCompositorOperation* item = [operations objectAtIndex: i];
		[arrayOperations addObject: [item propertyList]];		
	}
	
	[dictionary setObject: arrayOperations forKey: @"operations"];
	RELEASE(arrayOperations);
	
	return AUTORELEASE(dictionary);
}

@end
