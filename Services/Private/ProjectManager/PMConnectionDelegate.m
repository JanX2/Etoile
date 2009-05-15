#import <EtoileFoundation/EtoileFoundation.h>
#import "PMConnectionDelegate.h"
#import "PMDecoratedWindow.h"
#import "XCBWindow.h"
#import "PMCompositeWindow.h"
#include  <xcb/xcb.h>
#include <xcb/damage.h>
#include <xcb/composite.h>

@implementation PMConnectionDelegate
- (void)newWindow: (XCBWindow*)window
{
	NSLog(@"New window: %@", window);
	NSLog(@"\nDecoration: %@\nDecorated: %@", decorationWindows, decoratedWindows);
	if (![decorationWindows objectForKey: window] 
		 && ![decoratedWindows objectForKey: window])
	{
		xcb_set_input_focus([XCBConn connection], XCB_INPUT_FOCUS_PARENT, [window xcbWindowId], 0);
		NSLog(@"New window: %@", window);
		[window addToSaveSet];
		PMDecoratedWindow *win = [PMDecoratedWindow windowDecoratingWindow: window];
		XCBWindow *decorationWindow = [win decorationWindow];
		NSLog(@"New decoration window: %@", decorationWindow);
		[decorationWindows setObject: window forKey: decorationWindow];
		[decoratedWindows setObject: decorationWindow forKey: window];
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
					 object: decorationWindow];
		[center addObserver: self
				   selector: @selector(windowDidDestroy:)
					   name: XCBWindowDidDestroyNotification
					 object: window];
		NSLog(@"%@, %@, %@", window, decorationWindow, compositeWin);
		[win mapDecoratedWindow];
	}
}
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
	[self newWindow: win];
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
	[decoratedWindows release];
	[super dealloc];
}
- (id)init
{
	SUPERINIT;
	documentWindows = [NSMutableSet new];
	panelWindows = [NSMutableSet new];
	decorationWindows = [NSMutableDictionary new];
	compositeWindows = [NSMutableArray new];
	decoratedWindows = [NSMutableDictionary new];
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

	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center addObserver: self
			   selector: @selector(windowDidMap:)
				   name: XCBWindowDidMapNotification 
				 object: nil];
	/*
	[center addObserver: self
			   selector: @selector(windowPlacedOnBottom:)
				   name: XCBWindowWindowPlacedOnBottomNotification
				 object: nil];
	[center addObserver: self
			   selector: @selector(windowPlacedOnTop:)
				   name: XCBWindowWindowPlacedOnTopNotification
				 object: nil];
				 */

	PMApp = self;
	[self redirectRoots];
	return self;
}
- (void)redraw
{
	[PMCompositeWindow drawBackground];
	XCBRect big = XCBMakeRect(0, 0, 0xffff, 0xffff);
	FOREACH(compositeWindows, win, PMCompositeWindow*)
	{
		[win drawXCBRect: big];
	}
}
- (void)setNeedsDisplayInXCBRect: (XCBRect)aRect
{
	/*
	 * This should add the rectangle to the clip regions and post a damage
	 * notification thingy.
	xcb_connection_t *conn = [XCBConn connection];
	xcb_xfixes_region_t region = xcb_generate_id(conn);
	xcb_rectangle_t rect = XCBRectangleFromRect(aRect);
	xcb_xfixes_create_region(conn, region, 1, &rect);

	xcb_xfixes_destroy_region(conn, region);
	*/
	[PMCompositeWindow clearClipRegion];
	[self redraw];
}
- (void)XCBConnection: (XCBConnection*)connection 
            damageAdd: (struct xcb_damage_notify_event_t*)request
{
	// FIXME: This does a full redraw for any screen update, which is painfully
	// slow.  The point of the damage extension is to avoid this.  Set the clip
	// region on the root Picture before painting and the server will eliminate
	// redundant operations.
	//NSLog(@"Adding damage in %x", (int)request->drawable);
	//NSLog(@"Composite windows: %@", compositeWindows);
	[PMCompositeWindow setClipRegionFromDamage: request];
	[self redraw];
	[PMCompositeWindow clearClipRegion];
}
- (void)windowDidMap: (NSNotification*)aNotification
{
	XCBWindow *window = [aNotification object];
	[self newWindow: window];
}
- (void)removeCompositingForWindow: (XCBWindow*)win
{
	PMCompositeWindow *comp = [compositers objectForKey: win];
	if (nil != comp)
	{
		[compositeWindows removeObject: comp];
		[compositers removeObjectForKey: win];
		[self setNeedsDisplayInXCBRect: [win frame]];
	}
}
- (void)windowDidUnMap: (NSNotification*)aNotification
{
	[self removeCompositingForWindow: [aNotification object]];
}
- (void)windowDidDestroy: (NSNotification*)aNotification
{
	XCBWindow *win = [aNotification object];
	XCBWindow *decoratedWin = [decoratedWindows objectForKey: win];
	[self removeCompositingForWindow: win];
	[self removeCompositingForWindow: decoratedWin];
	[decorationWindows removeObjectForKey: decoratedWin];
	[decoratedWindows removeObjectForKey: win];
}
- (void)windowPlacedOnBottom: (NSNotification*)aNotification
{
	XCBWindow *win = [aNotification object];
//	PMCompositeWindow *comp = 
}
@end
