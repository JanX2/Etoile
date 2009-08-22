/*
	Copyright (C) 2009 Eric Wasylishen

    Author:  Eric Wasylishen <ewasylishen@gmail.com>
    Date: August 2009
    License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileUI/ETGeometry.h>
#import <EtoileUI/ETShape.h>
#import <EtoileUI/ETCompatibility.h>
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
	
	if ([[self manipulatedPath] isControlPoint: [self partcode]])
	{
		[self setStyle: [ETBezierControlPointStyle sharedInstance]];
	}
	else
	{
		[self setStyle: [ETBezierPointStyle sharedInstance]];
	}
	NSLog(@"Bezier handle %@ created, manip path %@", self, [self manipulatedPath]);
	
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

- (id) initWithManipulatedObject: (id)aTarget
{
	return [self initWithActionHandler: nil manipulatedObject: aTarget];
}

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
	
	[self setFlipped: YES];
	[self setStyle: nil]; /* Suppress the default ETLayoutItem style */
	[self setActionHandler: anHandler];
	[self setManipulatedObject: aTarget];
	
	// FIXME: assumption
	[self updateHandleLocations];
	
	return self;
}

- (NSBezierPath *) manipulatedPath
{
	NSLog(@"manip obj %@, style %@", [self manipulatedObject] , [[self manipulatedObject] style]);
	ETShape *shape = (ETShape *)[[self manipulatedObject] style];
	NSBezierPath *path = [shape path];
	NSAssert(path != nil, @"Path is nil");
	return path;
}

- (void) updateHandleLocations
{
	FOREACH([self items], handle, ETBezierHandle *)
	{
		NSLog(@"set handle %@ pc: %d to %@", handle, [handle partcode], NSStringFromPoint([[self manipulatedPath] pointForPartcode: [handle partcode]]));
		[handle setPosition: [[self manipulatedPath] pointForPartcode: [handle partcode]]];
	}
}


- (id) manipulatedObject
{
	return GET_PROPERTY(kETManipulatedObjectProperty);
}

- (void) setManipulatedObject: (id)anObject
{
	SET_PROPERTY(anObject, kETManipulatedObjectProperty);
	/* Better to avoid -setFrame: which would update the represented object frame. */
	// FIXME: Ugly duplication with -setFrame:... 
	//[self setFrame: [anObject frame]];
	[self setRepresentedObject: anObject];
	[self updateHandleLocations];
}

- (NSPoint) anchorPoint
{
	return [GET_PROPERTY(kETManipulatedObjectProperty) anchorPoint];
}

- (void) setAnchorPoint: (NSPoint)anchor
{
	return [GET_PROPERTY(kETManipulatedObjectProperty) setAnchorPoint: anchor];
}

- (NSPoint) position
{
	return [(ETLayoutItem *)GET_PROPERTY(kETManipulatedObjectProperty) position];
}

- (void) setPosition: (NSPoint)aPosition
{
	[GET_PROPERTY(kETManipulatedObjectProperty) setPosition: aPosition];
	[self updateHandleLocations];
}

/** Returns the content bounds associated with the receiver. */
- (NSRect) contentBounds
{
	NSRect manipulatedFrame = [GET_PROPERTY(kETManipulatedObjectProperty) frame];
	return ETMakeRect(NSZeroPoint, manipulatedFrame.size);
}

- (void) setContentBounds: (NSRect)rect
{
	NSRect manipulatedFrame = ETMakeRect([GET_PROPERTY(kETManipulatedObjectProperty) origin], rect.size);
	[GET_PROPERTY(kETManipulatedObjectProperty) setFrame: manipulatedFrame];
	[self updateHandleLocations];
}

- (NSRect) frame
{
	return [GET_PROPERTY(kETManipulatedObjectProperty) frame];
}

// NOTE: We need to figure out what we really needs. For example,
// -setBoundingBox: could be called when a handle group is inserted, or the 
// layout and/or the style could have a hook -boundingBoxForItem:. We 
// probably want to cache the bounding box value in an ivar too.
- (void) setFrame: (NSRect)frame
{
	[GET_PROPERTY(kETManipulatedObjectProperty) setFrame: frame];
	[self updateHandleLocations];
}

- (void) setBoundingBox: (NSRect)extent
{
	[super setBoundingBox: extent];
	[GET_PROPERTY(kETManipulatedObjectProperty) setBoundingBox: extent];
}

/** Marks both the receiver and its manipulated object as invalidated area 
or not. */
- (void) setNeedsDisplay: (BOOL)flag
{
	[super setNeedsDisplay: flag];
	[[self manipulatedObject] setNeedsDisplay: flag];
}

/** Returns YES. */
- (BOOL) acceptsActionsForItemsOutsideOfFrame
{
	return YES;
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
