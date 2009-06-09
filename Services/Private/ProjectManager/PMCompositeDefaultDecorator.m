#import "PMCompositeDefaultDecorator.h"

@implementation PMCompositeDefaultDecorator
- (void) decorateWindow: (PMCompositeWindow*)aWindow 
                 onRoot: (xcb_render_picture_t)rootPicture
                 inRect: (XCBRect)aRect
{
	XCBRect frame = [[aWindow window] frame];
	xcb_render_picture_t picture = [aWindow picture];
	xcb_connection_t *conn = [XCBConn connection];
	xcb_render_composite(conn, XCB_RENDER_PICT_OP_ATOP,
			picture, 0, rootPicture, 
			0, 0,
			0, 0,
			frame.origin.x, frame.origin.y, 
			frame.size.width, frame.size.height);
}
@end
