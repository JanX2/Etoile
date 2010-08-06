/**
 * Étoilé ProjectManager - XCBConnection.m
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
#import "XCBConnection.h"
#import "XCBScreen.h"
#import "XCBWindow+Package.h"
#import "XCBAtomCache.h"
#import "PMConnectionDelegate.h"
#import <EtoileFoundation/EtoileFoundation.h>
#include <xcb/xcbext.h>
#include <xcb/damage.h>

@interface XCBConnection (EventHandlers)
- (void)handleMapNotify: (xcb_map_notify_event_t*)anEvent;
- (void)handleCreateNotify: (xcb_create_notify_event_t*)anEvent;
- (void)handleButtonPress: (xcb_button_press_event_t*)anEvent;
- (void)handleButtonRelease: (xcb_button_release_event_t*)anEvent;
- (void)handleKeyPress: (xcb_key_press_event_t*)anEvent;
- (void)handleKeyRelease: (xcb_key_release_event_t*)anEvent;
- (void)handleMotionNotify: (xcb_motion_notify_event_t*)anEvent;
- (void)handleEnterNotify: (xcb_enter_notify_event_t*)anEvent;
- (void)handleLeaveNotify: (xcb_leave_notify_event_t*)anEvent;
- (void)handleExpose: (xcb_expose_event_t*)anEvent;
- (void)handleMapRequest: (xcb_map_request_event_t*)anEvent;
- (void)handleCirculateRequest: (xcb_circulate_request_event_t*)anEvent;
- (void)handleConfigureRequest: (xcb_configure_request_event_t*)anEvent;
- (void)handleReparentNotify: (xcb_reparent_notify_event_t*)anEvent;
@end

@interface XCBConnection (Private)
- (void)flush;
- (void)eventsReady: (NSNotification*)notification;
@end

@implementation XCBConnection (EventHandlers)
- (void) handleFocusIn: (xcb_focus_in_event_t*)anEvent
{
	NSDebugLLog(@"XCBConnection", @"Focus in");
	XCBWindow *win = [self windowForXCBId: anEvent->event];
	[win handleFocusIn: anEvent];
}
- (void) handleFocusOut: (xcb_focus_out_event_t*)anEvent
{
	NSDebugLLog(@"XCBConnection", @"Focus out");
	XCBWindow *win = [self windowForXCBId: anEvent->event];
	[win handleFocusOut: anEvent];
}
- (void) handleMapRequest: (xcb_map_request_event_t*)anEvent
{
	NSDebugLLog(@"XCBConnection", @"Mapping requested for window: %x", anEvent->window);
	XCBWindow *win = [self windowForXCBId: anEvent->window];
	NSAssert(win, @"Map request without window.");
	[win handleMapRequest: anEvent];
}
- (void)handleCirculateRequest: (xcb_circulate_request_event_t*)anEvent
{
	XCBWindow *win = [self windowForXCBId: anEvent->window];
	[win handleCirculateRequest: anEvent];
}
- (void)handleConfigureRequest: (xcb_configure_request_event_t*)anEvent
{
	NSDebugLLog(@"XCBConnection",@"XCBConnection: Configure requested for window: %x", anEvent->window);
	XCBWindow *win = [self windowForXCBId: anEvent->window];
	[win handleConfigureRequest: anEvent];
}
- (void)handleButtonPress: (xcb_button_press_event_t*)anEvent
{
	NSDebugLLog(@"XCBConnection",@"Button pressed");
	XCBWindow *win = [self windowForXCBId: anEvent->event];
	currentTime = anEvent->time;
	[win handleButtonPress: anEvent];
}
- (void)handleButtonRelease: (xcb_button_release_event_t*)anEvent
{
	NSDebugLLog(@"XCBConnection",@"Button released");
	XCBWindow *win = [self windowForXCBId: anEvent->event];
	currentTime = anEvent->time;
	[win handleButtonRelease: anEvent];
}
- (void)handleKeyPress: (xcb_key_press_event_t*)anEvent
{
	NSDebugLLog(@"XCBConnection",@"Key pressed");
	currentTime = anEvent->time;
}
- (void)handleKeyRelease: (xcb_key_release_event_t*)anEvent
{
	NSDebugLLog(@"XCBConnection",@"Key released");
	currentTime = anEvent->time;
}
- (void)handleMotionNotify: (xcb_motion_notify_event_t*)anEvent
{
	NSDebugLLog(@"XCBConnection",@"Motion notify");
	XCBWindow *win = [self windowForXCBId: anEvent->event];
	currentTime = anEvent->time;
	[win handleMotionNotify: anEvent];
}
- (void)handleEnterNotify: (xcb_enter_notify_event_t*)anEvent
{
	NSDebugLLog(@"XCBConnection",@"Enter notify");
	currentTime = anEvent->time;
}
- (void)handleLeaveNotify: (xcb_leave_notify_event_t*)anEvent
{
	NSDebugLLog(@"XCBConnection",@"Leave notify");
	currentTime = anEvent->time;
}
- (void)handleConfigureNotify: (xcb_configure_notify_event_t*)anEvent
{
	XCBWindow *win = [self windowForXCBId: anEvent->window];
	[win handleConfigureNotifyEvent: anEvent];
}
- (void)handleDestroyNotify: (xcb_destroy_notify_event_t*)anEvent
{
	XCBWindow *win = [self windowForXCBId: anEvent->window];
	[win handleDestroyNotifyEvent: anEvent];
}
- (void)handleUnMapNotify: (xcb_unmap_notify_event_t*)anEvent
{
	XCBWindow *win  = [self windowForXCBId: anEvent->window];
	NSDebugLLog(@"XCBConnection",@"UnMapping window %@ (%x)", win, anEvent->window);
	[win handleUnMapNotifyEvent: anEvent];
}
- (void)handleMapNotify: (xcb_map_notify_event_t*)anEvent
{
	XCBWindow *win  = [self windowForXCBId: anEvent->window];
	[win handleMapNotifyEvent: anEvent];
}
- (void)handleCirculateNotify: (xcb_circulate_notify_event_t*)anEvent
{
	XCBWindow *win  = [self windowForXCBId: anEvent->window];
	[win handleCirculateNotifyEvent: anEvent];
}
- (void)handleCreateNotify: (xcb_create_notify_event_t*)anEvent
{
	NSDebugLLog(@"XCBConnection",@"Created window %x", anEvent->window);
	XCBWindow *win  = [XCBWindow windowWithCreateEvent: anEvent];
	// No need to post notification, as this is handled by XCBWindow itself.
}
- (void)handleExpose: (xcb_expose_event_t*)anEvent
{
	XCBWindow *win = [self windowForXCBId:anEvent->window];
	[win handleExpose:anEvent];
}
- (void)handleReparentNotify: (xcb_reparent_notify_event_t*)anEvent
{
	XCBWindow *win = [self windowForXCBId: anEvent->window];
	[win handleReparentNotify: anEvent];
}
@end

XCBConnection *XCBConn;


@implementation XCBConnection
- (void)startMessageLoop
{
	[[NSRunLoop currentRunLoop] run];
}
+ (XCBConnection*)sharedConnection
{
	if (nil == XCBConn)
	{
		NSDebugLLog(@"XCBConnection",@"Creating shared connection...");
		[[self alloc] init];
	}
	return XCBConn;
}
- (id)init
{
	SUPERINIT;
	NSDebugLLog(@"XCBConnection",@"Creating connection...");
	NSDebugLLog(@"XCBConnection",@"Self: %p", self);
	[NSRunLoop currentRunLoop];
	connection = xcb_connect(NULL, NULL);
	if (NULL == connection)
	{
		[self release];
		return nil;
	}

	if (xcb_connection_has_error(connection)) 
	{
		NSLog(@"Unknown error creating connection.");
		[self release];
		return nil;
	}

	currentTime = XCB_CURRENT_TIME;

	replyHandlers = [NSMutableArray new];
	windows = NSCreateMapTable(NSIntMapKeyCallBacks,
			NSObjectMapValueCallBacks, 100);
	screens = [NSMutableArray new];

	// Hack needed because creating XCBWindow instances requires XCBConn to be
	// valid.
	XCBConn = self;

	// Set up event delivery
	int fd = xcb_get_file_descriptor(connection);
	if (-1 == fd)
	{
		NSLog(@"Received invalid file descriptor for XCBConnection");
		[self release];
		return nil;
	}
	handle = [[NSFileHandle alloc] initWithFileDescriptor:fd
	                                       closeOnDealloc:NO];
	NSNotificationCenter *center =
		[NSNotificationCenter defaultCenter];
	[center addObserver: self
	           selector: @selector(eventsReady:)
	               name: NSFileHandleDataAvailableNotification
           	     object: handle];
	[handle waitForDataInBackgroundAndNotify];

	// Create XCBWindows for all of the root windows.
	xcb_screen_iterator_t iter = 
		xcb_setup_roots_iterator(xcb_get_setup(connection));
	while (iter.rem)
	{
		xcb_screen_t *screen = iter.data;
		[screens addObject: [XCBScreen screenWithXCBScreen: screen]];
		NSDebugLLog(@"XCBConnection",@"Root %x (%dx%d)", screen->root, screen->width_in_pixels, 
				screen->height_in_pixels);
		[self registerWindow: [XCBWindow windowWithXCBWindow: screen->root parent:XCB_NONE]];

		xcb_screen_next(&iter);
	}
	xcb_flush(connection);
	NSDebugLLog(@"XCBConnection",@"Connection created");
	//[[XCBAtomCache sharedInstance] cacheAtom: @"_NET_ACTIVE_WINDOW"];
	return self;
}

#define HANDLE(constant, sel) \
	case XCB_ ## constant:\
		NSDebugLLog(@"XCBConnection",@"Handling %s", #constant);\
		if ([self respondsToSelector:@selector(handle ## sel:)])\
		{\
			[self handle ## sel: (void*)event];\
		}\
		break;

- (BOOL)handleEvents
{
	BOOL eventsHandled = NO;
	//NSDebugLLog(@"XCBConnection",@"Handling events");
	xcb_generic_event_t *event;
	while (NULL != (event = xcb_poll_for_event(connection)))
	{
		switch (event->response_type & ~0x80)
		{
			HANDLE(KEY_PRESS, KeyPress)
			HANDLE(KEY_RELEASE, KeyRelease)
			HANDLE(BUTTON_RELEASE, ButtonRelease)
			HANDLE(MOTION_NOTIFY, MotionNotify)
			HANDLE(ENTER_NOTIFY, EnterNotify)
			HANDLE(LEAVE_NOTIFY, LeaveNotify)
			HANDLE(FOCUS_OUT, FocusOut)
			HANDLE(FOCUS_IN, FocusIn)
			HANDLE(BUTTON_PRESS, ButtonPress)
			HANDLE(MAP_REQUEST, MapRequest)
			HANDLE(CIRCULATE_REQUEST, CirculateRequest)
			HANDLE(CONFIGURE_REQUEST, ConfigureRequest)
			HANDLE(UNMAP_NOTIFY, UnMapNotify)
			HANDLE(MAP_NOTIFY, MapNotify)
			HANDLE(DESTROY_NOTIFY, DestroyNotify)
			HANDLE(CREATE_NOTIFY, CreateNotify)
			HANDLE(CONFIGURE_NOTIFY, ConfigureNotify)
			HANDLE(CIRCULATE_NOTIFY, CirculateNotify)
			HANDLE(REPARENT_NOTIFY, ReparentNotify)

			HANDLE(EXPOSE, Expose)
			default:
				{
					SEL extSel = 
						extensionSelectors[event->response_type  & ~0x80];
			
					if (extSel != (SEL)0)
					{
						[self performSelector: extSel
						           withObject: (id)event];
					}
					else
					{
						NSDebugLLog(@"XCBConnection",@"Don't yet know how to handle events of type %d (%hd)",
							event->response_type, event->sequence);
					}
				}
			case 0: {}
		}
		eventsHandled = YES;
	}
	return eventsHandled;
}
- (BOOL)handleReplies
{
	BOOL repliesHandled = NO;
	//NSDebugLLog(@"XCBConnection",@"Handling replies");
	for(NSUInteger i=0 ; i<[replyHandlers count] ; i++)
	{
		NSArray *handler = [replyHandlers objectAtIndex: i];
		void *reply;
		xcb_generic_error_t *error;
		unsigned int sequenceNumber = 
			[[handler objectAtIndex: 0] unsignedIntValue];
		// FIXME: Handle errors.
		if (1 == xcb_poll_for_reply(connection, sequenceNumber, &reply, &error))
		{
			if (NULL == reply) 
			{
				// It is now safe to free the handler
				[replyHandlers removeObjectAtIndex: i];
				i--;
				continue;
			}
			NSDebugLLog(@"XCBConnection",@"Got reply for %d", sequenceNumber);
			if (error) 
			{
				NSLog(@"XCBConnection: ERROR for request seq %d: %d (response type %d)",
				error->sequence,
				error->error_code,
				error->response_type);
				if ([handler count] == 5)
				{
					id obj = [handler objectAtIndex: 1];
					id context = [handler objectAtIndex: 3];
					if ([context isEqual: [NSNull null]])
						context = nil;
					SEL errorSelector;
					[[handler objectAtIndex: 4] 
						getValue: &errorSelector];
					[obj performSelector: errorSelector
					          withObject: (id)error
					          withObject: (id)context];
				}
				free(error);
				continue;
			}
			id obj = [handler objectAtIndex: 1];
			SEL selector;
			[[handler objectAtIndex: 2] getValue: &selector];
			if ([handler count] == 3) 
			{
				[obj performSelector: selector withObject: (id)reply];
			}
			else
			{
				id context = [handler objectAtIndex: 3];
				[obj performSelector: selector
				          withObject: (id)reply
				          withObject: context];
			}
			free(reply);
			// Don't remove the handler just yet
			repliesHandled = YES;
		}
	}
	return repliesHandled;
}
- (void)setHandler: (id)anObject 
          forReply: (unsigned int)sequence
          selector: (SEL)aSelector
{
	NSNumber *key = [NSNumber numberWithUnsignedInt: sequence];
	NSDictionary *value = [NSArray arrayWithObjects:
		key,
		anObject,
		[NSValue valueWithBytes: &aSelector objCType: @encode(SEL)],
		nil];
	[replyHandlers addObject: value];
}
- (void)setHandler: (id)anObject
          forReply: (unsigned int)sequence
          selector: (SEL)aSelector
            object: (id)context
{
	NSNumber *key = [NSNumber numberWithUnsignedInt: sequence];
	NSDictionary *value = [NSArray arrayWithObjects:
		key,
		anObject,
		[NSValue valueWithBytes: &aSelector objCType: @encode(SEL)],
		context != nil ? context : (id)[NSNull null],
		nil];
	[replyHandlers addObject: value];
}
- (void)setHandler: (id)anObject
          forReply: (unsigned int)sequence
          selector: (SEL)aSelector
            object: (id)context
     errorSelector: (SEL)errorSelector
{
	NSNumber *key = [NSNumber numberWithUnsignedInt: sequence];
	NSDictionary *value = [NSArray arrayWithObjects:
		key,
		anObject,
		[NSValue valueWithBytes: &aSelector objCType: @encode(SEL)],
		context != nil ? context : (id)[NSNull null],
		[NSValue valueWithBytes: &errorSelector objCType: @encode(SEL)],
		nil];
	[replyHandlers addObject: value];
}

- (void)cancelHandlersForObject: (id)anObject
{
	// FIXME: This would be slow
	NSMutableIndexSet *removeObjects = [NSMutableIndexSet new];
	NSUInteger count = [replyHandlers count];
	for (NSUInteger i = 0; i < count; i++)
	{
		id replyHandler = [replyHandlers objectAtIndex:i];
		id handlerObject = [replyHandler objectAtIndex:2];
		if ([handlerObject isEqual: anObject])
			[removeObjects addIndex:i];

	}
	[replyHandlers removeObjectsAtIndexes:removeObjects];
	[removeObjects release];
}
- (void)unregisterWindow: (XCBWindow*)aWindow
{
	NSDebugLLog(@"XCBConnection",@"Unregistering window: %@", aWindow);
	NSMapRemove(windows, (void*)(intptr_t)[aWindow xcbWindowId]);
}
- (void)registerWindow: (XCBWindow*)aWindow
{
	NSDebugLLog(@"XCBConnection",@"Registered window: %@", aWindow);
	NSMapInsert(windows, (void*)(intptr_t)[aWindow xcbWindowId], aWindow);
}
- (XCBWindow*)windowForXCBId: (xcb_window_t)anId;
{
	return NSMapGet(windows, (void*)(intptr_t)anId);
}
- (void)setDelegate:(id) aDelegate
{
	delegate = aDelegate;
}
- (id)delegate 
{
	return delegate;
}
- (void)setSelector: (SEL)aSelector forXEvent: (uint8_t)anEvent
{
	extensionSelectors[anEvent] = aSelector;
}
- (NSArray*)screens
{
	return screens;
}
- (void)grab
{
	xcb_void_cookie_t c = xcb_grab_server_checked(connection);
	xcb_generic_error_t *e = xcb_request_check(connection, c);
	if (e) 
	{
		NSLog(@"Error grabbing server");
		free(e);
	}
}

- (void)ungrab
{
	xcb_void_cookie_t c = xcb_ungrab_server_checked(connection);
	xcb_generic_error_t *e = xcb_request_check(connection, c);
	if (e) 
	{
		NSLog(@"Error un-grabbing server");
		free(e);
	}
}
- (void)allowEvents: (xcb_allow_t)allow timestamp: (xcb_timestamp_t)time
{
	xcb_allow_events(connection, allow, time);
}
- (uint8_t)grabPointerWithWindow: (XCBWindow*)grabWindow
                     ownerEvents: (BOOL)ownerEvents
                       eventMask: (uint16_t)eventMask
                     pointerMode: (uint8_t)pointerMode
                    keyboardMode: (uint8_t)keyboardMode
                       confineTo: (XCBWindow*)confineWindow
                          cursor: (xcb_cursor_t)cursor
                            time: (xcb_timestamp_t)time
{
	xcb_grab_pointer_cookie_t cookie = xcb_grab_pointer(connection,
		ownerEvents ? 1 : 0,
		[grabWindow xcbWindowId],
		eventMask,
		pointerMode,
		keyboardMode,
		[confineWindow xcbWindowId],
		cursor,
		time);
	xcb_grab_pointer_reply_t *reply = xcb_grab_pointer_reply(connection, cookie, NULL);
	uint8_t status = reply->status;
	free(reply);
	return status;
}
- (void)ungrabPointer: (xcb_timestamp_t)time
{
	xcb_ungrab_pointer(connection, time);
}
- (xcb_connection_t*) connection
{
	return connection;
}
- (void) dealloc
{
	xcb_disconnect(connection);
	[handle release];
	[replyHandlers release];
	[screens release];
	[super dealloc];
}
- (void)setNeedsFlush: (BOOL)shouldFlush
{
	needsFlush = shouldFlush;
}
- (BOOL)needsFlush
{
	return needsFlush;
}
- (xcb_timestamp_t)currentTime
{
	return currentTime;
}

@end

@implementation XCBConnection(Private)
- (void)flush
{
	xcb_flush(connection);
}
- (void)eventsReady: (NSNotification*)notification
{
	// Poll while there is data left in the buffer
	while ([self handleEvents] || [self handleReplies]) {}
	// NSDebugLLog(@"XCBConnection",@"Finished handling events");
	if ([delegate respondsToSelector:@selector(finishedProcessingEvents:)])
		[delegate finishedProcessingEvents:self];
	if (needsFlush)
	{
		[self flush];
		needsFlush = NO;
	}
	[handle waitForDataInBackgroundAndNotify];
}
@end
