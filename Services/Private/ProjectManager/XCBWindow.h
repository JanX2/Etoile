/**
 * Étoilé ProjectManager - XCBWindow.h
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
#import "XCBScreen.h"
#import "XCBGeometry.h"
#import "XCBDrawable.h"

// FIXME: Change frame/setFrame: to avoid type conflict with NSWindow

enum _XCBWindowLoadState
{
	/**
	  * A Create Window request has been issued for
	  * this window, but it has not been confirmed if it
	  * has been successfully created yet.
	  */
	XCBWindowCreatePendingState,
	/**
	  * Indicates a window that is known to exist in
	  * the server, but the locally cached window attributes
	  * are being requested and not valid yet.
	  *
	  * Any attempts to retrieve window attribute values
	  * (including the parent) may return invalid results.
	  * Only operate on window in this state if you
	  * do not care about its attribute values (e.g. to
	  * request property values be cached).
	  */
	XCBWindowExistsState,
	/**
	  * A window that the attributes have been successfully
	  * cached. The window attribute methods should return
	  * valid cached values.
	  * 
	  * Call -updateAttributes to request an updated copy
	  * of the window attributes.
	  */
	XCBWindowAvailableState,

	/**
	  * The Create Window request failed, and/or this object
	  * references an invalid window identifier.
	  */
	XCBWindowInvalidState
};
typedef enum _XCBWindowLoadState XCBWindowLoadState;

@interface XCBWindow : NSObject <XCBDrawable> {
	xcb_window_t window;
	XCBRect frame;
	int16_t border_width;
	XCBWindow *parent, *above;
	xcb_get_window_attributes_reply_t attributes;

	id delegate;
	
	XCBWindowLoadState window_load_state;
	uint32_t _cache_load_values;
}

/**
  * Get the window with the specified ID, or
  * create a new one if it doesn't exist. 
  * 
  * Use this window when you know of a window
  * that already exists and you just want to
  * reference it. If it doesn't exist, it will
  * be created.
  *
  * Remember that windows that are not in the
  * XCBWindowAvailableState can have invalid
  * values for all the attributes, the parent
  * object and the geometry values.
  */
+ (XCBWindow*)windowWithXCBWindow: (xcb_window_t)aWindow;
/**
  * Get the window with the specified ID, or
  * create a new one if it doesn't exist. The
  * parent specifier is needed so that -parent
  * returns something from the start.
  *
  * You should only use this method when you are
  * not sure if the window already exists, and you
  * have a way of knowing who its parent is (usually
  * through window tree traversal).
  */
+ (XCBWindow*)windowWithXCBWindow: (xcb_window_t)aWindow 
                           parent: (xcb_window_t)parent;

/**
  * Get a window from a create event. The
  * window ID and parent information contained
  * within is used to create the window if it
  * does not already exist.
  */ 
+ (XCBWindow*)windowWithCreateEvent: (xcb_create_notify_event_t*)anEvent;

- (XCBWindowLoadState) windowLoadState;

- (void)setDelegate:(id)delegate;
- (id)delegate;
- (XCBWindow*)createChildInRect: (XCBRect)aRect
                    borderWidth: (uint16_t)borderWidth;
- (XCBWindow*)createChildInRect: (XCBRect)aRect
                    borderWidth: (uint16_t)borderWidth
                     valuesMask: (uint32_t)valuesMask
                         values: (const uint32_t*)valuesList;
- (XCBWindow*)createChildInRect: (XCBRect)aRect
                    borderWidth: (uint16_t)borderWidth
                     valuesMask: (uint32_t)valuesMask
                         values: (const uint32_t*)valuesList
                          depth: (uint8_t)depth
                          class: (xcb_window_class_t)windowClass
                         visual: (xcb_visualid_t)visual;
- (XCBRect)frame;
- (void)setFrame: (XCBRect)aRect;
- (int16_t)borderWidth;
- (XCBWindow*)parent;
- (xcb_window_t)xcbWindowId;
- (void)handleConfigureNotifyEvent: (xcb_configure_notify_event_t*)anEvent;
- (void)handleUnMapNotifyEvent: (xcb_unmap_notify_event_t*)anEvent;
- (void)handleDestroyNotifyEvent: (xcb_destroy_notify_event_t*)anEvent;
- (void)handleCirculateNotifyEvent: (xcb_circulate_notify_event_t*)anEvent;
- (void)handleMapNotifyEvent: (xcb_map_notify_event_t*)anEvent;
- (void)handleExpose: (xcb_expose_event_t*)anEvent;
- (void)handleMapRequest: (xcb_map_request_event_t*)anEvent;
- (void)handleCirculateRequest: (xcb_circulate_request_event_t*)anEvent;
- (void)handleConfigureRequest: (xcb_configure_request_event_t*)anEvent;
- (void)handleReparentNotify: (xcb_reparent_notify_event_t*)anEvent;
- (void)addToSaveSet;
- (void)removeFromSaveSet;
- (void)destroy;
- (void)map;
- (void)unmap;
- (void)reparentToWindow: (XCBWindow*)newParent
                      dX: (uint16_t)dx
                      dY: (uint16_t)dy;
/**
  * Request an update of the window attributes. Once
  * the reply has been received, a XCBWindowFrame(Will/Did)ChangeNotification
  * will be generated.
  */
- (void)updateWindowAttributes;

/**
  * Change the window attributes
  */
- (void)changeWindowAttributes: (uint32_t)mask
                        values: (const uint32_t*)values;
/** Window attributes */
- (xcb_visualid_t)visual;
- (xcb_window_class_t)windowClass;
- (xcb_map_state_t)mapState;
- (BOOL) overrideRedirect;
- (XCBWindow*)aboveWindow;

/**
  * Reconfigure the window according to values
  * listed in xcb_config_window_t
  */
- (void) configureWindow: (uint16_t)valueMask
                  values: (const uint32_t*)values;

/** XCBDrawable **/
- (xcb_drawable_t)xcbDrawableId;
@end

@interface NSObject (XCBWindowDelegate)
- (void)xcbWindowBecomeAvailable: (NSNotification*)notification;
- (void)xcbWindowCreateFailed: (NSNotification*)notification;
- (void)xcbWindowFrameWillChange: (NSNotification*)notification;
- (void)xcbWindowFrameDidChange: (NSNotification*)notification;
- (void)xcbWindowDidCreate: (NSNotification*)notification;
- (void)xcbWindowDidDestroy: (NSNotification*)notification;
- (void)xcbWindowDidMap: (NSNotification*)notification;
- (void)xcbWindowWillUnMap: (NSNotification*)notification;
- (void)xcbWindowDidUnMap: (NSNotification*)notification;
- (void)xcbWindowPlacedOnTop: (NSNotification*)notification;
- (void)xcbWindowPlacedOnBottom: (NSNotification*)notification;
- (void)xcbWindowAttributesDidChange: (NSNotification*)notification;
- (void)xcbWindowExpose: (NSNotification*)notification;
- (void)xcbWindowMapRequest: (NSNotification*)notification;
- (void)xcbWindowCirculateRequest: (NSNotification*)notification;
- (void)xcbWindowConfigureRequest: (NSNotification*)notification;
- (void)xcbWindowParentDidChange: (NSNotification*)notification;
@end
