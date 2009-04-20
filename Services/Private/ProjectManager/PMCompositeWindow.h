#import "XCBWindow.h"
#include <xcb/render.h>

@interface PMCompositeWindow : NSObject {
	XCBWindow *window;
	xcb_pixmap_t pixmap;
	xcb_render_picture_t picture;
	xcb_render_picture_t root;
	XCBRect scaledFrame;
}
+ (PMCompositeWindow*)compositeWindowWithXCBWindow: (XCBWindow*)aWindow;
- (void)setRootPicture: (xcb_render_picture_t)aPicture;
- (xcb_render_picture_t)picture;
- (void)drawXCBRect: (XCBRect)aRect;
@end
