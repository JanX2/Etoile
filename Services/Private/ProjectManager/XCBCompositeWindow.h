#import "XCBWindow.h"

@interface XCBCompositeWindow : XCBWindow {
	xcb_pixmap_t pixmap;
	xcb_picture_t picture;
}
@end
