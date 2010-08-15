/**
 * Étoilé ProjectManager - PMConnectionDelegate.m
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
#import "PMConnectionDelegate.h"
#import "PMScreen.h"
#import "PMCompositeWindow.h"
#import "PMManagedWindow.h"
#import <XCBKit/XCBConnection.h>
#import <XCBKit/XCBDamage.h>
#import <XCBKit/XCBRender.h>
#import <XCBKit/XCBFixes.h>
#import <XCBKit/XCBComposite.h>
#import <XCBKit/XCBPixmap.h>
#import <XCBKit/XCBGeometry.h>
#import <XCBKit/XCBWindow.h>
#import <XCBKit/XCBShape.h>
#import <XCBKit/ICCCM.h>
#import <XCBKit/EWMH.h>
#import <XCBKit/XCBAtomCache.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSNotification.h>
#import <EtoileFoundation/EtoileFoundation.h>

@interface PMConnectionDelegate (Private)

- (void)redirectRootsForWindow: (XCBWindow*)rootWindow;
- (PMScreen*)findScreenWithRootWindow: (XCBWindow*)root;
- (void)paintAllWithRegion: (XCBFixesRegion*)region onScreen: (PMScreen*)screen;
- (PMCompositeWindow*)findCompositeWindow: (XCBWindow*)window;
- (void)removeCompositeWindow: (XCBWindow*)window;

- (void)XCBConnection: (XCBConnection*)connection damageAdd: (xcb_damage_add_request_t*)event;
- (void)handleQueryTree: (xcb_query_tree_reply_t*)query_tree_reply;
- (void)handleNewCompositedWindow: (XCBWindow*)window;
- (void)windowBecomeAvailable: (NSNotification*)notification;
- (void)newWindow: (XCBWindow*)window pendingEvent: (NSNotification*)notification;
@end

@implementation PMConnectionDelegate
- (id)init
{
	SUPERINIT;
	compositeWindows = [NSMutableDictionary new];
	managedWindows = [NSMutableDictionary new];
	decorationWindows = [NSMutableSet new];
	XCBConnection *conn = [XCBConnection sharedConnection];
	if (conn == nil)
		[NSException raise: NSInternalInconsistencyException
		            format: @"Unable to create connection to the server"];
	[XCBConn setDelegate: self];
	[XCBDamage initializeExtensionWithConnection: XCBConn];
	[XCBComposite initializeExtensionWithConnection: XCBConn];
	[XCBRender initializeExtensionWithConnection: XCBConn];
	[XCBFixes initializeExtensionWithConnection: XCBConn];
	[XCBShape initializeExtensionWithConnection: XCBConn];

	[[XCBAtomCache sharedInstance]
		cacheAtoms: ICCCMAtomsList()];
	[[XCBAtomCache sharedInstance]
		cacheAtoms: EWMHAtomsList()];

	self->screens = [NSMutableDictionary new];

	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

	[defaultCenter addObserver: self
	                  selector: @selector(windowDidMap:)
	                      name: XCBWindowDidMapNotification
	                    object: nil];
	[defaultCenter addObserver: self
	                  selector: @selector(windowBecomeAvailable:)
	                      name: XCBWindowBecomeAvailableNotification
	                    object: nil];
	uint32_t screen_id = 0;
	FOREACH([XCBConn screens], screen, XCBScreen*)
	{
		PMScreen *pm_screen = [[PMScreen alloc] 
			initWithScreen: screen 
			            id: screen_id++];
		
		[screens setObject: pm_screen 
		            forKey: screen];
		if (![pm_screen manageScreen])
		{
			[pm_screen release];
			[screens removeObjectForKey: screen];
			continue;
		}

		[pm_screen release];

		[self redirectRootsForWindow: [screen rootWindow]];
	}
	if ([screens count] == 0)
	{
		NSDebugLLog(@"PMConnectionDelegate", @"No screens to manage!");
		[self release];
		return nil;
	}
	
	[[XCBAtomCache sharedInstance] waitOnPendingAtomRequests];
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] 
		removeObserver: self];
	[screens release];
	[compositeWindows release];
	[managedWindows release];
	[super dealloc];
}


- (void)redirectRootsForWindow: (XCBWindow*)rootWindow
{
	 [XCBComposite redirectSubwindows: rootWindow 
	                           method: XCB_COMPOSITE_REDIRECT_MANUAL];
}

- (void)windowBecomeAvailable: (NSNotification*)notification
{
	XCBWindow *subject = [notification object];

	if ([subject parent] == nil)
		return;
	PMScreen *screen = [self findScreenWithRootWindow: [subject parent]];
	if (screen == nil)
	{
		// Can't be top-level. Ignore it.
		NSDebugLLog(@"PMConnectionDelegate", @"-[PMConnectionDelegate newWindow: ignoring non-top level window %@", subject);
		return;
	}

	if ([subject mapState] == XCB_MAP_STATE_VIEWABLE)
	{
		[self newWindow: subject pendingEvent: nil];
	}
	else 
		// Make ourselves the delegate so we get the *Request events
		[subject setDelegate: self];
}

- (void)xcbWindowConfigureRequest: (NSNotification*)notification
{
	NSDebugLLog(@"PMConnectionDelegate", @"-[PMConnectionDelegate xcbWindowConfigureRequest:] forwarding configure request for %@", [notification object]);
	// We just fulfil these without interruption
	XCBWindowForwardConfigureRequest(notification);
}
- (void)xcbWindowMapRequest: (NSNotification*)notification
{
	XCBWindow *subject = [notification object];
	NSDebugLLog(@"PMConnectionDelegate", @"-[PMConnectionDelegate xcbWindowMapRequest:] first map request for %@", subject);
	[self newWindow: subject pendingEvent: notification];
}
- (void)newWindow: (XCBWindow*)subject pendingEvent: (NSNotification*)notification
{
	if (![subject overrideRedirect] &&
		[managedWindows objectForKey: subject] == nil &&
		![decorationWindows containsObject: subject])
	{
		NSDebugLLog(@"PMConnectionDelegate", @"-[PMConnectionDelegate newWindow: pendingEvent:] managing %@", subject);
		NSArray *pendingEvents = notification != nil ? [NSArray arrayWithObject: notification] : nil;
		PMManagedWindow *managedWindow = [[[PMManagedWindow alloc] initWithChildWindow: subject
			pendingEvents: pendingEvents] autorelease];
		[managedWindow setDelegate: self];
		[managedWindows setObject: managedWindow forKey: subject];
	} 
	else if ([subject overrideRedirect] &&
		[decorationWindows containsObject: subject] == NO &&
		[compositeWindows objectForKey: subject] == nil)
	{
		[self handleNewCompositedWindow: subject];
	}
}
- (void)windowDidMap: (NSNotification*)notification 
{
	XCBWindow *window = [notification object];
	PMScreen *screen = [self findScreenWithRootWindow: [window parent]];
	if (screen == nil)
		return;
	NSDebugLLog(@"PMConnectionDelegate", @"-[PMConnectionDelegate windowDidMap:] handling newly mapped window %@", window);
	
	[self handleNewCompositedWindow: window];
}
- (void)managedWindowDidMap: (PMManagedWindow*)managedWindow
{
	XCBWindow * window = [managedWindow decorationWindow] != nil ?
		[managedWindow decorationWindow] :
		[managedWindow childWindow];
	[self handleNewCompositedWindow: window];
}
- (void)compositeWindowDidDestroy: (NSNotification*)notification
{
	XCBWindow *window = [notification object];
	[self removeCompositeWindow: window];
}

- (void)removeCompositeWindow: (XCBWindow*)window
{
	NSDebugLLog(@"PMConnectionDelegate", @"-[PMConnectionDelegate removeCompositeWindow:] %@", window);
	if ([compositeWindows objectForKey: window])
	{
		XCBREM_OBSERVER(WindowDidDestroy, window);
		[compositeWindows removeObjectForKey: window];
	}
}

- (void)handleNewCompositedWindow: (XCBWindow*)window
{
	// Don't create a new composited window if one already exists
	if ([compositeWindows objectForKey: window])
		return;
	PMScreen *screen = [self findScreenWithRootWindow: [window parent]];
	if (screen == nil)
		return;
	PMCompositeWindow *compositeWindow = [PMCompositeWindow windowWithXCBWindow: window];
	[compositeWindows setObject: compositeWindow forKey: window];
	[screen childWindowDiscovered: window
	              compositeWindow: compositeWindow];
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		   selector: @selector(compositeWindowDidDestroy:)
		       name: XCBWindowDidDestroyNotification
		     object: window];
}

- (void)managedWindowDestroyed: (PMManagedWindow*)managedWindow
{
	NSDebugLLog(@"PMConnectionDelegate", @"-[PMConnectionDelegate managedWindowDestroyed:]: %@", managedWindow);
	[managedWindows removeObjectForKey: [managedWindow childWindow]];
}
- (void)managedWindowWithdrawn: (PMManagedWindow*)managedWindow
{
	NSDebugLLog(@"PMConnectionDelegate", @"-[PMConnectionDelegate managedWindowWithdrawn:]: %@", managedWindow);
	if ([managedWindow decorationWindow] != nil)
	{
		[self removeCompositeWindow: [managedWindow decorationWindow]];
	}
	else
	{
		[self removeCompositeWindow: [managedWindow childWindow]];
	}
}

- (void)finishedProcessingEvents: (XCBConnection*)connection
{
	// NSDebugLLog(@"PMConnectionDelegate", @"Finished processing events.");
	FOREACH(screens, screen, PMScreen*)
	{
		[screen paintAllDamaged];
	}
}

- (PMCompositeWindow*)findCompositeWindow: (XCBWindow*)window
{
	return [compositeWindows objectForKey: window];
}

- (PMScreen*)findScreenWithRootWindow: (XCBWindow*)root
{
	FOREACH(screens, screen, PMScreen*)
	{
		if ([[screen rootWindow] isEqual: root])
			return screen;
	}
	return nil;
}
@end
