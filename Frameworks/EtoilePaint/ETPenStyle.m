#import "ETPenStyle.h"

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
	
	[[inputValues valueForKey: @"path"] stroke];

	[NSGraphicsContext restoreGraphicsState];
}

@end