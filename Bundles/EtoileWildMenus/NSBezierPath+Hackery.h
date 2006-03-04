#include "AppKit/NSBezierPath.h"

@interface NSBezierPath(RoundedRectangle)

/**
Returns a closed bezier path describing a rectangle with curved corners
 The corner radius will be trimmed to not exceed half of the lesser rectangle dimension.
 */
+ (NSBezierPath *) bezierPathWithRoundedRect: (NSRect) aRect cornerRadius: (double) radius;

@end
