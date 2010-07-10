/**
 * Étoilé ProjectManager - XCBScreen.m
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
#import "XCBWindow+Package.h"
#import "XCBVisual.h"

#import <EtoileFoundation/EtoileFoundation.h>

@interface XCBScreen (Private)
- (void)restackWindow: (XCBWindow*)xcbWindow
          aboveWindow: (id)xcbAboveWindow;

- (void)discoverChildWindows;
/**
  * Register a new child window. It is added at the end
  * of the child windows list. If the childWindows list
  * already contains this object, this method does nothing.
  */
- (void)registerChildWindow: (XCBWindow*)newWindow;
/**
  * Remove a child window from the childWindows list. This
  * method does nothing if the child window is not in the
  * list.
  */
- (void)unregisterChildWindow: (XCBWindow*)deleteWindow;
@end

@implementation XCBScreen 
- (id) initWithXCBScreen: (xcb_screen_t*)aScreen
{
	SELFINIT;
	screen = *aScreen;
	root = [[XCBWindow windowWithXCBWindow: screen.root parent: XCB_NONE] 
		retain];
	return self;
}
- (NSString*)description
{
	return [NSString stringWithFormat: @"XCBScreen screen=%d rootWindow=%@", screen, root];
}
+ (XCBScreen*) screenWithXCBScreen: (xcb_screen_t*)aScreen
{
	return [[[self alloc] initWithXCBScreen: aScreen] autorelease];
}
- (id)copyWithZone: (NSZone*)zone
{
	return [self retain];
}
- (void) dealloc
{
	[childWindows release];
	[root release];
	[super dealloc];
}
- (XCBWindow*)rootWindow
{
	return root;
}
- (xcb_screen_t*)screenInfo
{
	return &screen;
}

- (xcb_visualid_t)defaultVisual
{
	return screen.root_visual;
}
- (uint8_t)defaultDepth
{
	return screen.root_depth;
}
- (NSArray*)childWindows
{
	return childWindows;
}
- (void)setTrackingChildren: (BOOL)trackingChildren
{
	if (trackingChildren)
	{
		if (childWindows)
			return;
		childWindows = [NSMutableArray new];
		[self discoverChildWindows];
		[[NSNotificationCenter defaultCenter]
			addObserver: self
			   selector: @selector(childWindowFrameDidChange:)
			       name: XCBWindowFrameDidChangeNotification
			     object: nil];
		[[NSNotificationCenter defaultCenter]
			addObserver: self
			   selector: @selector(childWindowDidCreate:)
			       name: XCBWindowDidCreateNotification
			     object: nil];
		[[NSNotificationCenter defaultCenter]
			addObserver: self
			   selector: @selector(childWindowDidDestroy:)
			       name: XCBWindowDidDestroyNotification
			     object: nil];
		[[NSNotificationCenter defaultCenter]
			addObserver: self
			   selector: @selector(childWindowDidReparent:)
			       name: XCBWindowParentDidChangeNotification
			     object: nil];
	}
	else
	{
		if (!childWindows)
			return;
		[[NSNotificationCenter defaultCenter]
			removeObserver: self];
		[childWindows release];
		childWindows = nil;
	}
}
@end

@implementation XCBScreen (Private)
- (void)childWindowFrameDidChange: (NSNotification*)notification
{
	if (nil != childWindows)
	{
		XCBWindow *xcbWindow = [notification object];
		if ([[xcbWindow parent] isEqual: root])
		{
			// Restack window only if xcbAboveWindow is set
			// in the notification
			XCBWindow *xcbAboveWindow = [[notification userInfo] 
				objectForKey: @"Above"];
			if (xcbAboveWindow != nil)
			{
				[self restackWindow: xcbWindow
					aboveWindow: xcbAboveWindow];
			}
		}
	}
}
- (void)childWindowDidDestroy: (NSNotification*)notification
{
	if (nil == childWindows)
		return;
	XCBWindow *xcbWindow = [notification object];
	if ([[xcbWindow parent] isEqual: root])
		[childWindows removeObject: xcbWindow];
}
- (void)childWindowDidReparent: (NSNotification*)notification
{
	if (nil == childWindows)
		return;
	XCBWindow *xcbWindow = [notification object];
	if ([[xcbWindow parent] isEqual: root])
		[self registerChildWindow: xcbWindow];
	else if ([childWindows containsObject: xcbWindow])
		[self unregisterChildWindow: xcbWindow];
}
- (void)childWindowDidCreate: (NSNotification*)notification
{
	if (nil == childWindows)
		return;
	// We need to handle this notification to discover
	// new windows in case ConfigureNotify is never called.
	// The original windows are found through the query tree
	// process.
	//
	// We cannot use the WindowBecomeAvailable notification
	// because it will show up all the windows that were
	// discovered in the query tree process, and it doesn't
	// tell us if windows were created or discovered.

	// Newly created windows are placed at the top of
	// the stacking order, and windows that have received
	// a CreateNotify event know who their parent window
	// is.
	XCBWindow *window = [notification object];
	if ([[window parent] isEqual: root])
	{
		// Add window at the top
		[window setAboveWindow: [childWindows lastObject]];
		[self registerChildWindow: window];
	}
}
- (void)handleQueryTree: (xcb_query_tree_reply_t*)query_tree_reply
{
	int c_length = xcb_query_tree_children_length(query_tree_reply);
	xcb_window_t *windows = xcb_query_tree_children(query_tree_reply);
	XCBWindow* previous = nil;
	for (int i = 0; i < c_length; i++)
	{
		// Below, we infer two things from the nature of
		// xcb_query_tree requests:
		// 1. The root window is the root window specified
		//    in the reply (because this class only sends
		//    xcb_query_tree() on root windows)
		// 2. The window below us is the previous window
		//    we handled in the list, because xcb_query_tree()
		//    returns windows in bottom to top stacking order.
		XCBWindow *newWindow = 
			[XCBWindow 
				windowWithXCBWindow: windows[i]
			                     parent: query_tree_reply->root
			                      above: [previous xcbWindowId]];
		// We are assuming childWindows contains no
		// existing windows for this screen, so we can
		// just add them in bottom->top stacking order, which is the
		// order returned by xcb_query_tree()
		[newWindow setAboveWindow: previous];
		[self registerChildWindow: newWindow];
		previous = newWindow;
	}
	[XCBConn setNeedsFlush: YES];
}
- (void)restackWindow: (XCBWindow*)xcbWindow
          aboveWindow: (id)xcbAboveWindow
{
	if (![xcbAboveWindow isEqual: [NSNull null]]) 
	{
		// Insert after the above window
		NSUInteger aboveIndex;
		[xcbWindow retain];
		[childWindows removeObject: xcbWindow];
		aboveIndex  = [childWindows indexOfObject: xcbAboveWindow];
		[childWindows insertObject: xcbWindow 
				   atIndex: aboveIndex + 1];
		[xcbWindow release];
		[xcbWindow setAboveWindow: xcbAboveWindow];
	}
	else
	{
		// Insert at the bottom of the list
		[xcbWindow retain];
		[childWindows removeObject: xcbWindow];
		[childWindows insertObject: xcbWindow 
				   atIndex: 0];
		[xcbWindow release];
		[xcbWindow setAboveWindow: nil];
	}
}
- (void)discoverChildWindows
{
	// xcb_query_tree() for child windows and 
	// wait for callbacks
	xcb_query_tree_cookie_t query_tree_cookie = 
	xcb_query_tree_unchecked([XCBConn connection], [root xcbWindowId]);
	[XCBConn 
		setHandler: self
		  forReply: query_tree_cookie.sequence
		  selector: @selector(handleQueryTree:)];
}
- (void)registerChildWindow: (XCBWindow*)newWindow
{
	if (nil != childWindows &&
		![childWindows containsObject: newWindow])
		[childWindows addObject: newWindow];
}
/**
  * Remove a child window from the childWindows list. This
  * method does nothing if the child window is not in the
  * list.
  */
- (void)unregisterChildWindow: (XCBWindow*)deleteWindow
{
	if (nil != childWindows &&
		[childWindows containsObject: deleteWindow])
		[childWindows removeObject: deleteWindow];
}
@end
