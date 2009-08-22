/*
	Copyright (C) 2009 Eric Wasylishen

    Author:  Eric Wasylishen <ewasylishen@gmail.com>
    Date: August 2009
    License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETBezierHandle.h"

@implementation ETBezierHandle

- (id) initWithActionHandler: (ETActionHandler *)anHandler
           manipulatedObject: (id)aTarget
                    partcode: (ETBezierPathPartcode)partcode
{
	self = [super initWithActionHandler: anHandler
	                  manipulatedObject: aTarget];
	if (nil == self)
	{
		return nil;
	}
	_partcode = partcode;
	
	
	return self;
}

@end

@implementation ETBezierHandleGroup

- (id) initWithManipulatedObject: (id)aTarget
{
  return nil;
}

- (void) render: (NSMutableDictionary *)inputValues 
      dirtyRect: (NSRect)dirtyRect
      inContext: (id)ctxt
{
}
- (void) drawOutlineInRect: (NSRect)rect
{
}

@end

/* Action and Style Aspects */

@implementation ETBezierPointActionHandler
- (void) handleTranslateItem: (ETHandle *)handle byDelta: (NSSize)delta
{
	NSBezierPath *path = [handle manipulatedPath];
	ETBezierPathPartcode partcode = [handle partcode];
	NSPoint point = ETSumPointAndSize([handle origin], delta);
	
	[path moveControlPointPartcode: partcode toPoint: point colinear:NO coradial: NO constrainAngle: NO];
}
@end

@implementation ETBezierControlPointActionHandler
- (void) handleTranslateItem: (ETHandle *)handle byDelta: (NSSize)delta
{
}
@end



@implementation ETBezierPointStyle

static ETBezierPointStyle *sharedBezierPointStyle = nil;

+ (id) sharedInstance
{
	if (sharedBezierPointStyle == nil)
		sharedBezierPointStyle = [[ETBezierPointStyle alloc] init];
		
	return sharedBezierPointStyle;
}

/** Draws the interior of the handle. */
- (void) drawHandleInRect: (NSRect)rect
{
	[[[NSColor orangeColor] colorWithAlphaComponent: 0.80] setFill];
	[[NSBezierPath bezierPathWithOvalInRect: rect] fill];
}

@end

@implementation ETBezierControlPointStyle

static ETBezierControlPointStyle *sharedBezierControlPointStyle = nil;

+ (id) sharedInstance
{
	if (sharedBezierControlPointStyle == nil)
		sharedBezierControlPointStyle = [[ETBezierControlPointStyle alloc] init];
		
	return sharedBezierControlPointStyle;
}

/** Draws the interior of the handle. */
- (void) drawHandleInRect: (NSRect)rect
{
	[[[NSColor cyanColor] colorWithAlphaComponent: 0.80] setFill];
	NSRectFill(rect);
}

@end