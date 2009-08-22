/*
	Copyright (C) 2009 Eric Wasylishen

    Author:  Eric Wasylishen <ewasylishen@gmail.com>
    Date: August 2009
    License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileUI/ETGeometry.h>
#import <EtoileUI/ETShape.h>
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
	
	[self setStyle: [ETBezierPointStyle sharedInstance]];
	
	return self;
}

- (ETBezierPathPartcode) partcode
{
	return _partcode;
}

- (NSBezierPath *) manipulatedPath
{
	return (NSBezierPath *)[(ETShape *)[[self manipulatedObject] style] path];
}

@end

@implementation ETBezierHandleGroup

- (id) initWithActionHandler: (ETActionHandler *)anHandler 
           manipulatedObject: (id)aTarget
{
	NSMutableArray *handles = [NSMutableArray array];
	
	// FIXME: assumption
	ETShape *shape = (ETShape *)[aTarget style];
	NSBezierPath *path = [shape path];
	
	unsigned int count = [path elementCount];
	NSPoint	points[3];
	NSBezierPathElement type;
	for (unsigned int  i = 0; i < count; i++ )
	{
		type = [path elementAtIndex:i associatedPoints:points];
		switch (type)
		{
			// FIXME: ugly
			case NSCurveToBezierPathElement:
				[handles addObject: AUTORELEASE([[ETBezierHandle alloc] initWithActionHandler: [ETBezierPointActionHandler sharedInstance]
				                                                            manipulatedObject: aTarget
																			         partcode: [path partcodeForControlPoint: 0 ofElement: i]])];
				[handles addObject: AUTORELEASE([[ETBezierHandle alloc] initWithActionHandler: [ETBezierPointActionHandler sharedInstance]
				                                                            manipulatedObject: aTarget
																			         partcode: [path partcodeForControlPoint: 1 ofElement: i]])];
				[handles addObject: AUTORELEASE([[ETBezierHandle alloc] initWithActionHandler: [ETBezierPointActionHandler sharedInstance]
				                                                            manipulatedObject: aTarget
																			         partcode: [path partcodeForControlPoint: 2 ofElement: i]])];
				break;	
			case NSMoveToBezierPathElement:
			case NSLineToBezierPathElement:
				[handles addObject: AUTORELEASE([[ETBezierHandle alloc] initWithActionHandler: [ETBezierPointActionHandler sharedInstance]
				                                                            manipulatedObject: aTarget
																			         partcode: [path partcodeForElement: i]])];
				break;
			case NSClosePathBezierPathElement:
				break;
			default:
				break;
		}
	}
	
	self = [super initWithItems: handles view: nil value: nil representedObject: nil];
	if (self == nil)
		return nil;
	
	return self;
}

- (void) updateHandleLocations
{
	FOREACH([self items], handle, ETBezierHandle *)
	{
		[handle setPosition: [_path pointForPartcode: [handle partcode]]];
	}
}

@end

/* Action and Style Aspects */

@implementation ETBezierPointActionHandler
- (void) handleTranslateItem: (ETHandle *)handle byDelta: (NSSize)delta
{
	NSBezierPath *path = [(ETBezierHandle *)handle manipulatedPath];
	ETBezierPathPartcode partcode = [(ETBezierHandle *)handle partcode];
	NSPoint point = ETSumPointAndSize([handle position], delta);
	
	[path moveControlPointPartcode: partcode toPoint: point colinear:NO coradial: NO constrainAngle: NO];
	[handle setPosition: point];
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