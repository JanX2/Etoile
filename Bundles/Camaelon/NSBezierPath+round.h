#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

#ifndef __NSBEZIER_PATH_ROUND_H__
#define __NSBEZIER_PATH_ROUND_H__

@interface NSBezierPath (RoundRect)
- (void) appendBezierPathWithTopRoundedCorners: (NSRect) aRect
					withRadius: (float) radius;
- (void) appendBezierPathWithRoundedRectangle: (NSRect) aRect
                                   withRadius: (float) radius;
@end

#endif // __NSBEZIER_PATH_ROUND_H__
