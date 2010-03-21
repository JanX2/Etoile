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
#import "XCBWindow.h"
#import "XCBAtomCache.h"
#import "PMConnectionDelegate.h"
#import <EtoileFoundation/EtoileFoundation.h>
#include <xcb/xcbext.h>
#include <xcb/damage.h>

@interface XCBConnection (EventHandlers)
- (void)handleMapNotify: (xcb_map_notify_event_t*)anEvent;
- (void)handleCreateNotify: (xcb_create_notify_event_t*)anEvent;
- (void)handleButtonPress: (xcb_map_notify_event_t*)anEvent;
- (void)handleExpose: (xcb_expose_event_t*)anEvent;
@end

@interface XCBConnection (Private)
- (void)flush;
@end

@implementation XCBConnection (EventHandlers)
- (void) handleFocusIn: (xcb_map_notify_event_t*)anEvent
{
	NSLog(@"Focus in");
}
- (void) handleFocusOut: (xcb_map_notify_event_t*)anEvent
{
	NSLog(@"Focus out");
}
- (void) handleMapRequest: (xcb_map_notify_event_t*)anEvent
{
	NSLog(@"Mapping requested");
}
- (void) handleButtonPress: (xcb_map_notify_event_t*)anEvent
{
	NSLog(@"Button pressed");
	//[[[screens objectAtIndex: 0 ] rootWindow] createChildInRect: XCBMakeRect(0,0,640,480)];
}
- (void) handleConfigureNotify: (xcb_configure_notify_event_t*)anEvent
{
	NSLog(@"Configuring window");
	XCBWindow *win = [self windowForXCBId: anEvent->window];
	[win handleConfigureNotifyEvent: anEvent];
}
- (void) handleDestroyNotify: (xcb_destroy_notify_event_t*)anEvent
{
	XCBWindow *win = [self windowForXCBId: anEvent->window];
	[win handleDestroyNotifyEvent: anEvent];
}
- (void) handleUnMapNotify: (xcb_unmap_notify_event_t*)anEvent
{
	XCBWindow *win  = [self windowForXCBId: anEvent->window];
	NSLog(@"UnMapping window %@ (%x)", win, anEvent->window);
	[win handleUnMapNotifyEvent: anEvent];
}
- (void) handleMapNotify: (xcb_map_notify_event_t*)anEvent
{
	uint32_t events = XCB_EVENT_MASK_FOCUS_CHANGE;

	xcb_change_window_attributes(connection, anEvent->window,
			XCB_CW_EVENT_MASK, &events);
	NSLog(@"Mapping window %x", anEvent->window);
	NSLog(@"Redirect? %d", anEvent->override_redirect);
	XCBWindow *win  = [self windowForXCBId: anEvent->window];
	[win handleMapNotifyEvent: anEvent];
}
- (void) handleCirculateNotify: (xcb_circulate_notify_event_t*)anEvent
{
	XCBWindow *win  = [self windowForXCBId: anEvent->window];
	[win handleCirculateNotifyEvent: anEvent];
}
- (void) handleCreateNotify: (xcb_create_notify_event_t*)anEvent
{
	NSLog(@"Created window %x", anEvent->window);
	XCBWindow *win  = [XCBWindow windowWithCreateEvent: anEvent];
	// No need to post notification, as this is handled by XCBWindow itself.

	//FIXME: Inefficient; track damaged regions in the client.
	//xcb_damage_damage_t damageid = xcb_generate_id(connection);
	//xcb_damage_create(connection, damageid, anEvent->window, XCB_DAMAGE_REPORT_LEVEL_RAW_RECTANGLES);
	//xcb_flush(connection);
	//NSLog(@"Registering for damage...");
}
- (void) handleExpose: (xcb_expose_event_t*)anEvent
{
	XCBWindow *win = [self windowForXCBId:anEvent->window];
	[win handleExpose:anEvent];
}
@end

XCBConnection *XCBConn;


@implementation XCBConnection
+ (XCBConnection*)sharedConnection
{
	if (nil == XCBConn)
	{
	NSLog(@"Creating shared connection...");
		[[self alloc] init];
	}
	return XCBConn;
}
- (id) init
{
	SUPERINIT;
	NSLog(@"Creating connection...");
	NSLog(@"Self: %x", self);
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
		NSLog(@"Root %x (%dx%d)", screen->root, screen->width_in_pixels, 
				screen->height_in_pixels);
		[self registerWindow: [XCBWindow windowWithXCBWindow: screen->root parent:XCB_NONE]];

		uint32_t events = 
			XCB_EVENT_MASK_FOCUS_CHANGE |
			XCB_EVENT_MASK_EXPOSURE | XCB_EVENT_MASK_BUTTON_PRESS |
		   	XCB_EVENT_MASK_KEY_PRESS | XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY |
			XCB_EVENT_MASK_STRUCTURE_NOTIFY;

		xcb_change_window_attributes(connection, screen->root,
			XCB_CW_EVENT_MASK, &events);
		events = 1;
		xcb_configure_window(connection, screen->root, 
			XCB_CW_OVERRIDE_REDIRECT, &events);
		xcb_change_window_attributes(connection, screen->root, 
			XCB_CW_OVERRIDE_REDIRECT, &events);
		xcb_screen_next(&iter);
	}
	xcb_flush(connection);
	NSLog(@"Connection created");
	//[[XCBAtomCache sharedInstance] cacheAtom: @"_NET_ACTIVE_WINDOW"];
	return self;
}

#define HANDLE(constant, sel) \
	case XCB_ ## constant:\
		NSLog(@"Handling %s", #constant);\
		if ([self respondsToSelector:@selector(handle ## sel:)])\
		{\
			[self handle ## sel: (void*)event];\
		}\
		break;

- (BOOL)handleEvents
{
	BOOL eventsHandled = NO;
	//NSLog(@"Handling events");
	xcb_generic_event_t *event;
	while (NULL != (event = xcb_poll_for_event(connection)))
	{
		switch (event->response_type & ~0x80)
		{
			//HANDLE(KEY_PRESS, KeyPress)
			//HANDLE(KEY_RELEASE, KeyRelease)
			//HANDLE(BUTTON_RELEASE, ButtonRelease)
			HANDLE(FOCUS_OUT, FocusOut)
			HANDLE(FOCUS_IN, FocusIn)
			HANDLE(BUTTON_PRESS, ButtonPress)
			HANDLE(MAP_REQUEST, MapRequest)
			HANDLE(UNMAP_NOTIFY, UnMapNotify)
			HANDLE(MAP_NOTIFY, MapNotify)
			HANDLE(DESTROY_NOTIFY, DestroyNotify)
			HANDLE(CREATE_NOTIFY, CreateNotify)
			HANDLE(CONFIGURE_NOTIFY, ConfigureNotify)
			HANDLE(CIRCULATE_NOTIFY, CirculateNotify)

			HANDLE(EXPOSE, Expose)
			default:
				{
					SEL extSel = 
						extensionSelectors[event->response_type  & ~0x80];
			
					if (extSel != (SEL)0)
					{
						[delegate performSelector: extSel
						               withObject: self
						               withObject: (id)event];
					}
					else
					{
						NSLog(@"Don't yet know how to handle events of type %d (%hd)",
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
	//NSLog(@"Handling replies");
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
			NSLog(@"Got reply for %d", sequenceNumber);
			if (error) 
			{
				NSLog(@"ERROR for request seq %d: %d (response type %d)",
				error->sequence,
				error->error_code,
				error->response_type);
				free(error);
				continue;
			}
			id obj = [handler objectAtIndex: 1];
			SEL selector;
			[[handler objectAtIndex: 2] getValue: &selector];
			[obj performSelector: selector withObject: (id)reply];
			free(reply);
			// Don't remove the handler just yet
			repliesHandled = YES;
		}
	}
	return repliesHandled;
}
- (void)eventsReady: (NSNotification*)notification
{
	// Poll while there is data left in the buffer
	while ([self handleEvents] || [self handleReplies]) {}
	// NSLog(@"Finished handling events");
	if ([delegate respondsToSelector:@selector(finishedProcessingEvents:)])
		[delegate finishedProcessingEvents:self];
	if (needsFlush)
	{
		[self flush];
		needsFlush = NO;
	}
	[handle waitForDataInBackgroundAndNotify];
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
	NSLog(@"Unregistering window: %@", aWindow);
	NSMapRemove(windows, (void*)(intptr_t)[aWindow xcbWindowId]);
}
- (void)registerWindow: (XCBWindow*)aWindow
{
	NSLog(@"Registered window: %@", aWindow);
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
	xcb_grab_server(connection);
}

- (void)ungrab
{
	xcb_ungrab_server(connection);
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

@end

@implementation XCBConnection(Private)
- (void)flush
{
	xcb_flush(connection);
}
@end
