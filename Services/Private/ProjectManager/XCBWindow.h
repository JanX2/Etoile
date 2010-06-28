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

@class XCBCachedProperty;

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

	NSMutableDictionary *cached_property_values;
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
  * through window tree traversal). If the window
  * already exists, the parent attribute is ignored.
  *
  * If the window needs to be created, it will be
  * assumed it is at the bottom of the stacking order.
  * If this is not what you want, you should get the
  * correct stacking order and call +windowWithXCBWindow:parent:above:
  */
+ (XCBWindow*)windowWithXCBWindow: (xcb_window_t)aWindow 
                           parent: (xcb_window_t)parent;

/**
  * Get the window with the specified ID, or
  * create a new one if it doesn't exist.
  *
  * You must only use this method if you know
  * the window doesn't exist and you know the
  * parent and above windows. If the window has
  * already been created in the system, the parent
  * and above parameters are ignored.
  */
+ (XCBWindow*)windowWithXCBWindow: (xcb_window_t)aWindow 
                           parent: (xcb_window_t)parent
                            above: (xcb_window_t)above;
/**
  * Get a window from a create event. The
  * window ID and parent information contained
  * within is used to create the window if it
  * does not already exist.
  */ 
+ (XCBWindow*)windowWithCreateEvent: (xcb_create_notify_event_t*)anEvent;

/**
  * A global object that represents an "unknown" window
  * This is used when an XCBWindow needs to be returned, but
  * the value is unknown.
  */
+ (XCBWindow*)unknownWindow;

- (XCBWindowLoadState)windowLoadState;

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
- (void)restackAboveWindow: (XCBWindow*)aboveWindow;
- (void)restackBelowWindow: (XCBWindow*)belowWindow;
- (void)restackRelativeTo: (XCBWindow*)otherWindow
                stackMode: (xcb_stack_mode_t)stackMode;
/**
  * Reconfigure the window according to values
  * listed in xcb_config_window_t
  */
- (void)configureWindow: (uint16_t)valueMask
                 values: (const uint32_t*)values;

- (int16_t)borderWidth;
- (XCBWindow*)parent;
- (xcb_window_t)xcbWindowId;
- (void)addToSaveSet;
- (void)removeFromSaveSet;
- (void)destroy;
- (void)map;
- (void)unmap;
- (void)reparentToWindow: (XCBWindow*)newParent
                      dX: (uint16_t)dx
                      dY: (uint16_t)dy;
- (void)setInputFocus: (uint8_t)revert_to
                 time: (xcb_timestamp_t)time;
- (void)grabButton: (uint8_t)button
         modifiers: (uint16_t)modifiers
       ownerEvents: (uint8_t)ownerEvents
         eventMask: (uint16_t)eventMask
       pointerMode: (uint8_t)pointerMode
      keyboardMode: (uint8_t)keyboardMode
         confineTo: (XCBWindow*)confineWindow
            cursor: (xcb_cursor_t)cursor;
- (void)ungrabButton: (uint8_t)button
           modifiers: (uint8_t)modifiers;
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
- (BOOL)overrideRedirect;
/**
  * The window that this one is positioned above.
  * Returns the [XCBWindow] instance of the window
  * this is positioned above, nil if it is at the
  * bottom of the stacking order, or 
  * +[XCBWindow unknownWindow] if the window below
  * this one is unknown.
  */
- (XCBWindow*)aboveWindow;

/**
  * Reconfigure the window according to values
  * listed in xcb_config_window_t
  */
- (void)configureWindow: (uint16_t)valueMask
                 values: (const uint32_t*)values;

/**
  * Refresh the cached value of a property, or cache it
  * if it has not already been loaded. This method will
  * intern the corresponding atom if necessary.
  *
  * When the property has been re-cached, a XCBWindowPropertyDidRefreshNotification
  * shall be posted.
  */
- (void)refreshCachedProperty: (NSString*)propertyName;
- (void)refreshCachedProperties: (NSArray*)properties;
/**
  * Retreive the cached value of a property. This method
  * returns nil if the property has not been cached.
  */
- (XCBCachedProperty*)cachedPropertyValue: (NSString*)propertyName;

- (void)changeProperty: (NSString*)propertyName
                  type: (NSString*)type
                format: (uint8_t)format
                  mode: (xcb_prop_mode_t)mode
                  data: (const void*)data
                 count: (uint32_t)elementCount;

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
- (void)xcbWindowPropertyDidRefresh: (NSNotification*)notification;
- (void)xcbWindowPropertyDidChange: (NSNotification*)notification;
- (void)xcbWindowButtonPress: (NSNotification*)notification;
- (void)xcbWindowButtonRelease: (NSNotification*)notification;
- (void)xcbWindowFocusIn: (NSNotification*)notification;
- (void)xcbWindowFocusOut: (NSNotification*)notification;
@end

void XCBWindowForwardConfigureRequest(NSNotification* notification);
