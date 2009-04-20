#import <EtoileFoundation/EtoileFoundation.h>
#import "PMConnectionDelegate.h"
#import "PMDecoratedWindow.h"
#import "XCBWindow.h"
#import "PMCompositeWindow.h"
#include  <xcb/xcb.h>
#include <xcb/damage.h>

@implementation PMConnectionDelegate
- (id)init
{
	SUPERINIT;
	documentWindows = [NSMutableSet new];
	panelWindows = [NSMutableSet new];
	decorationWindows = [NSMutableSet new];
	compositeWindows = [NSMutableSet new];
	decorations = [NSMutableDictionary new];
	[[XCBConnection sharedConnection] setDelegate: self];

	xcb_connection_t *connection = [XCBConn connection];
	const char *damageName = "DAMAGE";
	xcb_query_extension_cookie_t cookie = 
		xcb_query_extension(connection, strlen(damageName), damageName);
	// FIXME: Check for error
	xcb_query_extension_reply_t *reply = 
		xcb_query_extension_reply(connection, cookie, NULL);
	free(reply);

	NSLog(@"First event: %d", reply->first_event);
	[XCBConn setSelector: @selector(XCBConnection:damageAdd:)
	           forXEvent: reply->first_event + XCB_DAMAGE_ADD];
	xcb_damage_query_version(connection, 1, 1);

	PMApp = self;
	return self;
}
- (void)XCBConnection: (XCBConnection*)connection 
            damageAdd: (struct xcb_damage_add_request_t*)request
{
	NSLog(@"Adding damage in %d", (int)request->drawable);
	XCBRect big = XCBMakeRect(0,0,0xffff, 0xffff);
	FOREACH(compositeWindows, win, PMCompositeWindow*)
	{
		[win drawXCBRect: big];
	}
}
- (void)XCBConnection: (XCBConnection*)connection 
            mapWindow: (XCBWindow*)window
{
	[[decorations objectForKey: window] mapDecoratedWindow];
}
- (void)XCBConnection: (XCBConnection*)connection 
      handleNewWindow: (XCBWindow*)window
{
	if (![decorationWindows containsObject: window])
	{
		id win = [PMDecoratedWindow windowDecoratingWindow: window];
		[decorationWindows addObject: win];
		[decorations setObject: win forKey: window];
		[decorationWindows addObject: [win decorationWindow]];
		PMCompositeWindow *compositeWin = 
			[PMCompositeWindow compositeWindowWithXCBWindow: [win decorationWindow]];
		[compositeWindows addObject: compositeWin];
	}
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
