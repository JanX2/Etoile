/*
 * WFView.m - Workflow
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 03/27/07
 * License: Modified BSD license (see file COPYING)
 */


#import "WFView.h"
#import "WFObject.h"
#import "WFObjectDrawing.h"


@interface WFView (WorkflowPrivate)

- (void) WFDrawPipeFromPoint: (NSPoint)sourcePoint
                     toPoint: (NSPoint)destinationPoint;

@end


@implementation WFView

- (id) initWithFrame: (NSRect)frameRect
{
	self = [super initWithFrame: frameRect];
	if (self != nil)
		{
			/* Setup initial values */
			gridLineWidth = 0.0;
			gridSpacing = 48.0;
			gridColor = [NSColor gridColor];
			RETAIN(gridColor);

			pipeWidth = 5.0;
			pipeColor = [NSColor yellowColor];
			RETAIN(pipeColor);
			pipeBorderColor = [NSColor orangeColor];
			RETAIN(pipeBorderColor);
		}

	return self;
}

- (void) dealloc
{
	RELEASE(gridColor);
	RELEASE(pipeColor);
	RELEASE(pipeBorderColor);
}

/* Data source */

- (id) dataSource
{
	return dataSource;
}

- (void) setDataSource: (id)anObject
{
	if (!(anObject && 
		[anObject respondsToSelector:@selector(objectsForWorkflowView:)]))
		{
			[NSException raise: NSInternalInconsistencyException 
			            format: @"Data source does not respond to "
			                    @"objectsForWorkflowView:"];
		}

	if ([anObject
		respondsToSelector: @selector(workflowView:setValue:forObject:)])
		{
			isEditable = YES;
		}

	dataSource = anObject;

	[self setNeedsDisplay: YES];
}

/* Drawing */

- (BOOL) isFlipped
{
	return YES;
}

- (void) drawRect: (NSRect)rect
{
	/* Fill background */
	[[NSColor whiteColor] set];
	[NSBezierPath fillRect: rect];

	/* Draw grid */
	NSRect frameRect = [self frame];
	[gridColor set];
	[NSBezierPath setDefaultLineWidth: gridLineWidth];

	float currentPosition = gridSpacing;
	while (currentPosition < NSWidth(frameRect))
		{
			[NSBezierPath strokeLineFromPoint: NSMakePoint(currentPosition, 0)
			                          toPoint: NSMakePoint(currentPosition,
			                                   NSHeight(frameRect))];
			currentPosition += gridSpacing;
		}

	currentPosition = gridSpacing;
	while (currentPosition < NSHeight(frameRect))
		{
			[NSBezierPath strokeLineFromPoint: NSMakePoint(0, currentPosition)
			                          toPoint: NSMakePoint(NSWidth(frameRect),
			                                   currentPosition)];
			currentPosition += gridSpacing;
		}

	/* Draw data-flow diagram */
	if (dataSource)
		{
			// TODO: Draw objects and pipes from data source.
		}
}

@end


@implementation WFView (WorkflowPrivate)

- (void) WFDrawPipeFromPoint: (NSPoint)sourcePoint
                     toPoint: (NSPoint)destinationPoint
{
	float xAxis = (((destinationPoint.x - sourcePoint.x) / 2.0) + sourcePoint.x);
	NSPoint controlPoint1 = NSMakePoint(xAxis, sourcePoint.y);
	NSPoint controlPoint2 = NSMakePoint(xAxis, destinationPoint.y);

	NSBezierPath *pipePath = [NSBezierPath bezierPath];
	[pipePath moveToPoint: sourcePoint];
	[pipePath curveToPoint: destinationPoint controlPoint1: controlPoint1
	                                         controlPoint2: controlPoint2];

	[pipePath setLineWidth: pipeWidth];
	[pipePath setLineCapStyle: NSRoundLineCapStyle];
	[pipeBorderColor set];

	[pipePath stroke];

	[pipePath setLineWidth: (pipeWidth - 2.0)];
	[pipeColor set];

	[pipePath stroke];
}

@end

