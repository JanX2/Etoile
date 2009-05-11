#import "XCBWindow.h"
#import <EtoileFoundation/EtoileFoundation.h>


NSString *XCBWindowFrameDidChangeNotification = @"XCBWindowFrameDidChangeNotification";

@implementation XCBWindow
- (XCBWindow*) initWithXCBWindow: (xcb_window_t)aWindow
{
	SELFINIT;
	window = aWindow;
	xcb_get_geometry_cookie_t cookie =
		xcb_get_geometry([XCBConn connection], window);
	[XCBConn setHandler: self
			   forReply: cookie.sequence
			   selector: @selector(setGeometry:)];
	[XCBConn registerWindow: self];
	return self;
}
+ (XCBWindow*) windowWithXCBWindow: (xcb_window_t)aWindow
{
	// Don't create multiple objects for the same window.
	id win = [XCBConn windowForXCBId: aWindow];
	if (nil != win)
	{
		return win;
	}
	return [[[self alloc] initWithXCBWindow: aWindow] autorelease];
}
- (id)copyWithZone: (NSZone*)aZone
{
	return [[[self class] allocWithZone: aZone] initWithXCBWindow: window];
}
- (XCBWindow*) createChildInRect: (XCBRect)aRect
{
	xcb_generic_error_t  *error;
	xcb_connection_t *conn = [XCBConn connection];
	xcb_window_t winid = xcb_generate_id(conn);
	error = xcb_request_check(conn, 
		xcb_create_window_checked(conn, 0, winid, window, aRect.origin.x,
			aRect.origin.y, aRect.size.width, aRect.size.height, 10,
			XCB_WINDOW_CLASS_INPUT_OUTPUT, 0,0,0));
	if (error)
	{
		NSLog(@"Error %d creating window.", error->error_code); 
		free(error);
		return nil;
	}

	xcb_map_window(conn, winid);
	xcb_flush(conn);
	return [isa windowWithXCBWindow: winid];
}
- (void)handleConfigureNotifyEvent: (xcb_configure_notify_event_t*)anEvent
{
	frame = XCBMakeRect(anEvent->x, anEvent->y, anEvent->width, anEvent->height);
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center postNotificationName: XCBWindowFrameDidChangeNotification
	                      object: self];
}
- (void)setGeometry: (xcb_get_geometry_reply_t*)reply
{
	frame = XCBMakeRect(reply->x, reply->y, reply->width, reply->height);
	parent = [[XCBConn windowForXCBId: reply->root] retain];
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center postNotificationName: XCBWindowFrameDidChangeNotification
	                      object: self];
}
- (void)handleCreateEvent: (xcb_create_notify_event_t*)anEvent
{
	NSLog(@"Handling create event...");
	parent = [[XCBConn windowForXCBId: anEvent->parent] retain];
	window = anEvent->window;
	frame = XCBMakeRect(anEvent->x, anEvent->y, anEvent->width, anEvent->height);
}
- (XCBWindow*) initWithCreateEvent: (xcb_create_notify_event_t*)anEvent
{
	SELFINIT;
	NSLog(@"Creating window with parent: %d", (int)anEvent->parent);
	[self handleCreateEvent: anEvent];
	[XCBConn registerWindow: self];
	return self;
}
+ (XCBWindow*) windowWithCreateEvent: (xcb_create_notify_event_t*)anEvent
{
	// Don't create multiple objects for the same window.
	id win = [XCBConn windowForXCBId: anEvent->window];
	if (nil != win)
	{
		[win handleCreateEvent: anEvent];
		return win;
	}
	return [[[self alloc] initWithCreateEvent: anEvent] autorelease];
}
- (XCBWindow*) parent
{
	return parent;
}
- (XCBRect)frame
{
	return frame;
}
- (void)setFrame: (XCBRect)aRect
{
	uint32_t values[4];
	unsigned int i = 0;
	uint16_t mask = 0;
	// Only send the components that have changed to the server.
	// This can save some work on the server side, and later.
	if (aRect.origin.x != frame.origin.x)
	{
		values[i++] = aRect.origin.x;
		mask |= XCB_CONFIG_WINDOW_X;
	}
	if (aRect.origin.y != frame.origin.y)
	{
		values[i++] = aRect.origin.y;
		mask |= XCB_CONFIG_WINDOW_Y;
	}
	if (aRect.size.width != frame.size.width)
	{
		values[i++] = aRect.size.width;
		mask |= XCB_CONFIG_WINDOW_WIDTH;
	}
	if (aRect.size.height != frame.size.height)
	{
		values[i++] = aRect.size.height;
		mask |= XCB_CONFIG_WINDOW_HEIGHT;
	}
	xcb_connection_t *conn = [XCBConn connection];
	xcb_configure_window(conn, window, mask, values);
	xcb_flush(conn);
}
- (xcb_window_t) xcbWindowId
{
	return window;
}
- (void)addToSaveSet
{
	xcb_change_save_set([XCBConn connection], XCB_SET_MODE_INSERT, window);
}
- (void)removeFromSaveSet
{
	xcb_change_save_set([XCBConn connection], XCB_SET_MODE_DELETE, window);
}
- (NSUInteger)hash
{
	return (NSUInteger)window;
}
- (BOOL)isEqual:(id)anObject
{
	return [anObject isKindOfClass: [XCBWindow class]] &&
		[anObject xcbWindowId] == window;
}
- (NSString*) description
{
	return [NSString stringWithFormat:@"%@ (%@)", [super description],
		   XCBStringFromRect(frame)];
}
@end
