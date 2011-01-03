/**
 * Étoilé ProjectManager - WorkspaceManager - PMWindowTracker.h
 *
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
#import <EtoileUI/EtoileUI.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import <XCBKit/ICCCM.h>
#import <XCBKit/XCBWindow.h>
#import <XCBKit/XCBNotifications.h>
#import <XCBKit/XCBCachedProperty.h>

extern NSString *PMProjectWindowProperty;
extern NSString *PMViewWindowProperty;

@class XWindowImageRep;
@class XCBDamage;
@class XCBRenderPicture;
@class XCBPixmap;

@interface PMWindowTracker : NSObject
{
@protected
	XCBWindow *window;
	XCBWindow *topLevelWindow;
	XCBDamage *damageTracker;
	NSMutableSet *waitingOnProperties;
	NSString *viewName, *projectName;
	// These track the ICCCM states of Withdrawn, Iconic and Normal
	ICCCMWindowState window_state;

	BOOL activated;
	// This tracks the Map/UnMap events so that we
	// know when a window is withdrawn.
	BOOL mapped;
	id delegate;

	NSBitmapImageRep *imageRep;
	XCBPixmap *windowPixmap;
	XCBPixmap *scalingPixmap;
	XCBRenderPicture *scalingPicture;
}
- (id)initByTrackingWindow: (XCBWindow*)aWindow;
- (BOOL)isTrackingWindow: (XCBWindow*)aWindow;
- (void)setDelegate: (id)aDelegate;
- (XCBWindow*)window;
- (XCBWindow*)topLevelWindow;
- (NSImage*)windowPixmap;
/**
  * The window name as a string. This method
  * can return nil and can also throw exceptions
  * if the window name is an unexpected type.
  */
- (NSString*)windowName;

/**
  * YES if the window has been activated (i.e. it is not in the 
  * ICCCM withdrawn state and is being managed by the window manager)
  * or NO if it is deactivated.
  */
- (BOOL)activated;
/**
  * The ICCCM window state. The value of this property is invalid
  * if -activated is NO.
  */
- (ICCCMWindowState)windowState;
@end

@interface NSObject (PMWindowTrackerDelegate)
- (void)trackedWindowActivated: (PMWindowTracker*)tracker;
- (void)trackedWindowDidShow: (PMWindowTracker*)tracker;
- (void)trackedWindowDidHide: (PMWindowTracker*)tracker;
- (void)trackedWindowDeactivated: (PMWindowTracker*)tracker;
- (void)trackedWindowPixmapUpdated: (PMWindowTracker*)tracker;
@end

