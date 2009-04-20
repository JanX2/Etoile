#import <Foundation/Foundation.h>
#include <xcb/xcb.h>

@class XCBWindow;

@interface XCBConnection : NSObject {
	xcb_connection_t *connection;
	NSFileHandle *handle;
	NSMutableArray *screens;
	NSMutableArray *replyHandlers;
	NSMapTable *windows;
	id delegate;
	SEL extensionSelectors[256];
}
+ (XCBConnection*)sharedConnection;
- (xcb_connection_t*) connection;
- (void) setDelegate: (id)aDelegate;
- (void) setSelector: (SEL)aSelector forXEvent: (uint8_t)anEvent;
- (NSArray*) screens;
- (XCBWindow*) windowForXCBId: (xcb_window_t)anId;
- (void) registerWindow: (XCBWindow*)aWindow;
- (void)setHandler: (id)anObject 
          forReply: (unsigned int)sequence
          selector: (SEL)aSelector;
@end

/**
 * Shared global XCB connection.  Only one connection may exist per process.
 * This variable is invalid before the first call to XCBConnection
 * +sharedConnection.
 */
extern XCBConnection *XCBConn;
