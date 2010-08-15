/**
 * Étoilé ProjectManager - XCBScreen.h
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
#import <XCBKit/XCBConnection.h>

@class XCBWindow;
@class XCBVisual;

@interface XCBScreen : NSObject {
	xcb_screen_t screen;
	XCBWindow *root;
	xcb_visualid_t default_visual;
	NSMutableArray* childWindows;
}
+ (XCBScreen*)screenWithXCBScreen: (xcb_screen_t*)aScreen;
- (XCBWindow*)rootWindow;
- (xcb_screen_t*)screenInfo;
- (xcb_visualid_t)defaultVisual;
- (uint8_t)defaultDepth;

// Methods related to child window tracking
/**
  * Get a list of the child windows, or nil
  * if window tracking is turned off. The
  * windows are listed in bottom to top
  * stacking order.
  */
- (NSArray*)childWindows;

/**
  * Change if window tracking is turned on or
  * off.
  *
  * If trackingChildren is YES, then XCBScreen
  * will start keeping track of all the child
  * windows of the root window for the screen.
  * It will first issue an xcb_query_tree() request
  * for asynchronously discovering the initial
  * window list, and then use notifications
  * to track new and deleted windows.
  *
  * Setting this to NO will cancel window tracking
  * and delete the child window list.
  * 
  * You must make sure that XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY
  * is selected on the root window in order to get the
  * needed child window events, or else this won't
  * update as windows are created/deleted.
  */
- (void)setTrackingChildren: (BOOL)trackingChildren;
@end
