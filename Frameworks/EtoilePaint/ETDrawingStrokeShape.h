#import <EtoileFoundation/EtoileFoundation.h>
#import <EtoileUI/EtoileUI.h>
#import "ETBrushStyle.h"
#import "ETPenStyle.h"

@interface ETDrawingStrokeShape : ETShape
{
	NSMutableArray *_pressures;
	ETStyle *_brushStyle;
	NSPoint _origin;
}

// maybe all the tablet paramaters should be passed in a dictionary?
//- (void) addPenPosition: (NSPoint)point withPressure: (float)pressure tilt:(NSPoint)tilt rotation:(float)rotation barrelPressure:(float)barrelPressure atTime: (NSTimeInterval)timestamp;
- (void) addPoint: (NSPoint)point withPressure: (float)pressure; 

- (ETStyle *) brushStyle;
- (void) setBrushStyle: (ETStyle *)style;

- (void) setDrawingOrigin: (NSPoint)origin;

@end
