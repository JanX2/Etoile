#import <Foundation/Foundation.h>
#import <X11/Xlib.h>
#include <time.h>

@interface Corner : NSObject {
	int lastCorner;
	time_t inCornerTime;
	Window w; 
	Window lastRoot;
	unsigned int rootWidth;
	unsigned int rootHeight;
	BOOL inCorner;
	Display *display;
	id delegate;

	BOOL inGesture;
	NSRect lastPosition;
	char lastDirection;
	NSMutableString *gesture;
}
/**
 * Poll the mouse position.
 */
- (void) periodic:(id)sender;
@end
