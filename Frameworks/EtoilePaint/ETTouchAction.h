#import <AppKit/AppKit.h>

/**
 * Formal protocol which covers the methods defined in NSEvent for getting
 * tablet data.
 */
@protocol ETTouchAction

- (NSTimeInterval) timestamp;
- (float) pressure;
- (float) rotation;
- (NSPoint) tilt;
- (float) tangentialPressure;

// TODO: Any more? Not sure how the fancy airbrush tool works..

@end

@interface ETEvent (ETTouchAction) <ETTouchAction>

@end
