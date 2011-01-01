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
#include <EtoileUI/EtoileUI.h>
#include <EtoileFoundation/EtoileFoundation.h>
#include <XCBKit/XCBWindow.h>
#include <XCBKit/XCBNotifications.h>
#include <XCBKit/XCBCachedProperty.h>

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
	BOOL activated, mapped;
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
- (NSImage*)windowPixmap;
- (NSString*)windowName;
@end

@interface NSObject (PMWindowTrackerDelegate)
- (void)trackedWindowActivated: (PMWindowTracker*)tracker;
- (void)trackedWindowDidShow: (PMWindowTracker*)tracker;
- (void)trackedWindowDidHide: (PMWindowTracker*)tracker;
- (void)trackedWindowDeactivated: (PMWindowTracker*)tracker;
- (void)trackedWindowPixmapUpdated: (PMWindowTracker*)tracker;
@end

