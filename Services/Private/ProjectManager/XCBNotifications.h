/**
 * Étoilé ProjectManager - XCBNotifications.h
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
#import <Foundation/NSString.h>

#ifndef DEFINE_NOTIFICATION
#define DEFINE_NOTIFICATION(x) extern NSString *XCB ## x ##Notification
#endif

DEFINE_NOTIFICATION(WindowDidDestroy);
DEFINE_NOTIFICATION(WindowDidMap);
DEFINE_NOTIFICATION(WindowWillUnMap);
DEFINE_NOTIFICATION(WindowDidUnMap);
DEFINE_NOTIFICATION(WindowFrameWillChange);
DEFINE_NOTIFICATION(WindowFrameDidChange);
DEFINE_NOTIFICATION(WindowPlacedOnTop);
DEFINE_NOTIFICATION(WindowPlacedOnBottom);
DEFINE_NOTIFICATION(WindowDidCreate);
DEFINE_NOTIFICATION(WindowBecomeAvailable);
DEFINE_NOTIFICATION(WindowCreateFailed);
DEFINE_NOTIFICATION(WindowAttributesDidChange);
DEFINE_NOTIFICATION(WindowExpose);
DEFINE_NOTIFICATION(WindowMapRequest);
DEFINE_NOTIFICATION(WindowUnMapRequest);
DEFINE_NOTIFICATION(WindowConfigureRequest);
DEFINE_NOTIFICATION(WindowCirculateRequest);
DEFINE_NOTIFICATION(WindowParentDidChange);

#define XCBNOTIFY_U(x, ui) \
{\
	NSNotificationCenter *_center = [NSNotificationCenter defaultCenter];\
	NSLog(@"%@ posting XCB" # x "Notification", self);\
	[_center postNotificationName: XCB ## x ## Notification\
	                      object: self\
			    userInfo: ui];\
}
#define XCBNOTIFY(x) XCBNOTIFY_U(x, nil)
#define XCBDELEGATE_U(x, ui) \
	if ([delegate respondsToSelector:@selector(xcb##x :)]) {\
		NSLog(@"%@ delegate " # x, self); \
		[delegate xcb##x :\
			[NSNotification\
			notificationWithName:\
			XCB##x##Notification \
			object:self \
			userInfo: ui]];\
	}
#define XCBDELEGATE(x) XCBDELEGATE_U(x, nil)

#define XCBREM_OBSERVER(not, obj) \
	[[NSNotificationCenter defaultCenter]\
		removeObserver:self\
		name:XCB ## not ## Notification\
		object: obj];
#undef DEFINE_NOTIFICATION
