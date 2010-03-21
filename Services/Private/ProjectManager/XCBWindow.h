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

@interface XCBWindow : NSObject <XCBDrawable> {
	xcb_window_t window;
	XCBRect frame;
	int16_t border_width;
	XCBWindow *parent;
	xcb_get_window_attributes_reply_t attributes;
	id delegate;
}
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

/**
  * Find an XCBWindow with the specified ID.
  * Returns nil if the window has not been
  * created yet. Use this method when you can
  * be sure a window has been created already.
  */
+ (XCBWindow*)findXCBWindow:(xcb_window_t)aWindow;
- (void)setDelegate:(id)delegate;
- (id)delegate;
- (XCBWindow*)createChildInRect: (XCBRect)aRect;
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
- (void)addToSaveSet;
- (void)removeFromSaveSet;
- (void)destroy;
- (void)map;
- (void)unmap;
/**
  * Request an update of the window attributes. Once
  * the reply has been received, a XCBWindowFrame(Will/Did)ChangeNotification
  * will be generated.
  */
- (void)updateWindowAttributes;

/** Window attributes */
- (xcb_visualid_t)visual;
- (xcb_window_class_t)windowClass;
- (xcb_map_state_t)mapState;

/** XCBDrawable **/
- (xcb_drawable_t)xcbDrawableId;
@end

@interface NSObject (XCBWindowDelegate)
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
@end
