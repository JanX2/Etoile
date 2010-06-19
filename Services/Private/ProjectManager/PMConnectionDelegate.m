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
#import "XCBConnection.h"
#import "XCBDamage.h"
#import "XCBRender.h"
#import "XCBFixes.h"
#import "XCBComposite.h"
#import "XCBPixmap.h"
#import "XCBGeometry.h"
#import "XCBWindow.h"
#import "ICCCM.h"
#import "EWMH.h"
#import "XCBAtomCache.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSNotification.h>
#import <EtoileFoundation/EtoileFoundation.h>

@interface PMConnectionDelegate (Private)

- (void)redirectRootsForWindow: (XCBWindow*)rootWindow;
- (void)newWindow: (XCBWindow*)window;
- (PMScreen*)findScreenWithRootWindow: (XCBWindow*)root;
- (void)paintAllWithRegion: (XCBFixesRegion*)region onScreen: (PMScreen*)screen;
- (PMCompositeWindow*)findCompositeWindow: (XCBWindow*)window;
- (void)removeManagedWindow: (XCBWindow*)window;

- (void)XCBConnection: (XCBConnection*)connection damageAdd: (xcb_damage_add_request_t*)event;
- (void)handleQueryTree: (xcb_query_tree_reply_t*)query_tree_reply;
- (void)handleNewCompositedWindow: (XCBWindow*)window;
- (void)windowBecomeAvailable: (NSNotification*)notification;
@end


@implementation PMConnectionDelegate

- (id)init
{
	SUPERINIT;
	compositeWindows = [NSMutableDictionary new];
	managedWindows = [NSMutableDictionary new];
	decorationWindows = [NSMutableSet new];
	[[XCBConnection sharedConnection] setDelegate:self];
	[XCBDamage initializeExtensionWithConnection: XCBConn];
	[XCBComposite initializeExtensionWithConnection: XCBConn];
	[XCBRender initializeExtensionWithConnection: XCBConn];
	[XCBFixes initializeExtensionWithConnection: XCBConn];

	[[XCBAtomCache sharedInstance]
		cacheAtoms: ICCCMAtomsList()];
	[[XCBAtomCache sharedInstance]
		cacheAtoms: EWMHAtomsList()];

	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

	[defaultCenter addObserver: self
	                  selector: @selector(windowDidMap:)
	                      name: XCBWindowDidMapNotification
	                    object: nil];
	[defaultCenter addObserver: self
	                  selector: @selector(windowDidUnMap:)
	                      name: XCBWindowDidUnMapNotification
	                    object: nil];
	[defaultCenter addObserver: self
	                  selector: @selector(windowBecomeAvailable:)
	                      name: XCBWindowBecomeAvailableNotification
	                    object: nil];
	[defaultCenter addObserver: self
	                  selector: @selector(windowDidReparent:)
	                      name: XCBWindowParentDidChangeNotification
	                    object: nil];

	self->screens = [NSMutableDictionary new];

	[XCBConn grab];
	uint32_t screen_id = 0;
	FOREACH([XCBConn screens], screen, XCBScreen*)
	{
		PMScreen *pm_screen = [[PMScreen alloc] 
			initWithScreen: screen 
			            id: screen_id++];
		if (![pm_screen manageScreen])
		{
			[pm_screen release];
			continue;
		}


		[screens setObject: pm_screen 
		            forKey: screen];
		[pm_screen release];


		[self redirectRootsForWindow: [screen rootWindow]];
	}
	[XCBConn ungrab];
	xcb_flush([XCBConn connection]);
	if ([screens count] == 0)
	{
		NSLog(@"No screens to manage!");
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

- (void)windowDidMap: (NSNotification*)notification 
{
	XCBWindow *window = [notification object];
	PMScreen *screen = [self findScreenWithRootWindow: [window parent]];
	if (screen == nil)
		return;
	[self handleNewCompositedWindow: window];
}

- (void)windowDidUnMap: (NSNotification*)notification
{
}

- (void)compositeWindowDidDestroy: (NSNotification*)notification
{
	XCBWindow *window = [notification object];
	if ([compositeWindows objectForKey: window])
	{
		NSLog(@"-[PMConnectionDelegate compositeWindowDidDestroy] %@", [notification object]);
		XCBREM_OBSERVER(WindowDidDestroy, window);
		[compositeWindows removeObjectForKey: window];
	}
}

- (void)windowDidReparent: (NSNotification*)notification
{
	XCBWindow *window = [notification object];
	PMScreen * screen = [self findScreenWithRootWindow: [window parent]];
	
	if (screen)
		// Window reparented to root window
		[screen childWindowDiscovered: window
		              compositeWindow: nil];
	else
	{
		// Window reparented to a child window (we're looking for the case
		// we reparented something to a decoration window)
		screen = [self 
			findScreenWithRootWindow: [[notification userInfo] objectForKey: @"OldParent"]];
		// There is the slight chance we received a reparent notify
		// for a child window of something we're not managing
		if (!screen)
			return;
		[screen childWindowRemoved: window];
	}
}
- (void)XCBConnection: (XCBConnection*)connection damageNotify: (xcb_damage_notify_event_t*)event
{
	//NSLog(@"Damage notify {%d, %d, %d, %d}", 
	//	event->area.x, event->area.y, event->area.width, event->area.height);
	XCBWindow *damagedWindow = [XCBWindow windowWithXCBWindow: event->drawable];
	PMCompositeWindow *compositeWindow = [self findCompositeWindow: damagedWindow];
	if (compositeWindow != nil)
	{
		PMScreen *screen = [self findScreenWithRootWindow: [damagedWindow parent]];
		if (nil == screen)
			NSLog(@"-[PMConnectionDelegate damageNotify:] ERROR screen not found.");
		// FIXME: Find out why we don't deal with the area that was damaged
		// I'm thinking the XServer knows automatically, but I cannot understand
		// the spec (carmstrong)
		XCBFixesRegion *partsRegion = [compositeWindow windowDamaged];
		[screen appendDamage: partsRegion];
	}
	else
		NSLog(@"-[PMConnectionDelegate damageNotify:] ERROR compositewindow for XCBWindow %@ not found.", damagedWindow);
}

- (void)newWindow: (XCBWindow*)subject
{
	PMScreen *screen = [self findScreenWithRootWindow: [subject parent]];
	if (screen == nil)
	{
		// Can't be top-level. Ignore it.
		NSLog(@"-[PMConnectionDelegate newWindow: ignoring non-top level window %@", subject);
		return;
	}

	if (![subject overrideRedirect] &&
		[managedWindows objectForKey: subject] == nil)
	{
		NSLog(@"-[PMConnectionDelegate windowDidBecomeAvailable] managing %@", subject);
		PMManagedWindow *managedWindow = [PMManagedWindow windowDecoratingWindow: subject];
		[managedWindows setObject: managedWindow forKey: subject];
		[[NSNotificationCenter defaultCenter]
			addObserver: self
			   selector: @selector(managedWindowDidDestroy:)
			       name: XCBWindowDidDestroyNotification
			     object: subject];
		[screen childWindowDiscovered: subject
		              compositeWindow: nil];
	} 
	else if ([subject overrideRedirect] &&
		[decorationWindows containsObject: subject] == NO &&
		[compositeWindows objectForKey: subject] == nil)
	{
		[self handleNewCompositedWindow: subject];
	}
}

- (void)windowBecomeAvailable: (NSNotification*)notification
{
	XCBWindow *subject = [notification object];

	if ([subject parent] == nil)
		return;
	[self newWindow: subject];
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

- (void)managedWindowDidDestroy: (NSNotification*)notification
{
	if ([managedWindows objectForKey: [notification object]])
		[self removeManagedWindow: [notification object]];
}

- (void)removeManagedWindow: (XCBWindow*)window
{
	NSLog(@"-[PMConnectionDelegate removeManagedWindow:]: %@", window);
	XCBREM_OBSERVER(WindowDidDestroy, window);
	PMManagedWindow *managedWindow = [managedWindows objectForKey: window];
	[decorationWindows removeObject: [managedWindow decorationWindow]];
	[managedWindows removeObjectForKey: window];
}

- (void)finishedProcessingEvents: (XCBConnection*)connection
{
	// NSLog(@"Finished processing events.");
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
		if ([[screen rootWindow] isEqual:root])
			return screen;
	}
	return nil;
}
@end
