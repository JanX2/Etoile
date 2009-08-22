#import "ETPenStyle.h"
#import "NSBezierPath+Geometry.h"
#import "NSBezierPath+Text.h"

/**
 * Implements a vector pen/calligraphy tool.
 *
 * Ideally, the width of the pen stroke could vary with pressure.
 * This isn't that easy to implement, though, since NSBezierPath only supports
 * a constant stroke width.
 * 
 * One idea: for each curve segment in the NSBezierPath.
 * construct a closed quadrilateral where the ends are straight lines
 * (corresponding to the width of the stroke at the start and end) 
 * and the sides are new curves with suitably chosen control points.
 *
 * Will have to test and see if this leaves visible seams or not..
 * Also, if the fill is semitransparent, drawing a path which crosses itself
 * will have that region more opaque (but that's probably realistic.)
 * Cusps may not look pretty..
 */
@implementation ETPenStyle

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect;
{
	[NSGraphicsContext saveGraphicsState];
	
	NSPoint origin = [[inputValues valueForKey:@"origin"] pointValue];
	NSAffineTransform *xform = [NSAffineTransform transform];
	[xform translateXBy: origin.x yBy: origin.y];
	[xform concat];

	// Text drawing test	
	[[[inputValues valueForKey: @"path"] bezierPathByInterpolatingPath: 1.0] drawStringOnPath: @"Étoilé is a user environment designed from the ground up around the things people do with computers: create, collaborate, and learn."];

	[NSGraphicsContext restoreGraphicsState];
}

@end
