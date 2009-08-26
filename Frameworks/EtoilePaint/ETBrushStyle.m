#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayoutItem.h>

#import "ETBrushStyle.h"
#import "NSBezierPath+Geometry.h"

/**
 * Implements a basic bitmap brush.
 *
 * Everything is hardcoded for now :)
 *
 * Currently hardcoded for flipped coordinates to make experimentation easier.
 */
@implementation ETBrushStyle

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect;
{
	[NSGraphicsContext saveGraphicsState];
	
	NSPoint origin = [[inputValues valueForKey:@"origin"] pointValue];

	//NSLog(@"Offsetting drawing by %@ (frame: %@)", NSStringFromPoint(origin),  NSStringFromRect([item frame]));
	
NSAffineTransform *xform = [NSAffineTransform transform];
	[xform translateXBy: origin.x yBy: origin.y];
	[xform concat];
	
	
	NSBezierPath *path = [[inputValues valueForKey: @"path"] bezierPathByInterpolatingPath: 1.0];
	NSArray *pressures = [inputValues valueForKey: @"pressures"];
	//NSGradient *gradient = [[NSGradient alloc] initWithStartingColor: [NSColor blueColor] endingColor: [NSColor clearColor]];
	
	NSImage *brushImage = [[NSImage alloc] initWithContentsOfFile: 
		[[NSBundle bundleForClass: [self class]] pathForResource: @"testbrush" ofType: @"png"]];


	// Update item bounding box based on brush radius
	float maxRadius = [brushImage size].width / 2;
	[item setBoundingBox: NSInsetRect([(id)item bounds], -1 * maxRadius, -1 * maxRadius)];
	//NSLog(@"New bounding box %@, bounds %@", NSStringFromRect([item boundingBox]), NSStringFromRect([(id)item bounds]));	

	//[[NSColor colorWithDeviceRed: 0.3 green: 0.0 blue: 0.7 alpha: 0.2] setFill];

	if (path != nil && pressures != nil)
	{
		float spacing = 5.5;
		float length = [path length];
		for (float pos = 0; pos < length; pos += spacing)
		{
			float slope;
			NSPoint point = [path pointOnPathAtLength: pos slope: &slope];
	
			// Center the brush dab over point
			point.x -= maxRadius;
			point.y += maxRadius;

			float pressure =  0.75;
			float radius = 10.0 * pressure;
/*				
			NSRect rect = NSMakeRect(point.x - radius, point.y - radius, 2*radius, 2*radius);
			NSBezierPath *brushpath = [NSBezierPath bezierPath];
			[brushpath appendBezierPathWithOvalInRect: rect];
			[brushpath fill];
*/
			[brushImage compositeToPoint: point operation: NSCompositeSourceOver];		
		}
	}

	[NSGraphicsContext restoreGraphicsState];
}

@end
