#import <EtoileFoundation/EtoileFoundation.h>
#import "PMConnectionDelegate.h"
#import "PMDecoratedWindow.h"
#import "XCBWindow.h"
#import "PMCompositeWindow.h"
#include  <xcb/xcb.h>
#include <xcb/damage.h>
#include <xcb/composite.h>

@implementation PMConnectionDelegate
- (void)redirectRoots
{
	xcb_connection_t *conn = [XCBConn connection];
	FOREACH([XCBConn screens], screen, XCBScreen*)
	{
		xcb_window_t root = [[screen rootWindow] xcbWindowId];
		xcb_composite_redirect_subwindows(conn, root, XCB_COMPOSITE_REDIRECT_MANUAL);
		xcb_query_tree_cookie_t cookie = xcb_query_tree(conn, root);
		[XCBConn setHandler: self
				   forReply: cookie.sequence
				   selector: @selector(handleQueryTree:)];
	}
	xcb_flush(conn);
}
- (void)handleQueryTree: (xcb_query_tree_reply_t*)reply
{
	NSLog(@"Query tree reply received.");
	xcb_window_t *windows = xcb_query_tree_children(reply);
	int end = xcb_query_tree_children_length(reply);
	xcb_window_t window = windows[0];
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	for (int i=0; i<end ; window = windows[++i])
	{
		NSLog(@"Querying geometry for %x", window);
		XCBWindow *win = [XCBWindow windowWithXCBWindow: window];
		[center addObserver: self
				   selector: @selector(geometryChanged:)
					   name: XCBWindowFrameDidChangeNotification
					 object: win];
	}
	xcb_flush([XCBConn connection]);
}
- (void) geometryChanged: (NSNotification*)aNotification
{
	id win = [aNotification object];
	[self XCBConnection: XCBConn
	          mapWindow: win];
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center removeObserver: self
	                  name: XCBWindowFrameDidChangeNotification
	                object: win];
}
- (void)dealloc
{
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center removeObserver: self];
	[documentWindows release];
	[panelWindows release];
	[decorationWindows release];
	[compositeWindows release];
	[compositers release];
	[decorations release];
	[super dealloc];
}
- (id)init
{
	SUPERINIT;
	documentWindows = [NSMutableSet new];
	panelWindows = [NSMutableSet new];
	decorationWindows = [NSMutableSet new];
	compositeWindows = [NSMutableSet new];
	decorations = [NSMutableDictionary new];
	compositers = [NSMutableDictionary new];
	[[XCBConnection sharedConnection] setDelegate: self];

	xcb_connection_t *connection = [XCBConn connection];
	const char *damageName = "DAMAGE";
	xcb_query_extension_cookie_t cookie = 
		xcb_query_extension(connection, strlen(damageName), damageName);
	// FIXME: Check for error
	xcb_query_extension_reply_t *reply = 
		xcb_query_extension_reply(connection, cookie, NULL);

	NSLog(@"First event: %d", reply->first_event);
	[XCBConn setSelector: @selector(XCBConnection:damageAdd:)
	           forXEvent: reply->first_event + XCB_DAMAGE_NOTIFY];
	free(reply);
	xcb_damage_query_version(connection, 1, 1);


	PMApp = self;
	[self redirectRoots];
	return self;
}
- (void)XCBConnection: (XCBConnection*)connection 
            damageAdd: (struct xcb_damage_notify_event_t*)request
{
	NSLog(@"Adding damage in %x", (int)request->drawable);
	XCBRect big = XCBMakeRect(0,0,0xffff, 0xffff);
	NSLog(@"Composite windows: %@", compositeWindows);
	FOREACH(compositeWindows, win, PMCompositeWindow*)
	{
		[win drawXCBRect: big];
	}
}
- (void)XCBConnection: (XCBConnection*)connection 
            mapWindow: (XCBWindow*)window
{
	if (![decorationWindows containsObject: window])
	{
		[window addToSaveSet];
		id win = [PMDecoratedWindow windowDecoratingWindow: window];
		[decorations setObject: win forKey: window];
		id decorationWindow = [win decorationWindow];
		[decorationWindows addObject: decorationWindow];
		NSLog(@"Creating composite window for decoration window %@", decorationWindow);
		PMCompositeWindow *compositeWin = 
			[PMCompositeWindow compositeWindowWithXCBWindow: decorationWindow];
		[compositeWindows addObject: compositeWin];
		[compositers setObject: compositeWin forKey: decorationWindow];
		NSNotificationCenter *center =
			[NSNotificationCenter defaultCenter];
		[center addObserver: self
				   selector: @selector(windowDidUnMap:)
					   name: XCBWindowDidUnMapNotification
					 object: window];
	}
	[[decorations objectForKey: window] mapDecoratedWindow];
}
- (void)windowDidUnMap: (NSNotification*)aNotification
{
	XCBWindow *win = [aNotification object];
	PMCompositeWindow *comp = [compositers objectForKey: win];
	[compositeWindows removeObject: comp];
	[compositers removeObjectForKey: win];
	NSLog(@"Removed window: %@", compositeWindows);
}
- (void)XCBConnection: (XCBConnection*)connection 
      handleNewWindow: (XCBWindow*)window
{
}
-      (void)XCBConnection: (XCBConnection*)connection 
handleConfigureNotifyEvent: (xcb_configure_notify_event_t*)anEvent
{
	XCBWindow *win = [connection windowForXCBId: anEvent->window];
	NSLog(@"Configuring window...");
	[win handleConfigureNotifyEvent: anEvent];
	if ([documentWindows containsObject: win])
	{
		
	}
}
@end
