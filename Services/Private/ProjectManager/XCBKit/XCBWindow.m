/*
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
#import "XCBWindow+Package.h"
#import <XCBKit/XCBVisual.h>
#import <XCBKit/XCBAtomCache.h>
#import <XCBKit/XCBCachedProperty.h>
#import <EtoileFoundation/EtoileFoundation.h>

#import <Foundation/NSNull.h>

/**
  * This enumeration is used to keep track
  * of the values we have successfully cached
  * so far. It is needed so that we know when
  * we may transition into the XCBWindowAvailableState
  * when there is multiple things that need to be 
  * requested, like geometry and attributes.
  */
enum _XCBWindowLoadedValues
{
	XCBWindowLoadedNothing = 0,
	XCBWindowLoadedAttributes = 1,
	XCBWindowLoadedGeometry = 2,
	XCBWindowLoadedEverything = XCBWindowLoadedAttributes | XCBWindowLoadedGeometry
};

/**
  * The unknown window, see +[XCBWindow unknownWindow]
  */
static XCBWindow* UnknownWindow;

@interface XCBWindow (Private)
- (XCBWindow*)initWithXCBWindow: (xcb_window_t)aWindow 
                         parent: (xcb_window_t)parent_id
                          above: (xcb_window_t)above_sibling;
- (void) checkIfAvailable;
- (XCBWindow*)initWithNewXCBWindow: (xcb_window_t)new_window_id;
- (void)requestProperty: (NSString*)property atomValue: (NSNumber*)atom;
- (void)handleCreateEvent: (xcb_create_notify_event_t*)anEvent;
@end

@implementation XCBWindow
+ (void)initialize
{
	UnknownWindow = [[XCBWindow alloc]
		initWithXCBWindow: 0 parent: 0 above: 0];
}
+ (XCBWindow*)unknownWindow
{
	return UnknownWindow;
}

- (void) dealloc
{
	[parent release];
	[above release];
	[cached_property_values release];
	[super dealloc];
}
+ (XCBWindow*)windowWithXCBWindow: (xcb_window_t)aWindow 
{
	return [self windowWithXCBWindow: aWindow parent: 0];
}
+ (XCBWindow*)windowWithXCBWindow: (xcb_window_t)aWindow 
                           parent: (xcb_window_t)parent_id
{
	// If a 0 (None) window is specified, just return
	// nothing.
	if (aWindow == 0)
		return nil;
	// Don't create multiple objects for the same window.
	id win = [XCBConn windowForXCBId: aWindow];
	if (nil != win)
	{
		return win;
	}
	return [[[self alloc] initWithXCBWindow: aWindow parent: parent_id above: 0] autorelease];
}
+ (XCBWindow*)windowWithXCBWindow: (xcb_window_t)aWindow 
                           parent: (xcb_window_t)parent
                            above: (xcb_window_t)above;
{
	// If a 0 (None) window is specified, just return
	// nothing.
	if (aWindow == 0)
		return nil;
	// Don't create multiple objects for the same window.
	id win = [XCBConn windowForXCBId: aWindow];
	if (nil != win)
	{
		return win;
	}
	return [[[self alloc] 
		initWithXCBWindow: aWindow 
		           parent: parent 
		            above: above] 
			autorelease];
}
- (XCBWindowLoadState) windowLoadState
{
	return window_load_state;
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
	[XCBConn setNeedsFlush: YES];
}
- (void)changeWindowAttributes: (uint32_t)mask
                        values: (const uint32_t*)values
{
	xcb_void_cookie_t c = xcb_change_window_attributes_checked(
		[XCBConn connection],
		window,
		mask,
		values);
	[XCBConn setHandler: self
	           forReply: c.sequence
	          selector: @selector(changeWindowAttributesReply:)];
	[XCBConn setNeedsFlush: YES];
}
- (void)changeWindowAttributesReply: (void*)c
{
	NSDebugLLog(@"XCBWindow", @"XCBWindow: change window attributes succeeded.");
}
- (XCBWindow*)createChildInRect: (XCBRect)aRect
                    borderWidth: (uint16_t)borderWidth
{
	return [self createChildInRect: aRect borderWidth: borderWidth valuesMask: 0 values: 0];
}

- (XCBWindow*)createChildInRect: (XCBRect)aRect
                    borderWidth: (uint16_t)borderWidth
                     valuesMask: (uint32_t)valuesMask
                         values: (const uint32_t*)valuesList
{
	return [self 
		createChildInRect: aRect
		      borderWidth: borderWidth
		       valuesMask: valuesMask
		           values: valuesList
		            depth: 0
		            class: 0
		           visual: 0];

}

- (XCBWindow*)createChildInRect: (XCBRect)aRect
                    borderWidth: (uint16_t)borderWidth
                     valuesMask: (uint32_t)valuesMask
                         values: (const uint32_t*)valuesList
                          depth: (uint8_t)depth
                          class: (xcb_window_class_t)windowClass
                         visual: (xcb_visualid_t)visual
{
	xcb_connection_t *conn = [XCBConn connection];
	xcb_window_t winid = xcb_generate_id(conn);
	/*xcb_void_cookie_t cookie =*/ xcb_create_window(
		conn,
		depth,
		winid,
		self->window,
		aRect.origin.x,
		aRect.origin.y,
		aRect.size.width,
		aRect.size.height,
		borderWidth,
		windowClass,
		visual,
		valuesMask,
		valuesList);
	XCBWindow *newWindow = [[[self class] alloc]
		initWithNewXCBWindow: winid];
	// All of these will be recached by the updateWindowAttributes
	// and setGeometry callbacks called in the init method,
	// but we may as well set them to the values that it was created
	// with.
	newWindow->parent = [self retain];
	newWindow->frame = aRect;
	newWindow->border_width = borderWidth;
	newWindow->attributes._class = windowClass;
	newWindow->attributes.visual = visual;
	// FIXME: Copy the valuesMask/valuesList
	NSDebugLLog(@"XCBWindow", @"-[XCBWindow createChildInRect: ..] Creating child window %x", winid);
	[XCBConn setNeedsFlush: YES];
	return newWindow;
}
- (void)destroy
{
	xcb_destroy_window([XCBConn connection], window);
	[XCBConn setNeedsFlush: YES];
}
- (void)destroyAndWait
{
	[self destroy];
	[self waitForState: XCBWindowDestroyedState];
}
- (BOOL)waitForState: (XCBWindowLoadState)state
{
	return [self waitForState: state
	               beforeDate: [NSDate distantFuture]];
}
- (BOOL)waitForState: (XCBWindowLoadState)state
          beforeDate: (NSDate*)date
{
	NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
	[XCBConn flush];
	while (window_load_state != state &&
		[[date laterDate: [NSDate date]] isEqual: date])
	{
		BOOL result = [runLoop 
			runMode: NSDefaultRunLoopMode
			beforeDate: date];
		if (NO == result)
			break;
	}
	return state == window_load_state;
}
- (void)map
{
	xcb_map_window([XCBConn connection], window);
	[XCBConn setNeedsFlush: YES];
}
- (void)unmap
{
	xcb_unmap_window([XCBConn connection], window);
	[XCBConn setNeedsFlush: YES];
}
- (void)reparentToWindow: (XCBWindow*)newParent
                      dX: (uint16_t)dx
                      dY: (uint16_t)dy
{
	xcb_reparent_window([XCBConn connection], window, [newParent xcbWindowId], dx, dy);
	//ASSIGN(parent, newParent);
	[XCBConn setNeedsFlush: YES];
}
- (void)setInputFocus: (uint8_t)revert_to
                 time: (xcb_timestamp_t)time
{
	xcb_set_input_focus([XCBConn connection], revert_to, window, time);
	[XCBConn setNeedsFlush: YES];
}
- (int)grabButton: (uint8_t)button
         modifiers: (uint16_t)modifiers
       ownerEvents: (uint8_t)ownerEvents
         eventMask: (uint16_t)eventMask
       pointerMode: (uint8_t)pointerMode
      keyboardMode: (uint8_t)keyboardMode
         confineTo: (XCBWindow*)confineWindow
            cursor: (xcb_cursor_t)cursor
{
	xcb_void_cookie_t cookie = xcb_grab_button([XCBConn connection],
		ownerEvents,
		[self xcbWindowId],
		eventMask,
		pointerMode,
		keyboardMode,
		confineWindow != nil ? [confineWindow xcbWindowId] : XCB_NONE,
		cursor,
		button,
		modifiers);
	[XCBConn setNeedsFlush: YES];
	xcb_generic_error_t *error = xcb_request_check([XCBConn connection], cookie);
	int error_code = 0;
	if (error)
	{
		NSLog(@"%@ error grabbing button %d: %d %d %d", self,
			button,
			error->response_type,
			error->error_code,
			error->sequence);
		error_code = error->error_code;
		free(error);
	}
	return error_code;
}

- (void)ungrabButton: (xcb_button_index_t)button
           modifiers: (uint16_t)modifiers
{
	xcb_ungrab_button([XCBConn connection],
		button,
		[self xcbWindowId],
		modifiers);
	[XCBConn setNeedsFlush: YES];
}
- (void)sendEvent: (uint32_t)event_mask
        propagate: (BOOL)propagate
             data: (const char*)event_data
{
	xcb_send_event([XCBConn connection],
		propagate ? 1 : 0,
		[self xcbWindowId],
		event_mask,
		event_data);
	[XCBConn setNeedsFlush: YES];
}
- (void)setGeometry: (xcb_get_geometry_reply_t*)reply
{
	frame = XCBMakeRect(reply->x, reply->y, reply->width, reply->height);
	border_width = reply->border_width;
	_cache_load_values |= XCBWindowLoadedGeometry;
	XCBDELEGATE(WindowFrameDidChange);
	XCBNOTIFY(WindowFrameDidChange);
	[self checkIfAvailable];
}
- (XCBWindow*)initWithCreateEvent: (xcb_create_notify_event_t*)anEvent
{
	SELFINIT;
	NSDebugLLog(@"XCBWindow", @"Creating window with parent: %d", (int)anEvent->parent);
	window = anEvent->window;
	// This will get updated again in handleCreateEvent, but
	// just to get around the NSAssert() and because this
	// window was obviously created through some external
	// means (in our programme or from another X11 client).
	window_load_state = XCBWindowCreatePendingState;
	_cache_load_values = XCBWindowLoadedGeometry;
	[XCBConn registerWindow: self];
	[self handleCreateEvent: anEvent];
	return self;
}
+ (XCBWindow*)windowWithCreateEvent: (xcb_create_notify_event_t*)anEvent
{
	// Don't create multiple objects for the same window.
	id win = [XCBWindow windowWithXCBWindow: anEvent->window];
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
	[self setFrame: aRect
	        border: [self borderWidth]];
}
- (void)setFrame: (XCBRect)aRect
          border: (int16_t)aBorderWidth
{
	uint32_t values[5];
	unsigned int i = 0;
	uint16_t mask = 0;
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
	if (border_width != aBorderWidth)
	{
		values[i++] = aBorderWidth;
		mask |= XCB_CONFIG_WINDOW_BORDER_WIDTH;
	}

	
	[self configureWindow: mask
	               values: values];
}
- (void)setFrame: (XCBRect)aRect
          border: (int16_t)aBorderWidth
           above: (XCBWindow*)anAbove
       stackMode: (xcb_stack_mode_t)stackMode
{
	uint32_t values[7];
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
	if (border_width != aBorderWidth)
	{
		values[i++] = aBorderWidth;
		mask |= XCB_CONFIG_WINDOW_BORDER_WIDTH;
	}

	values[i++] = [anAbove xcbWindowId];
	mask |= XCB_CONFIG_WINDOW_SIBLING;
	values[i++] = stackMode;
	mask |= XCB_CONFIG_WINDOW_STACK_MODE;
	
	[self configureWindow: mask
	               values: values];
}
- (void)moveWindow: (XCBPoint)newpoint
{
	uint32_t values[2];
	uint32_t mask = 0;
	int i = 0;
	if (newpoint.x != frame.origin.x)
	{
		values[i++] = newpoint.x;
		mask |= XCB_CONFIG_WINDOW_X;
	}
	if (newpoint.y != frame.origin.y)
	{
		values[i++] = newpoint.y;
		mask |= XCB_CONFIG_WINDOW_Y;
	}
	[self configureWindow: mask values: values];
}
- (void)restackRelativeTo: (XCBWindow*)otherWindow
                stackMode: (xcb_stack_mode_t)stackMode
{
	uint32_t values[2];
	uint16_t mask;
	if (nil != otherWindow)
	{
		mask = XCB_CONFIG_WINDOW_SIBLING |
			XCB_CONFIG_WINDOW_STACK_MODE;
		values[0] = [otherWindow xcbWindowId];
		values[1] = stackMode;
	}
	else
	{
		mask = XCB_CONFIG_WINDOW_STACK_MODE;
		values[0] = stackMode;
	}
	[self configureWindow: mask
	               values: values];
}
- (void)restackBelowWindow: (XCBWindow*)belowWindow
{
	[self restackRelativeTo: belowWindow
	              stackMode: XCB_STACK_MODE_BELOW];
}
- (void)restackAboveWindow: (XCBWindow*)aboveWindow
{
	[self restackRelativeTo: aboveWindow
	              stackMode: XCB_STACK_MODE_ABOVE];
}
- (void)setIgnoreSyntheticConfigureNotify: (BOOL)ig
{
	ignore_synthetic_configure_notify = ig;
}
- (BOOL)ignoreSyntheticConfigureNotify
{
	return ignore_synthetic_configure_notify;
}
- (void)configureWindow: (uint16_t)valueMask
                 values: (const uint32_t*)values
{
	xcb_configure_window([XCBConn connection],
		window,
		valueMask,
		values);
	[XCBConn setNeedsFlush: YES];
}

- (xcb_window_t)xcbWindowId
{
	return window;
}

- (int16_t)borderWidth
{
	return border_width;
}
- (xcb_drawable_t)xcbDrawableId
{
	return window;
}
- (void)addToSaveSet
{
	xcb_change_save_set([XCBConn connection], XCB_SET_MODE_INSERT, window);
	[XCBConn setNeedsFlush: YES];
}
- (void)removeFromSaveSet
{
	xcb_change_save_set([XCBConn connection], XCB_SET_MODE_DELETE, window);
	[XCBConn setNeedsFlush: YES];
}
- (void)setWindowAttributes:(xcb_get_window_attributes_reply_t*)reply
{
	attributes = *reply;
	_cache_load_values |= XCBWindowLoadedAttributes;
	XCBDELEGATE(WindowAttributesDidChange);
	XCBNOTIFY(WindowAttributesDidChange);
	
	[self checkIfAvailable];
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
- (BOOL)overrideRedirect
{
	return attributes.override_redirect ? YES : NO;
}
- (uint32_t)eventMask
{
	return attributes.your_event_mask;
}
- (XCBWindow*)aboveWindow
{
	return above;
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

- (void)refreshCachedProperty: (NSString*)propertyName
{
	XCBAtomCache *atomCache = [XCBAtomCache sharedInstance];
	xcb_atom_t atom = [atomCache atomNamed: propertyName];
	[self requestProperty: propertyName
	            atomValue: [NSNumber numberWithLong: atom]];
}

- (void)refreshCachedProperties: (NSArray*)properties
{
	FOREACH(properties, prop, NSString*)
	{
		[self refreshCachedProperty: prop];
	}
}

- (XCBCachedProperty*)cachedPropertyValue: (NSString*)cachedPropertyName
{
	return [cached_property_values objectForKey: cachedPropertyName];
}

- (void)changeProperty: (NSString*)propertyName
                  type: (NSString*)type
                format: (uint8_t)format
                  mode: (xcb_prop_mode_t)mode
                  data: (const void*)data
                 count: (uint32_t)elementCount
{
	XCBAtomCache *atomCache = [XCBAtomCache sharedInstance];
	xcb_change_property([XCBConn connection],
		mode,
		[self xcbWindowId],
		[atomCache atomNamed: propertyName],
		[atomCache atomNamed: type],
		format,
		elementCount,
		data);
	[XCBConn setNeedsFlush: YES];
}
- (void)replaceProperty: (NSString*)propertyName
                   type: (NSString*)type
                 format: (uint8_t)format
                   data: (const void*)data
                  count: (uint32_t)elementCount
{
	[self changeProperty: propertyName
	                type: type
	              format: format
	                mode: XCB_PROP_MODE_REPLACE
	                data: data
	               count: elementCount];
}

@end

@implementation XCBWindow (Private)
- (void)requestProperty: (NSString*)property atomValue: (NSNumber*)atomValue
{
	// We are currently assuming we want the whole
	// property value, no matter how long it is. Other
	// people may only want an offset of it.
	xcb_get_property_cookie_t cookie = 
		xcb_get_property([XCBConn connection],
			0,
			window,
			(xcb_atom_t)[atomValue longValue],
			XCB_GET_PROPERTY_TYPE_ANY,
			0,
			UINT32_MAX);
	// Retain the property name in case it gets released
	[property retain];

	[XCBConn setHandler: self
	           forReply: cookie.sequence
	           selector: @selector(handlePropertyReply:propertyName:)
	             object: property];
	[XCBConn setNeedsFlush: YES];
}

- (void)handlePropertyReply: (xcb_get_property_reply_t*)reply
               propertyName: (NSString*)propertyName
{
	XCBCachedProperty *property = [[XCBCachedProperty alloc]
		initWithGetPropertyReply: reply
		            propertyName: propertyName];
	if (nil == cached_property_values)
		cached_property_values = [NSMutableDictionary new];
	[cached_property_values setObject: property
	                           forKey: propertyName];
	NSDictionary *userInfo = [NSDictionary
		dictionaryWithObjectsAndKeys: 
		propertyName, @"PropertyName",
		property, @"PropertyValue",
		nil];
	XCBDELEGATE_U(WindowPropertyDidRefresh, userInfo);
	XCBNOTIFY_U(WindowPropertyDidRefresh, userInfo);
	[property release];
}
- (void)checkIfAvailable
{
	if (XCBWindowExistsState == window_load_state &&
		XCBWindowLoadedEverything == _cache_load_values)
	{
		window_load_state = XCBWindowAvailableState;
		XCBDELEGATE(WindowBecomeAvailable);
		XCBNOTIFY(WindowBecomeAvailable);
	}
}
/**
  * Create a new XCBWindow object for a window that the 
  * programme just created using xcb_create_window, but
  * haven't received the notification for yet.
  */
- (XCBWindow*)initWithNewXCBWindow: (xcb_window_t)new_window_id
{
	SELFINIT;
	window = new_window_id;
	window_load_state = XCBWindowCreatePendingState;
	_cache_load_values = XCBWindowLoadedNothing;
	// The create act itself through to the set of events
	// that happen after creation don't tell us where
	// we are stacked in the window list. We just
	// assume we are on the bottom
	above = nil;
	[XCBConn registerWindow: self];
	return self;
}
- (XCBWindow*)initWithXCBWindow: (xcb_window_t)aWindow 
                         parent: (xcb_window_t)parent_id
                          above: (xcb_window_t)above_sibling
{
	SELFINIT;
	window = aWindow;
	window_load_state = XCBWindowExistsState;
	_cache_load_values = XCBWindowLoadedNothing;

	// Don't use the "unknown window" for parent
	// as this information can be discovered through
	// the various events and geometry/attributes
	// callbacks, and nil means it has no parent.
	parent = [[XCBWindow windowWithXCBWindow: parent_id] 
			retain];

	// If the above window is set to zero, we don't know
	// what window this one is above (yet). If we get
	// a CreateNotify callback, we can check with the screen.
	// Otherwise, ConfigureNotifys will inform us.
	if (0 != above)
		above = [[XCBWindow windowWithXCBWindow: above_sibling]
			retain];
	else
		above = [[XCBWindow unknownWindow] retain];

	// Start the requests for geometry and window attributes
	// if we are a real window
	if (0 != window) // Check if we are the unknown window
	{
		xcb_get_geometry_cookie_t cookie =
			xcb_get_geometry([XCBConn connection], window);
		[XCBConn setHandler: self
				   forReply: cookie.sequence
				   selector: @selector(setGeometry:)];
		[self updateWindowAttributes];
		[XCBConn setNeedsFlush:YES];
	}
	[XCBConn registerWindow: self];
	return self;
}
- (void)handleCreateEvent: (xcb_create_notify_event_t*)anEvent
{
	NSDebugLLog(@"XCBWindow", @"-[XCBWindow handleCreateEvent:]");
	NSAssert(window_load_state != XCBWindowAvailableState, @"Expected window in the created or pending state.");
	window_load_state = XCBWindowExistsState;
	window = anEvent->window;
	frame = XCBMakeRect(anEvent->x, anEvent->y, anEvent->width, anEvent->height);
	border_width = anEvent->border_width;
	attributes.override_redirect = anEvent->override_redirect;
	ASSIGN(parent, [XCBWindow windowWithXCBWindow: anEvent->parent]);
	_cache_load_values |= XCBWindowLoadedGeometry;
	[self updateWindowAttributes];
	XCBDELEGATE(WindowDidCreate);
	XCBNOTIFY(WindowDidCreate);
	XCBDELEGATE(WindowDidCreate);
	XCBNOTIFY(WindowDidCreate);
}
@end

@implementation XCBWindow (Package)
- (void)setAboveWindow: (XCBWindow*)newAbove
{
	if (nil == newAbove ||
		[[newAbove parent] isEqual: parent])
		ASSIGN(above, newAbove);
	else
		[NSException raise: NSInvalidArgumentException
		            format: @"The specified above window (%@) is not a sibling of this window (%@).", newAbove, self];
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
- (void)handleConfigureNotifyEvent: (xcb_configure_notify_event_t*)anEvent
{
	id aboveWindow = anEvent->above_sibling == 0 ?
		(id)[NSNull null] :
		(id)[XCBWindow 
			windowWithXCBWindow: anEvent->above_sibling
			             parent: 0];
	XCBRect frameRect = XCBMakeRect(anEvent->x, anEvent->y,
		anEvent->width, anEvent->height);
	NSValue *frameRectValue = [NSValue 
		valueWithBytes:&frameRect
		objCType:@encode(XCBRect)];
	NSValue *borderWidth = [NSNumber numberWithInt: anEvent->border_width];
	NSNumber *sendEvent = [NSNumber numberWithBool: anEvent->response_type & 0x80];
	NSDictionary *userInfo = 
		[NSDictionary dictionaryWithObjectsAndKeys:
		frameRectValue, @"Rect",
		borderWidth, @"BorderWidth",
		sendEvent, @"SendEvent",
		aboveWindow, @"Above", // Place last as aboveWindow == nil, which then cuts off the rest of the dictionary (and hence it is absent, indicating stacked at the bottom). maybe we should have the concept of a nil window or just [NSNull null]
		nil];
		
	_cache_load_values |= XCBWindowLoadedGeometry;
	XCBDELEGATE_U(WindowFrameWillChange, userInfo);
	XCBNOTIFY_U(WindowFrameWillChange, userInfo);
	if (!([sendEvent boolValue] && ignore_synthetic_configure_notify))
	{
		frame = XCBMakeRect(anEvent->x, anEvent->y, anEvent->width, anEvent->height);
		border_width = anEvent->border_width;
		attributes.override_redirect = anEvent->override_redirect;
	}
	ASSIGN(above, [XCBWindow windowWithXCBWindow: anEvent->above_sibling]);
	XCBDELEGATE_U(WindowFrameDidChange, userInfo);
	XCBNOTIFY_U(WindowFrameDidChange, userInfo);
	
	[self checkIfAvailable];
}
- (void)handleDestroyNotifyEvent: (xcb_destroy_notify_event_t*)anEvent
{
	window_load_state = XCBWindowDestroyedState;
	XCBDELEGATE(WindowDidDestroy);
	XCBNOTIFY(WindowDidDestroy);
	[XCBConn cancelHandlersForObject: self];
	[XCBConn unregisterWindow: self];
}
- (void)handleUnMapNotifyEvent: (xcb_unmap_notify_event_t*)anEvent
{
	XCBDELEGATE(WindowWillUnMap);
	XCBNOTIFY(WindowWillUnMap);
	NSDebugLLog(@"XCBWindow", @"Umapping %@", self);
	attributes.map_state = XCB_MAP_STATE_UNMAPPED;
	XCBDELEGATE(WindowDidUnMap);
	XCBNOTIFY(WindowDidUnMap);
}
- (void)handleMapNotifyEvent: (xcb_map_notify_event_t*)anEvent
{
	attributes.map_state = XCB_MAP_STATE_VIEWABLE;
	XCBDELEGATE(WindowDidMap);
	XCBNOTIFY(WindowDidMap);
}
- (void)handleMapRequest: (xcb_map_request_event_t*)anEvent
{
	XCBWindow *parent_window = [XCBWindow windowWithXCBWindow: anEvent->parent];
	NSDictionary *dictionary = 
		[NSDictionary dictionaryWithObject: parent_window 
		                            forKey: @"Parent"];
	XCBDELEGATE_U(WindowMapRequest, dictionary);
}
- (void)handleCirculateRequest: (xcb_circulate_request_event_t*)anEvent
{
	NSValue *place = [NSNumber numberWithInteger: anEvent->place];
	NSDictionary *dictionary = 
		[NSDictionary 
			dictionaryWithObjectsAndKeys: place, 
			                              @"Place",
			                              nil];
	XCBDELEGATE_U(WindowCirculateRequest, dictionary);
}
- (void)handleConfigureRequest: (xcb_configure_request_event_t*)anEvent
{
	XCBWindow *parent_window = [XCBWindow windowWithXCBWindow: anEvent->parent];
	uint16_t vm = anEvent->value_mask;
	XCBRect rframe = XCBMakeRect(anEvent->x, anEvent->y, anEvent->width, anEvent->height);
	NSValue *rframeVal = [NSValue valueWithBytes: &rframe 
	                                   objCType: @encode(XCBRect)];
	NSValue *borderWidth = [NSNumber numberWithInteger: anEvent->border_width];
	// If the XCB_CONFIG_WINDOW_SIBLING parameter is specified, we report
	// the above window or NSNull if it is to be placed on top. We put in
	// nil to specify that this value was absent.
	id aboveWindow = vm & XCB_CONFIG_WINDOW_SIBLING ?
		(anEvent->sibling != 0 ? (id)[XCBWindow windowWithXCBWindow: anEvent->sibling] : (id)[NSNull null]) :
		nil
		;
	NSValue *stackMode = [NSNumber numberWithInteger: anEvent->stack_mode];
	NSDictionary *dictionary = 
		[NSDictionary dictionaryWithObjectsAndKeys: 
			[NSNumber numberWithInteger: vm], @"ValueMask",
			parent_window, @"Parent",
			rframeVal, @"Frame",
			borderWidth, @"BorderWidth",
			stackMode, @"StackMode",
			aboveWindow, @"Above", // Put last in case it is nil
			nil
			];
	XCBDELEGATE_U(WindowConfigureRequest, dictionary);
}
- (void)handleReparentNotify: (xcb_reparent_notify_event_t*)anEvent
{
	XCBWindow* oldParent = [parent retain];
	ASSIGN(parent, [XCBWindow windowWithXCBWindow: anEvent->parent]);
	NSDictionary *dictionary = [NSDictionary 
		dictionaryWithObject: oldParent
		              forKey: @"OldParent"];
	// There are no ConfigureNotify events to update these
	frame.origin.x = anEvent->x;
	frame.origin.y = anEvent->y;
	XCBDELEGATE_U(WindowParentDidChange, dictionary);
	XCBNOTIFY_U(WindowParentDidChange, dictionary);
	[oldParent release];
}
- (void)handleButtonPress: (xcb_button_press_event_t*)anEvent
{
	XCBWindow *rootWindow = [XCBWindow windowWithXCBWindow: anEvent->root],
		  *childWindow = [XCBWindow windowWithXCBWindow: anEvent->child];
	XCBPoint rootPoint = XCBMakePoint(anEvent->root_x, anEvent->root_y),
		 eventPoint = XCBMakePoint(anEvent->event_x, anEvent->event_y);
	NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithUnsignedChar: anEvent->detail], @"Detail",
		[NSNumber numberWithUnsignedLong: anEvent->time], @"Time",
		[NSValue valueWithXCBPoint: rootPoint], @"RootPoint",
		[NSValue valueWithXCBPoint: eventPoint], @"EventPoint",
		[NSNumber numberWithUnsignedInteger: anEvent->state], @"State",
		[NSNumber numberWithBool: anEvent->same_screen ? YES : NO], @"SameScreen",
		rootWindow, @"Root",
		childWindow, @"Child",
		nil];
	XCBDELEGATE_U(WindowButtonPress, dictionary);
	XCBNOTIFY_U(WindowButtonPress, dictionary);
}
- (void)handleButtonRelease: (xcb_button_release_event_t*)anEvent
{
	XCBWindow *rootWindow = [XCBWindow windowWithXCBWindow: anEvent->root],
		  *childWindow = [XCBWindow windowWithXCBWindow: anEvent->child];
	XCBPoint rootPoint = XCBMakePoint(anEvent->root_x, anEvent->root_y),
		 eventPoint = XCBMakePoint(anEvent->event_x, anEvent->event_y);
	NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithUnsignedChar: anEvent->detail], @"Detail",
		[NSNumber numberWithUnsignedLong: anEvent->time], @"Time",
		[NSValue valueWithXCBPoint: rootPoint], @"RootPoint",
		[NSValue valueWithXCBPoint: eventPoint], @"EventPoint",
		[NSNumber numberWithUnsignedInteger: anEvent->state], @"State",
		[NSNumber numberWithBool: anEvent->same_screen ? YES : NO], @"SameScreen",
		rootWindow, @"Root",
		childWindow, @"Child",
		nil];
	XCBDELEGATE_U(WindowButtonRelease, dictionary);
	XCBNOTIFY_U(WindowButtonRelease, dictionary);
}
- (void)handleFocusIn: (xcb_focus_in_event_t*)anEvent
{
	NSDictionary *dictionary = [NSDictionary
		dictionaryWithObjectsAndKeys: 
			[NSNumber numberWithInteger: anEvent->mode],
			@"Mode",
			[NSNumber numberWithInteger: anEvent->detail],
			@"Detail",
			nil];
	XCBDELEGATE_U(WindowFocusIn, dictionary);
	XCBNOTIFY_U(WindowFocusIn, dictionary);
}
- (void)handleFocusOut: (xcb_focus_out_event_t*)anEvent
{
	NSDictionary *dictionary = [NSDictionary
		dictionaryWithObjectsAndKeys: 
			[NSNumber numberWithInteger: anEvent->mode],
			@"Mode",
			[NSNumber numberWithInteger: anEvent->detail],
			@"Detail",
			nil];
	XCBDELEGATE_U(WindowFocusOut, dictionary);
	XCBNOTIFY_U(WindowFocusOut, dictionary);
}
- (void)handleMotionNotify: (xcb_motion_notify_event_t*)anEvent
{
	XCBWindow *rootWindow = [XCBWindow windowWithXCBWindow: anEvent->root],
		  *childWindow = [XCBWindow windowWithXCBWindow: anEvent->child];
	XCBPoint rootPoint = XCBMakePoint(anEvent->root_x, anEvent->root_y),
		 eventPoint = XCBMakePoint(anEvent->event_x, anEvent->event_y);
	NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithUnsignedChar: anEvent->detail], @"Detail",
		[NSNumber numberWithUnsignedLong: anEvent->time], @"Time",
		[NSValue valueWithXCBPoint: rootPoint], @"RootPoint",
		[NSValue valueWithXCBPoint: eventPoint], @"EventPoint",
		[NSNumber numberWithUnsignedInteger: anEvent->state], @"State",
		[NSNumber numberWithBool: anEvent->same_screen ? YES : NO], @"SameScreen",
		rootWindow, @"Root",
		childWindow, @"Child",
		nil];
	XCBDELEGATE_U(WindowMotionNotify, dictionary);
	XCBNOTIFY_U(WindowMotionNotify, dictionary);
}
@end

void XCBWindowForwardConfigureRequest(NSNotification* aNotification)
{
	XCBWindow *window = [aNotification object];
	NSDictionary *values = [aNotification userInfo];
	uint32_t vl[7];
	int i = 0;
	
	XCBRect frame;
	NSInteger borderWidth, stackMode;
	id aboveWindow;
	NSInteger valueMask;

	valueMask = [[values objectForKey: @"ValueMask"] integerValue];
	[[values objectForKey: @"Frame"] getValue: &frame];
	borderWidth = [[values objectForKey: @"BorderWidth"] integerValue];
	stackMode = [[values objectForKey: @"StackMode"] integerValue];
	aboveWindow = [values objectForKey: @"Above"];
	if ([aboveWindow isEqual: [NSNull null]])
		aboveWindow = nil;

	if (valueMask & XCB_CONFIG_WINDOW_X)
		vl[i++] = frame.origin.x;
	if (valueMask & XCB_CONFIG_WINDOW_Y)
		vl[i++] = frame.origin.y;
	if (valueMask & XCB_CONFIG_WINDOW_WIDTH)
		vl[i++] = frame.size.width;
	if (valueMask & XCB_CONFIG_WINDOW_HEIGHT)
		vl[i++] = frame.size.height;
	if (valueMask & XCB_CONFIG_WINDOW_BORDER_WIDTH)
		vl[i++] = borderWidth;
	if (valueMask & XCB_CONFIG_WINDOW_SIBLING)
		vl[i++] = [aboveWindow xcbWindowId];
	if (valueMask & XCB_CONFIG_WINDOW_STACK_MODE)
		vl[i++] = stackMode;
	
	// Just in case it contains other bit junk
	valueMask &= XCB_CONFIG_WINDOW_X | XCB_CONFIG_WINDOW_Y |
		XCB_CONFIG_WINDOW_WIDTH | XCB_CONFIG_WINDOW_HEIGHT |
		XCB_CONFIG_WINDOW_BORDER_WIDTH |
		XCB_CONFIG_WINDOW_SIBLING |
		XCB_CONFIG_WINDOW_STACK_MODE;
	[window configureWindow: valueMask
	                 values: vl];
}
