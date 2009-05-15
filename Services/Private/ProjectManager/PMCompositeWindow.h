#import "XCBWindow.h"
#import "PMNotifications.h"
#include <xcb/render.h>

@interface PMCompositeWindow : NSObject {
	NSMutableArray *decorations;
	XCBWindow *window;
	xcb_pixmap_t pixmap;
	xcb_render_picture_t picture;
	xcb_render_picture_t root;
	xcb_render_transform_t transform;
	XCBRect scaledFrame;
}
+ (void)drawBackground;
+ (void)setClipRegionFromDamage: (struct xcb_damage_notify_event_t*)request;
+ (void)clearClipRegion;
+ (PMCompositeWindow*)compositeWindowWithXCBWindow: (XCBWindow*)aWindow;
- (void)setRootPicture: (xcb_render_picture_t)aPicture;
- (xcb_render_picture_t)picture;
- (void)drawXCBRect: (XCBRect)aRect;
- (XCBWindow*)window;
- (xcb_render_picture_t)rootPicture;
@end

@protocol PMCompositeWindowDecotating
- (void) decorateWindow: (PMCompositeWindow*)aWindow 
                 onRoot: (xcb_render_picture_t)rootPicture
                 inRect: (XCBRect)aRect;
@end
