#import "XCBConnection.h"
#import "XCBScreen.h"
#import "XCBWindow.h"
#import "XCBAtomCache.h"
#import "PMConnectionDelegate.h"
#import <EtoileFoundation/EtoileFoundation.h>
#include <xcb/xcbext.h>
#include <xcb/damage.h>

@interface XCBConnection (EventHandlers)
- (void) handleMapNotify: (xcb_map_notify_event_t*)anEvent;
- (void) handleCreateNotify: (xcb_create_notify_event_t*)anEvent;
- (void) handleButtonPress: (xcb_map_notify_event_t*)anEvent;
@end
@implementation XCBConnection (EventHandlers)
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
	[delegate XCBConnection: self handleConfigureNotifyEvent: anEvent];
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	XCBWindow *win = [self windowForXCBId: anEvent->window];
	[win handleConfigureNotifyEvent: anEvent];
}
- (void) handleUnMapNotify: (xcb_unmap_notify_event_t*)anEvent
{
	NSLog(@"UnMapping window %d", anEvent->window);
	XCBWindow *win  = [self windowForXCBId: anEvent->window];
	[win handleUnMapNotifyEvent: anEvent];
}
- (void) handleMapNotify: (xcb_map_notify_event_t*)anEvent
{
	NSLog(@"Mapping window %d", anEvent->window);
	NSLog(@"Redirect? %d", anEvent->override_redirect);
	XCBWindow *win  = [self windowForXCBId: anEvent->window];
	[delegate XCBConnection: self mapWindow: win];
}
- (void) handleCreateNotify: (xcb_create_notify_event_t*)anEvent
{
	XCBWindow *win  = [XCBWindow windowWithCreateEvent: anEvent];
	//FIXME: Inefficient; track damaged regions in the client.
	xcb_damage_damage_t damageid = xcb_generate_id(connection);
	xcb_damage_create(connection, damageid, anEvent->window, XCB_DAMAGE_REPORT_LEVEL_RAW_RECTANGLES);
	xcb_flush(connection);
	NSLog(@"Registering for damage...");
	[delegate XCBConnection: self handleNewWindow: win];
}
@end

XCBConnection *XCBConn;

@implementation XCBConnection
+ (XCBConnection*)sharedConnection
{
	if (XCBConn == nil)
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

	replyHandlers = [NSMutableArray new];
	windows = NSCreateMapTable(NSIntMapKeyCallBacks,
			NSObjectMapValueCallBacks, 100);
	screens = [NSMutableArray new];

	// Hack needed because creating XCBWindow instances requires XCBConn to be
	// valid.
	XCBConn = self;

	// Set up event delivery
	int fd = xcb_get_file_descriptor(connection);
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
		[self registerWindow: [XCBWindow windowWithXCBWindow: screen->root]];

		uint32_t events = 
			XCB_EVENT_MASK_EXPOSURE | XCB_EVENT_MASK_BUTTON_PRESS |
		   	XCB_EVENT_MASK_KEY_PRESS | XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY;

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
	NSLog(@"Handling events");
	xcb_generic_event_t *event;
	while (NULL != (event = xcb_poll_for_event(connection)))
	{
		switch (event->response_type & ~0x80)
		{
			//HANDLE(KEY_PRESS, KeyPress)
			//HANDLE(KEY_RELEASE, KeyRelease)
			//HANDLE(BUTTON_RELEASE, ButtonRelease)
			HANDLE(BUTTON_PRESS, ButtonPress)
			HANDLE(MAP_REQUEST, MapRequest)
			HANDLE(UNMAP_NOTIFY, UnMapNotify)
			HANDLE(MAP_NOTIFY, MapNotify)
			HANDLE(CREATE_NOTIFY, CreateNotify)
			HANDLE(CONFIGURE_NOTIFY, ConfigureNotify)

			//HANDLE(EXPOSE, Expose)
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
	NSLog(@"Handling replies");
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
			NSLog(@"Got reply for %d", sequenceNumber);
			id obj = [handler objectAtIndex: 1];
			SEL selector;
			[[handler objectAtIndex: 2] getValue: &selector];
			[obj performSelector: selector withObject: (id)reply];
			free(reply);
			[replyHandlers removeObjectAtIndex: i];
			i--;
			repliesHandled = YES;
		}
	}
	return repliesHandled;
}
- (void) eventsReady: (NSNotification*)notification
{
	// Poll while there is data left in the buffer
	while ([self handleEvents] || [self handleReplies]) {}
	NSLog(@"Finished handling events");
	xcb_flush(connection);
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
- (void) registerWindow: (XCBWindow*)aWindow
{
	NSLog(@"Registered window: %@", aWindow);
	NSMapInsert(windows, (void*)(intptr_t)[aWindow xcbWindowId], aWindow);
}
- (XCBWindow*) windowForXCBId: (xcb_window_t)anId;
{
	return NSMapGet(windows, (void*)(intptr_t)anId);
}
- (void) setDelegate:(id) aDelegate
{
	delegate = aDelegate;
}
- (void) setSelector: (SEL)aSelector forXEvent: (uint8_t)anEvent
{
	extensionSelectors[anEvent] = aSelector;
}
- (NSArray*) screens
{
	return screens;
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
@end
