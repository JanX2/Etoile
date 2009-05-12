#import <Foundation/Foundation.h>
#import "XCBConnection.h"

@interface PMConnectionDelegate : NSObject {
	NSMutableSet *documentWindows;
	NSMutableSet *panelWindows;
	NSMutableDictionary *decorationWindows;
	NSMutableSet *compositeWindows;
	NSMutableDictionary *compositers;
	NSMutableDictionary *decoratedWindows;
}
- (void)XCBConnection: (XCBConnection*)connection
      handleNewWindow: (XCBWindow*)window;
- (void)XCBConnection: (XCBConnection*)connection
            mapWindow: (XCBWindow*)window;
-      (void)XCBConnection: (XCBConnection*)connection 
handleConfigureNotifyEvent: (xcb_configure_notify_event_t*)anEvent;
@end

PMConnectionDelegate *PMApp;
