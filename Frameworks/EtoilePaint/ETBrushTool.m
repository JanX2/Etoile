/*
 Copyright (C) 2008 Quentin Mathe
 
 Author:  Quentin Mathe <qmathe@club-internet.fr>
 Date:  December 2008
 License:  Modified BSD (see COPYING)
 */

#import "ETBrushTool.h"

@implementation ETBrushTool

+ (NSString *) baseClassName
{
	return @"Tool";
}

- (id) init
{
	SUPERINIT
	return self;
}

- (void) dealloc
{
    [super dealloc];
}


- (void) mouseDown: (ETEvent *)anEvent
{
	//NSLog(@"ETBrushTool mousedown. %@\n %@\n %@", [self targetItem],  [anEvent layoutItem], [[self targetItem] itemsIncludingAllDescendants]);
	
	NSPoint startPoint = [anEvent locationInLayoutItem];
	NSRect startRect = NSMakeRect(startPoint.x, startPoint.y, 10.0, 10.0);
	
	NSRect r = [[self targetItem] convertRect:startRect fromItem: [anEvent layoutItem]];
	NSRect r2 = [[anEvent layoutItem] convertRect:startRect toItem: (ETLayoutItemGroup *)[self targetItem]];
	
	NSLog(@"r1: %@ r2: %@", NSStringFromRect(r), NSStringFromRect(r2));
	// FIXME: why aren't r and r2 equal
	NSRect locInTargetContent = [[self targetItem] convertRectToContent: r2];

	_startInTargetContainer = locInTargetContent.origin;
	
	_start = [anEvent location]; // store position in window
	
	_brushStroke = [[[ETLayoutItem alloc] init] autorelease];
	_drawingStrokeShape = [[ETDrawingStrokeShape alloc] init];
	[_drawingStrokeShape addPoint: NSMakePoint(0.0, 0.0) withPressure: [(NSEvent *)[anEvent backendEvent] pressure]];
	[_brushStroke setStyle: _drawingStrokeShape];
	[_brushStroke setFrame: locInTargetContent];
	
	[(ETLayoutItemGroup *)[self targetItem] addItem: _brushStroke];
	[_brushStroke setNeedsDisplay: YES];
}

- (void) mouseUp: (ETEvent *)anEvent
{
	NSLog(@"ETBrushTool mouseup. %@ %@", [self targetItem], [anEvent layoutItem]);
}

- (void) mouseDragged: (ETEvent *)anEvent
{
	//NSLog(@"ETBrushTool mousedragged %@ %@. %f", [self targetItem], [anEvent locationInLayoutItem], [(NSEvent *)[anEvent backendEvent] pressure]);
	
	// coordinates of the mouse pointer relative to where the drag was initiated
	NSPoint dragPosition = NSMakePoint([anEvent location].x - _start.x, [anEvent location].y - _start.y);
	
	// coordinates dragged to in the container's coordinate system
	NSRect dragPositionInTargetContainer;
	dragPositionInTargetContainer.origin = ETSumPoint(_startInTargetContainer, dragPosition);
	dragPositionInTargetContainer.size = NSMakeSize(1.0, 1.0);
	
	// set the new frame of the layout item.
	[_brushStroke setFrame: NSUnionRect([_brushStroke frame], ETStandardizeRect(dragPositionInTargetContainer))];
	
	NSPoint drawPositionRelativeToStartPosition;
	drawPositionRelativeToStartPosition.x = MAX(0.0, _startInTargetContainer.x - [_brushStroke frame].origin.x);
	drawPositionRelativeToStartPosition.y = MAX(0.0, _startInTargetContainer.y - [_brushStroke frame].origin.y);
	[_drawingStrokeShape setDrawingOrigin: drawPositionRelativeToStartPosition];
	
	
	[_drawingStrokeShape addPoint: dragPosition
					 withPressure: [(NSEvent *)[anEvent backendEvent] pressure]];
	
	[[self targetItem] setNeedsDisplay: YES];
	[[self targetItem] displayIfNeeded];
}



@end
