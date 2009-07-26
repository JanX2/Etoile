#import "ETBrushStyle.h"
#import <AppKit/AppKit.h>

/**
 * Implements a basic bitmap brush.
 *
 * Currently only stamps the brush bitmap at the location of each input event, so
 * looks very ugly (need to interpolate between the input events).
 *
 * Everything is also hardcoded for now :)
 *
 */
@implementation ETBrushStyle

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect;
{
	[NSGraphicsContext saveGraphicsState];
	
	NSPoint origin = [[inputValues valueForKey:@"origin"] pointValue];
	NSAffineTransform *xform = [NSAffineTransform transform];
	[xform translateXBy: origin.x yBy: origin.y];
	[xform concat];
	
	
	NSBezierPath *path = [inputValues valueForKey: @"path"];
	NSArray *pressures = [inputValues valueForKey: @"pressures"];
	//NSGradient *gradient = [[NSGradient alloc] initWithStartingColor: [NSColor blueColor] endingColor: [NSColor clearColor]];
	
	[[NSColor colorWithDeviceRed: 0.3 green: 0.0 blue: 0.7 alpha: 0.3] setFill];

	if (path != nil && pressures != nil)
	{
		NSPoint points[3];
		NSPoint last = NSZeroPoint;
		for (unsigned int i=0; i<[path elementCount]; i++)
		{
			if ([path elementAtIndex: i associatedPoints: points] == NSLineToBezierPathElement)
			{
				float pressure =  [[pressures objectAtIndex: i-1] floatValue];
				float radius = 10.0 * pressure;
				
				NSRect rect = NSMakeRect(points[0].x - radius, points[0].y - radius, 2*radius, 2*radius);
				NSBezierPath *path = [NSBezierPath bezierPath];
				[path appendBezierPathWithOvalInRect: rect];
				[path fill];

				last = points[0];
			}
		}
	}
	
	[NSGraphicsContext restoreGraphicsState];
}

@end
