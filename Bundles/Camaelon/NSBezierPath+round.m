#include "NSBezierPath+round.h"

//
// Simple category of NSBezierPath to easily draw a rectangle with
// custom rounded corners.
//
@implementation NSBezierPath (RoundRect)

- (void) appendBezierPathWithLeftAndBottomRoundedCorners: (NSRect) aRect
					withRadius: (float) radius
{
  NSPoint topMid = NSMakePoint(NSMidX(aRect), NSMaxY(aRect));
  NSPoint bottomMid = NSMakePoint(NSMidX(aRect), NSMinY(aRect));
  NSPoint topLeft = NSMakePoint(NSMinX(aRect), NSMaxY(aRect));
  NSPoint topRight = NSMakePoint(NSMaxX(aRect), NSMaxY(aRect));
  NSPoint bottomRight = NSMakePoint(NSMaxX(aRect), NSMinY(aRect));
  NSPoint bottomLeft = NSMakePoint(NSMinX(aRect), NSMinY(aRect));

  [self moveToPoint: topMid];
  [self appendBezierPathWithArcFromPoint: topLeft
  	toPoint: aRect.origin
	radius: radius];
  [self appendBezierPathWithArcFromPoint: bottomLeft
        toPoint: bottomRight
        radius: radius];
  [self appendBezierPathWithArcFromPoint: bottomRight
	toPoint: topRight
	radius: radius];
  [self lineToPoint: topRight];
  [self closePath];
}

- (void) appendBezierPathWithBottomRoundedCorners: (NSRect) aRect
					withRadius: (float) radius
{
  NSPoint bottomMid = NSMakePoint(NSMidX(aRect), NSMinY(aRect));
  NSPoint topLeft = NSMakePoint(NSMinX(aRect), NSMaxY(aRect));
  NSPoint topRight = NSMakePoint(NSMaxX(aRect), NSMaxY(aRect));
  NSPoint bottomRight = NSMakePoint(NSMaxX(aRect), NSMinY(aRect));
  NSPoint bottomLeft = NSMakePoint(NSMinX(aRect), NSMinY(aRect));

  [self moveToPoint: topLeft];
  [self appendBezierPathWithArcFromPoint: bottomLeft
        toPoint: bottomMid
        radius: radius];
  [self appendBezierPathWithArcFromPoint: bottomRight
	toPoint: topRight
	radius: radius];
  [self lineToPoint: topRight];
  [self closePath];
}

- (void) appendBezierPathWithLeftRoundedCorners: (NSRect) aRect
					withRadius: (float) radius
{
  NSPoint topMid = NSMakePoint(NSMidX(aRect), NSMaxY(aRect));
  NSPoint topLeft = NSMakePoint(NSMinX(aRect), NSMaxY(aRect));
  NSPoint topRight = NSMakePoint(NSMaxX(aRect), NSMaxY(aRect));
  NSPoint bottomRight = NSMakePoint(NSMaxX(aRect), NSMinY(aRect));
  NSPoint bottomLeft = NSMakePoint(NSMinX(aRect), NSMinY(aRect));

  [self moveToPoint: topMid];
  [self appendBezierPathWithArcFromPoint: topLeft
        toPoint: aRect.origin
        radius: radius];
  [self appendBezierPathWithArcFromPoint: bottomLeft
	toPoint: bottomRight
	radius: radius];
  [self lineToPoint: bottomRight];
  [self lineToPoint: topRight];
  [self closePath];
}

- (void) appendBezierPathWithTopRoundedCorners: (NSRect) aRect
					withRadius: (float) radius
{
	NSLog (@"toproundedcorners ! radius: %f", radius);
  NSPoint topMid = NSMakePoint(NSMidX(aRect), NSMaxY(aRect));
  NSPoint topLeft = NSMakePoint(NSMinX(aRect), NSMaxY(aRect));
  NSPoint topRight = NSMakePoint(NSMaxX(aRect), NSMaxY(aRect));
  NSPoint bottomRight = NSMakePoint(NSMaxX(aRect), NSMinY(aRect));
  NSPoint bottomLeft = NSMakePoint(NSMinX(aRect), NSMinY(aRect));

  [self moveToPoint: topMid];
  [self appendBezierPathWithArcFromPoint: topLeft
        toPoint: aRect.origin
        radius: radius];
  [self lineToPoint: bottomLeft];
  [self lineToPoint: bottomRight];
  [self appendBezierPathWithArcFromPoint: topRight 
	toPoint: topLeft
	radius: radius];
  [self closePath];
}

- (void) appendBezierPathWithRoundedRectangle: (NSRect) aRect
                                   withRadius: (float) radius
{
  NSPoint topMid = NSMakePoint(NSMidX(aRect), NSMaxY(aRect));
  NSPoint topLeft = NSMakePoint(NSMinX(aRect), NSMaxY(aRect));
  NSPoint topRight = NSMakePoint(NSMaxX(aRect), NSMaxY(aRect));
  NSPoint bottomRight = NSMakePoint(NSMaxX(aRect), NSMinY(aRect));

  [self moveToPoint: topMid];
  [self appendBezierPathWithArcFromPoint: topLeft
        toPoint: aRect.origin
        radius: radius];
  [self appendBezierPathWithArcFromPoint: aRect.origin
        toPoint: bottomRight
        radius: radius];
  [self appendBezierPathWithArcFromPoint: bottomRight
        toPoint: topRight
        radius: radius];
  [self appendBezierPathWithArcFromPoint: topRight
        toPoint: topLeft
        radius: radius];
  [self closePath];
}

- (void) appendBezierDemiSupPathWithRoundedRectangle: (NSRect) aRect
                                   withRadius: (float) radius
{
  NSPoint topMid = NSMakePoint(NSMidX(aRect), NSMaxY(aRect));
  NSPoint topLeft = NSMakePoint(NSMinX(aRect), NSMaxY(aRect));
  NSPoint topRight = NSMakePoint(NSMaxX(aRect) - radius, NSMaxY(aRect));
  NSPoint bottomRight = NSMakePoint(NSMaxX(aRect), NSMinY(aRect));

  [self moveToPoint: topRight];
  [self appendBezierPathWithArcFromPoint: topLeft
        toPoint: aRect.origin
        radius: radius];
  [self appendBezierPathWithArcFromPoint: aRect.origin
        toPoint: bottomRight
        radius: radius];
}
- (void) appendBezierDemiDownPathWithRoundedRectangle: (NSRect) aRect
                                   withRadius: (float) radius
{
  NSPoint topMid = NSMakePoint(NSMidX(aRect), NSMaxY(aRect));
  NSPoint topLeft = NSMakePoint(NSMinX(aRect), NSMaxY(aRect));
  NSPoint topRight = NSMakePoint(NSMaxX(aRect), NSMaxY(aRect));
  NSPoint bottomRight = NSMakePoint(NSMaxX(aRect), NSMinY(aRect));
  NSPoint bottomLeft = NSMakePoint(NSMinX(aRect) + radius, NSMinY(aRect));

  [self moveToPoint: bottomLeft];
  [self appendBezierPathWithArcFromPoint: bottomRight
        toPoint: topRight
        radius: radius];
  [self appendBezierPathWithArcFromPoint: topRight
        toPoint: topLeft
        radius: radius];
}

@end

