/**
 * Étoilé ProjectManager - XCBWindow.m
 *
 * Copyright (C) 2009 David Chisnall
 * Copyright (C) 2010 Christopher Armstrong <carmstrong@fastmail.com.au>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 **/
#import "XCBWindow.h"
#import "XCBVisual.h"
#import <EtoileFoundation/EtoileFoundation.h>

@implementation XCBWindow
- (XCBWindow*)initWithXCBWindow: (xcb_window_t)aWindow 
                         parent: (xcb_window_t)parent_id
{
	SELFINIT;
	window = aWindow;
	xcb_get_geometry_cookie_t cookie =
		xcb_get_geometry([XCBConn connection], window);
	[XCBConn setHandler: self
			   forReply: cookie.sequence
			   selector: @selector(setGeometry:)];
	[XCBConn setNeedsFlush:YES];
	parent = [[XCBConn windowForXCBId:parent_id] retain];
	// Even though we know the parent, we need the window
	// attributes to do some other stuff like the window class
	[self updateWindowAttributes];
	[XCBConn registerWindow: self];
	return self;
}
- (void) dealloc
{
	[parent release];
	[super dealloc];
}
+ (XCBWindow*)windowWithXCBWindow: (xcb_window_t)aWindow 
                           parent: (xcb_window_t)parent_id
{
	// Don't create multiple objects for the same window.
	id win = [XCBConn windowForXCBId: aWindow];
	if (nil != win)
	{
		return win;
	}
	return [[[self alloc] initWithXCBWindow: aWindow parent:parent_id] autorelease];
}
+ (XCBWindow*)findXCBWindow: (xcb_window_t)aWindow
{
	return [XCBConn windowForXCBId:aWindow];
}
- (id)copyWithZone: (NSZone*)aZone
{
	// Window objects are unique.  Copying should not do anything.
	return [self retain];
}
- (void)setDelegate: (id)del
{
	self->delegate = del;
}
- (id)delegate
{
	return delegate;
}
- (void)updateWindowAttributes
{
	xcb_get_window_attributes_cookie_t acookie = 
		xcb_get_window_attributes([XCBConn connection], window);
	[XCBConn setHandler: self
		forReply:acookie.sequence
		selector: @selector(setWindowAttributes:)];
	[XCBConn setNeedsFlush:YES];
}

- (void)handleCirculateNotifyEvent: (xcb_circulate_notify_event_t*)anEvent
{
	if (anEvent == XCB_PLACE_ON_TOP)
	{
		XCBDELEGATE(WindowPlacedOnTop);
		XCBNOTIFY(WindowPlacedOnTop);
	}
	else
	{
		XCBDELEGATE(WindowPlacedOnBottom);
		XCBNOTIFY(WindowPlacedOnBottom);
	}
}
- (void)handleExpose: (xcb_expose_event_t*)anEvent
{
	XCBRect exposeRect = XCBMakeRect(anEvent->x, anEvent->y, anEvent->width, anEvent->height);
	NSDictionary *userInfo = [NSDictionary 
		dictionaryWithObjectsAndKeys:
			[NSValue valueWithBytes:&exposeRect objCType:@encode(XCBRect)],
			@"Rect",
			[NSNumber numberWithInt:anEvent->count],
			@"Count",
			nil];
	XCBDELEGATE_U(WindowExpose, userInfo);
	XCBNOTIFY_U(WindowExpose, userInfo);
}
- (XCBWindow*)createChildInRect: (XCBRect)aRect
{
	xcb_generic_error_t  *error;
	xcb_connection_t *conn = [XCBConn connection];
	xcb_window_t winid = xcb_generate_id(conn);
	error = xcb_request_check(conn, 
		xcb_create_window_checked(conn, 0, winid, window, aRect.origin.x,
			aRect.origin.y, aRect.size.width, aRect.size.height, 0,
			XCB_WINDOW_CLASS_INPUT_OUTPUT, 0,0,0));
	if (error)
	{
		NSLog(@"Error %d creating window.", error->error_code); 
		free(error);
		return nil;
	}

	xcb_map_window(conn, winid);
	xcb_flush(conn);
	NSLog(@"Creating child window %x", winid);
	return [isa windowWithXCBWindow: winid parent:self->window];
}
- (void)destroy
{
	xcb_destroy_window([XCBConn connection], window);
}
- (void)map
{
	xcb_map_window([XCBConn connection], window);
}
- (void)unmap
{
	xcb_map_window([XCBConn connection], window);
}
- (void)handleConfigureNotifyEvent: (xcb_configure_notify_event_t*)anEvent
{
	XCBWindow *aboveWindow = [XCBWindow findXCBWindow:anEvent->above_sibling];
	XCBRect frameRect = XCBMakeRect(anEvent->x, anEvent->y,
		anEvent->width, anEvent->height);
	NSValue *frameRectValue = [NSValue 
		valueWithBytes:&frameRect
		objCType:@encode(XCBRect)];
	NSValue *borderWidth = [NSNumber numberWithInt:anEvent->border_width];	
	NSDictionary *userInfo = 
		[NSDictionary dictionaryWithObjectsAndKeys:
		frameRectValue, @"Rect",
		borderWidth, @"BorderWidth",
		aboveWindow, @"Above", // Place last as aboveWindow == nil, which then cuts off the rest of the dictionary (and hence it is absent, indicating stacked at the bottom). maybe we should have the concept of a nil window or just [NSNull null]
		nil];
		
	XCBDELEGATE_U(WindowFrameWillChange, userInfo);
	XCBNOTIFY_U(WindowFrameWillChange, userInfo);
	frame = XCBMakeRect(anEvent->x, anEvent->y, anEvent->width, anEvent->height);
	border_width = anEvent->border_width;
	XCBDELEGATE_U(WindowFrameDidChange, userInfo);
	XCBNOTIFY_U(WindowFrameDidChange, userInfo);
}
- (void)handleDestroyNotifyEvent: (xcb_destroy_notify_event_t*)anEvent
{
	XCBDELEGATE(WindowDidDestroy);
	XCBNOTIFY(WindowDidDestroy);
	[XCBConn cancelHandlersForObject: self];
	[XCBConn unregisterWindow: self];
}
- (void)handleUnMapNotifyEvent: (xcb_unmap_notify_event_t*)anEvent
{
	XCBDELEGATE(WindowWillUnMap);
	XCBNOTIFY(WindowWillUnMap);
	NSLog(@"Umapping %@", self);
	attributes.map_state =XCB_MAP_STATE_UNMAPPED;
	XCBDELEGATE(WindowDidUnMap);
	XCBNOTIFY(WindowDidUnMap);
}
- (void)handleMapNotifyEvent: (xcb_map_notify_event_t*)anEvent
{
	attributes.map_state =XCB_MAP_STATE_VIEWABLE;
	XCBDELEGATE(WindowDidMap);
	XCBNOTIFY(WindowDidMap);
}
- (void)setGeometry: (xcb_get_geometry_reply_t*)reply
{
	frame = XCBMakeRect(reply->x, reply->y, reply->width, reply->height);
	border_width = reply->border_width;
	parent = [[XCBConn windowForXCBId: reply->root] retain];
	XCBDELEGATE(WindowFrameDidChange);
	XCBNOTIFY(WindowFrameDidChange);
}
- (void)handleCreateEvent: (xcb_create_notify_event_t*)anEvent
{
	NSLog(@"Handling create event...");
	window = anEvent->window;
	frame = XCBMakeRect(anEvent->x, anEvent->y, anEvent->width, anEvent->height);
	border_width = anEvent->border_width;
	parent = [[XCBConn windowForXCBId: anEvent->parent] retain];
	[self updateWindowAttributes];
	XCBDELEGATE(WindowDidCreate);
	XCBNOTIFY(WindowDidCreate);
}
- (XCBWindow*)initWithCreateEvent: (xcb_create_notify_event_t*)anEvent
{
	SELFINIT;
	NSLog(@"Creating window with parent: %d", (int)anEvent->parent);
	window = anEvent->window;
	parent = [[XCBWindow findXCBWindow:anEvent->parent] retain];
	[XCBConn registerWindow: self];
	[self handleCreateEvent: anEvent];
	return self;
}
+ (XCBWindow*)windowWithCreateEvent: (xcb_create_notify_event_t*)anEvent
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
- (XCBWindow*)parent
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
	[XCBConn setNeedsFlush:YES];
}
- (xcb_window_t)xcbWindowId
{
	return window;
}

- (int16_t)borderWidth
{
	return border_width;
}
- (xcb_drawable_t) xcbDrawableId
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
- (void)setWindowAttributes:(xcb_get_window_attributes_reply_t*)reply
{
	attributes = *reply;
	XCBDELEGATE(WindowAttributesDidChange);
	XCBNOTIFY(WindowAttributesDidChange);
}
- (xcb_visualid_t)visual
{
	return attributes.visual;
}
- (xcb_window_class_t)windowClass
{
	return attributes._class;
}
- (xcb_map_state_t)mapState
{
	return attributes.map_state;
}
- (NSUInteger)hash
{
	return (NSUInteger)window;
}
- (BOOL)isEqual: (id)anObject
{
	return [anObject isKindOfClass: [XCBWindow class]] &&
		[anObject xcbWindowId] == window;
}
- (NSString*)description
{
	return [NSString stringWithFormat:@"%@ XID: %x (%@)", [super description],
		   window,
		   XCBStringFromRect(frame)];
}

@end
