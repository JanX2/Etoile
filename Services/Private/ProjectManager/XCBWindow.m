#import "XCBWindow.h"
#import <EtoileFoundation/EtoileFoundation.h>


NSString *XCBWindowFrameDidChangeNotification = @"XCBWindowFrameDidChangeNotification";

@implementation XCBWindow
- (XCBWindow*) initWithXCBWindow: (xcb_window_t)aWindow
{
	SELFINIT;
	window = aWindow;
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
		xcb_create_window_checked(conn, 0, winid, window, aRect.origin.x, aRect.origin.y, aRect.size.width, aRect.size.height, 10, XCB_WINDOW_CLASS_INPUT_OUTPUT, 0,0,0)
	);
	if (error) { NSLog(@"Error %d", error->error_code);}

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
- (XCBWindow*) initWithCreateEvent: (xcb_create_notify_event_t*)anEvent
{
	SELFINIT;
	NSLog(@"Creating window with parent: %d", (int)anEvent->parent);
	parent = [[XCBConn windowForXCBId: anEvent->parent] retain];
	window = anEvent->window;
	frame = XCBMakeRect(anEvent->x, anEvent->y, anEvent->width, anEvent->height);
	[XCBConn registerWindow: self];
	return self;
}
+ (XCBWindow*) windowWithCreateEvent: (xcb_create_notify_event_t*)anEvent
{
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
