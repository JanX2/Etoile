#import "ETDrawingStrokeShape.h"

@implementation ETDrawingStrokeShape

- (id) init
{
	self = [super initWithBezierPath: [NSBezierPath bezierPath]];
	if (nil == self)
	{
		return nil;
	}
	[_path moveToPoint: NSZeroPoint];
	_pressures = [[NSMutableArray alloc] initWithCapacity:1000];
	
	// Change this to ETPenStyle to get a vector pen tool instead..
	_brushStyle = [[ETBrushStyle alloc] init];
	_origin = NSMakePoint(0.0, 0.0);
	return self;
}

- (void) dealloc
{
	[_brushStyle release];
	[_pressures release];
	[super dealloc];
}

- (void) addPoint: (NSPoint)point withPressure: (float)pressure
{
	[_path lineToPoint: point];
	[_pressures addObject: [NSNumber numberWithFloat:pressure]];
	[self didChangeItemBounds: [[self path] bounds]];
}

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect;
{
	// FIXME: May be we should better support dirtyRect. The next drawing 
	// methods don't take in account it and simply redraw all their content.
	
	NSMutableDictionary *newInputValues = [D([self path], @"path",
											_pressures, @"pressures",
										   [NSValue valueWithPoint: _origin], @"origin") mutableCopy];
	[newInputValues addEntriesFromDictionary: inputValues];
	
	[[self brushStyle] render: newInputValues
				   layoutItem: item
					dirtyRect: dirtyRect];
	
	if ([item isSelected])
	{
		[self drawSelectionIndicatorInRect: [item drawingBoundsForStyle: self]];
	}
}

- (ETStyle *) brushStyle
{
	return _brushStyle;
}
- (void) setBrushStyle: (ETStyle *)style;
{
	ASSIGN(_brushStyle, style);
	// TODO: redraw?
}


- (void) setDrawingOrigin: (NSPoint)origin
{
	_origin = origin;
}


@end
