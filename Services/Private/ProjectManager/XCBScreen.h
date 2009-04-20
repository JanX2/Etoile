#import "XCBConnection.h"

@class XCBWindow;

@interface XCBScreen : NSObject {
	xcb_screen_t screen;
	XCBWindow *root;
}
+ (XCBScreen*) screenWithXCBScreen: (xcb_screen_t*)aScreen;
- (XCBWindow*) rootWindow;
- (xcb_screen_t*)screenInfo;
@end
