#import <Cocoa/Cocoa.h>
#import <X11/Xlib.h>
#import <StepTalk/StepTalk.h>


@interface Corner : NSObject {
	int lastCorner;
	int cornerWaitCount;
	Window w; 
	Window lastRoot;
	unsigned int rootWidth;
	unsigned int rootHeight;
	BOOL inCorner;
	STEnvironment * scriptingEnvironment;
	STEngine * smalltalkEngine;
	NSArray * scripts;
}
@end
