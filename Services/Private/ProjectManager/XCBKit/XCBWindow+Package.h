/**
 * Étoilé ProjectManager - XCBWindow+Package.h
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

#import <XCBKit/XCBWindow.h>

@interface XCBWindow (Package)
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
- (void)handleButtonPress: (xcb_button_press_event_t*)anEvent;
- (void)handleButtonRelease: (xcb_button_release_event_t*)anEvent;
- (void)handleFocusIn: (xcb_focus_in_event_t*)anEvent;
- (void)handleFocusOut: (xcb_focus_out_event_t*)anEvent;
- (void)handleMotionNotify: (xcb_motion_notify_event_t*)anEvent;
/**
  * Set the window that this window is positioned above.
  * This method must not be used as a public API. It is
  * currently used internally by XCBScreen to set the above
  * window when window tracking is on.
  *
  * You could use this to store the above window when
  * you have some means of tracking it correctly.
  */
- (void)setAboveWindow: (XCBWindow*)above;
@end
