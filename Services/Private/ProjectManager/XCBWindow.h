#import "XCBScreen.h"
#import "XCBGeometry.h"

@interface XCBWindow : NSObject {
	xcb_window_t window;
	XCBRect frame;
	XCBWindow *parent;
}
+ (XCBWindow*)windowWithXCBWindow: (xcb_window_t)aWindow;
+ (XCBWindow*)windowWithCreateEvent: (xcb_create_notify_event_t*)anEvent;
- (XCBWindow*)createChildInRect: (XCBRect)aRect;
- (XCBRect)frame;
- (void)setFrame: (XCBRect)aRect;
- (XCBWindow*)parent;
- (xcb_window_t) xcbWindowId;
- (void)handleConfigureNotifyEvent: (xcb_configure_notify_event_t*)anEvent;
- (void)addToSaveSet;
- (void)removeFromSaveSet;
@end

extern NSString *XCBWindowFrameDidChangeNotification;
