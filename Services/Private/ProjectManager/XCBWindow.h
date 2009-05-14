#import "XCBScreen.h"
#import "XCBGeometry.h"

// FIXME: Change frame/setFrame: to avoid type conflict with NSWindow

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
- (void) handleUnMapNotifyEvent: (xcb_unmap_notify_event_t*)anEvent;
- (void) handleDestroyNotifyEvent: (xcb_destroy_notify_event_t*)anEvent;
- (void) handleCirculateNotifyEvent: (xcb_circulate_notify_event_t*)anEvent;
- (void) handleMapNotifyEvent: (xcb_map_notify_event_t*)anEvent;
- (void)addToSaveSet;
- (void)removeFromSaveSet;
- (void)destroy;
- (void)map;
- (void)unmap;
@end
