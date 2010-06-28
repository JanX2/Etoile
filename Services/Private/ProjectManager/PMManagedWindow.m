/**
 * Étoilé ProjectManager - PMManagedWindow.m
 *
 * Copyright (C) 2009 David Chisnall
 * Copyright (C) 2010 Christopher Armstrong
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
#import "PMManagedWindow.h"
#import "XCBWindow.h"
#import "XCBCachedProperty.h"
#import "XCBAtomCache.h"
#import "ICCCM.h"
#import "EWMH.h"
#import <EtoileFoundation/EtoileFoundation.h>

static const int DecorationWindowBorderSize = 4;

@interface PMManagedWindow (Private)
- (XCBRect)idealDecorationWindowFrame;
- (id)initWithChildWindow: (XCBWindow*)win;
/**
  * Reparent the child window into the decoration window
  * and then map the decoration window.
  *
  * Still requires that the child window be mapped using
  * -mapChildWindow
  */
- (void)mapDecorationWindow;
/**
  * Clean up after the child window was unmapped, including
  * reparenting the child back to the root window and 
  * unmmaping the decoration window.
  */
- (void)handleUnMap;
/**
  * Lazily create the decoration window
  */
- (void)createDecorationWindow;
/**
  * Map the child window and add it to the save set.
  */
- (void)mapChildWindow;
/**
  * Handle a child window that has just requested mapping
  * or was discovered in the map state.
  */
- (void)handleMapRequest;
/**
  * This method must be called when the window is ready
  * to transition from the PMManagedWindowWaitingOnPropertiesState
  * to one of the latter states. It checks the window
  * properties and pending events for map requests/already
  * mapped and determines if the window should be decorated,
  * etc.
  */
- (void)windowReadyForTransition;
- (void)xcbWindowBecomeAvailable: (NSNotification*)notification;
@end

@implementation PMManagedWindow
- (id)initWithChildWindow: (XCBWindow*)win pendingEvents: (NSArray*)pending
{
	SELFINIT;

	ASSIGN(child, win);
	ASSIGN(pendingEvents, pending);

	[child setDelegate: self];
	state = PMManagedWindowPendingState;

	if ([child windowLoadState] >= XCBWindowExistsState)
		[self xcbWindowDidCreate: nil];
	if ([child windowLoadState] >= XCBWindowAvailableState)
		[self xcbWindowBecomeAvailable: nil];
	return self;
}
- (void)dealloc
{
	NSDebugLLog(@"PMManagedWindow", @"%@: -[PMManagedWindow dealloc]", self);
	NSNotificationCenter *center =
		[NSNotificationCenter defaultCenter];
	[center removeObserver: self];
	[child setDelegate: nil];
	[child release];
	[pendingEvents release];
	[decorationWindow release];
	[super dealloc];
}
- (void)xcbWindowDidCreate: (NSNotification*)notification
{
	NSString *neededPropertyValuesArray[] = {
		ICCCMWMName,
		ICCCMWMNormalHints,
		ICCCMWMSizeHints,
		ICCCMWMHints,
		ICCCMWMTransientFor,
		ICCCMWMProtocols,
		EWMH_WMWindowType
	};
	NSArray *neededPropertyValues = [NSArray 
		arrayWithObjects: neededPropertyValuesArray
		           count: sizeof(neededPropertyValuesArray) / sizeof(NSString*)];
	ASSIGN(pendingWindowProperties, [NSMutableSet setWithCapacity: [neededPropertyValues count]]); 
	[pendingWindowProperties addObjectsFromArray: neededPropertyValues];
	[child refreshCachedProperties: neededPropertyValues];
}
- (void)xcbWindowBecomeAvailable: (NSNotification*)notification
{
	state = PMManagedWindowWaitingOnPropertiesState;
	if ([pendingWindowProperties count] == 0) {
		NSDebugLLog(@"PMManagedWindow", @"Become ready for transition form xcbWindowBecomeAvailable");
		[self windowReadyForTransition];
	}
}
- (XCBWindow*)childWindow
{
	return child;
}
- (void)createDecorationWindow
{
	XCBWindow *root = [child parent];
	NSDebugLLog(@"PMManagedWindow", @"-[PMMangedWindow initWithChildWindow:] Root: %@", root);
	NSNotificationCenter *center =
		[NSNotificationCenter defaultCenter];

	uint32_t values[3];
	// FIXME: Do these have to be in the same order as the
	// mask declarations?
	values[0] = 0x80FFFFA0;
	values[1] = 0;
	values[2] = XCB_EVENT_MASK_EXPOSURE |
		XCB_EVENT_MASK_BUTTON_PRESS | 
		XCB_EVENT_MASK_BUTTON_RELEASE;
	decorationWindow = 
		[[root createChildInRect: [self idealDecorationWindowFrame]
		            borderWidth: 0
		             valuesMask: XCB_CW_BACK_PIXEL | XCB_CW_OVERRIDE_REDIRECT | XCB_CW_EVENT_MASK
		                 values: values
		                  depth: 0
		                  class: XCB_WINDOW_CLASS_INPUT_OUTPUT
		                 visual: 0] retain];
	[center addObserver: self
	           selector: @selector(decorationWindowCreated:)
	               name: XCBWindowBecomeAvailableNotification
	             object: decorationWindow];
	[center addObserver: self
	           selector: @selector(decorationWindowDidMap:)
	               name: XCBWindowDidMapNotification
	             object: decorationWindow];
}
- (void)setDelegate: (id)dg
{
	self->delegate = dg;
}
- (XCBRect)idealDecorationWindowFrame
{
	XCBRect frame = [child frame];
	// FIXME
	xcb_translate_coordinates_cookie_t c = xcb_translate_coordinates(
		[XCBConn connection], 
		[decorationWindow xcbWindowId], 
		[[decorationWindow parent] xcbWindowId],
		frame.origin.x,
		frame.origin.y);
	xcb_translate_coordinates_reply_t *r = xcb_translate_coordinates_reply(
		[XCBConn connection],
		c,
		NULL);
	if (r!=NULL) 
	{
		frame.origin.x = r->dst_x;
		frame.origin.y = r->dst_y;
		free(r);
	}
	// END FIXME
	frame.origin.x -= DecorationWindowBorderSize;
	frame.origin.y -= DecorationWindowBorderSize;
	frame.size.height += 2 * DecorationWindowBorderSize;
	frame.size.width += 2 * DecorationWindowBorderSize;
	return frame;
}
- (void)xcbWindowPropertyDidRefresh: (NSNotification*)notification
{
	XCBCachedProperty *property = [[notification userInfo] objectForKey: @"PropertyValue"];
	[pendingWindowProperties removeObject: [property propertyName]];

	if (state == PMManagedWindowWaitingOnPropertiesState && 
			[pendingWindowProperties count] == 0)
	{
		NSDebugLLog(@"PMManagedWindow", @"Become ready for transition form xcbWindowPropertyDidRefresh");
		[self windowReadyForTransition];
	}
}

- (void)windowReadyForTransition
{
	if ([child mapState] == XCB_MAP_STATE_VIEWABLE)
		[self handleMapRequest];
	FOREACH(pendingEvents, pendingEvent, NSNotification*)
	{
		if ([[pendingEvent name] isEqual: XCBWindowMapRequestNotification])
		{
			[self handleMapRequest];
		}
	}	 
	ASSIGN(pendingEvents, nil);
}
- (void)xcbWindowMapRequest: (NSNotification*)aNotification
{
	NSDebugLLog(@"PMManagedWindow", @"%@: -[PMManagedWindow xcbWindowMapRequest:]", self);
	[self handleMapRequest];
}
- (void)xcbWindowDidMap: (NSNotification*)notification
{
	NSDebugLLog(@"PMManagedWindow", @"%@: -[PMManagedWindow xcbWindowDidMap:] child window mapped.", self);
}
- (void)xcbWindowConfigureRequest: (NSNotification*)aNotification
{
	// We receive configure requests in root window coordinates, even
	// when the client has been reparented into one of our decoration 
	// windows (this is an ICCCM requirement)
	NSInteger valueMask = [[[aNotification userInfo] objectForKey: @"ValueMask"] integerValue];
	
	// FIXME: We will need to do stacking and window size constraints here
	NSDebugLLog(@"PMManagedWindow", @"%@, -[PMManagedWindow xcbWindowConfigureRequest:]",  self);
	if (nil == decorationWindow)
		XCBWindowForwardConfigureRequest(aNotification);
	else
	{
	}
}
- (void)xcbWindowDidUnMap: (NSNotification*)aNotification
{
	if (!ignoreUnmap)
	{
		NSDebugLLog(@"PMManagedWindow", @"-[PMManagedWindow xcbWindowDidUnMap]: %@: Child window unmapped, removing decoration", self);
		[self handleUnMap];
	}
	ignoreUnmap = NO;
}
- (void)xcbWindowDidDestroy: (NSNotification*)aNotification
{
	NSDebugLLog(@"PMManagedWindow", @"%@: -[PMMangedWindow xcbWindowDidDestroy:] Child window destroyed.", self);
	// Destroy the decoration window but don't
	// release it yet
	[decorationWindow destroy];
	[delegate managedWindowWithdrawn: self];
}
- (void)xcbWindowFrameDidChange: (NSNotification*)aNotification
{
	NSDebugLLog(@"PMManagedWindow", @"%@: -[PMManagedWindow xcbWindowFrameDidChange]", self);
	XCBRect frame = [self idealDecorationWindowFrame];
	[[self decorationWindow] setFrame: frame];
}
- (XCBWindow*)decorationWindow
{
	return decorationWindow;
}
- (void)handleMapRequest
{
	XCBAtomCache *atomCache = [XCBAtomCache sharedInstance];
	// We should only be here if we are transitioning from
	// PMManagedWindowWaitingOnPropertiesState to the latter states

	// Determine if we need to decorate the window
	// 1. NEEDS DECORATION
	// 1a) If decoration window doesn't exist, create it
	// 1b) Reparent the child window into the decoration window and map the decoration window
	// 1c) Map the child window
	// 2. DOESN'T NEED DECORATION
	// 2a) Map the child window

	BOOL decorate = YES;
	XCBCachedProperty *wmHintsProperty = [child cachedPropertyValue: ICCCMWMHints];
	if (![wmHintsProperty isEmpty])
	{
		xcb_wm_hints_t wm_hints = [wmHintsProperty asWMHints];

	}
	XCBCachedProperty *ewmhWindowType = [child cachedPropertyValue: EWMH_WMWindowType];
	if (![ewmhWindowType isEmpty])
	{
		// FIXME: This is an atom list, not a single atom
		xcb_atom_t value = [ewmhWindowType asAtom];
		if ([atomCache atomNamed: EWMH_WMWindowTypeNormal] == value ||
			[atomCache atomNamed: EWMH_WMWindowTypeUtility] == value ||
			[atomCache atomNamed: EWMH_WMWindowTypeDialog] == value)
			decorate = YES;
		else
			decorate = NO;
	}
	// FIXME: Assuming reparenting (i.e. decoration) is needed
	NSDebugLLog(@"PMManagedWindow", @"%@: mapping the decoration window and then reparenting the child.", self);
	ignoreUnmap = YES;
	if (decorate)
	{
		if (decorationWindow == nil)
			[self createDecorationWindow];
		else
		{
			[self mapDecorationWindow];
			[self mapChildWindow];
		}
	}
	else
	{
		[self mapChildWindow];
	}
}
- (void)mapDecorationWindow
{
	reparented = YES;
	// Reposition the decoration window just above the original
	// window before reparenting so it comes out in the same
	// position
	[[self decorationWindow] restackAboveWindow: child];
	[[self decorationWindow] map];
	child_origin = [child frame].origin;
	[child reparentToWindow: decorationWindow
	                     dX: DecorationWindowBorderSize
	                     dY: DecorationWindowBorderSize];
	uint32_t value = XCB_EVENT_MASK_STRUCTURE_NOTIFY |
		XCB_EVENT_MASK_PROPERTY_CHANGE;
	[child changeWindowAttributes: XCB_CW_EVENT_MASK
	                       values: &value];
	
	[XCBConn setNeedsFlush: YES];
}

- (void)mapChildWindow
{
	[child map];
	[child addToSaveSet];
}
- (void)decorationWindowCreated: (NSNotification*)notification 
{
	NSDebugLLog(@"PMManagedWindow", @"%@: decoration window become available.", self);
	[self mapDecorationWindow];
	[self mapChildWindow];
}

- (void)handleUnMap
{
	NSDebugLLog(@"PMManagedWindow", @"%@: unmapping the decoration window and then unparenting the child.",self);
	if (reparented)
	{
		[decorationWindow unmap];
		// FIXME: Should we calculate where it was before?
		[child reparentToWindow: [decorationWindow parent]
				     dX: child_origin.x
				     dY: child_origin.y];
	}
	reparented = NO;
	[delegate managedWindowWithdrawn: self];
}

- (void)decorationWindowDidMap: (NSNotification*)notification
{
	//ignoreUnmap = NO;
}
- (NSString*)description
{
	return [NSString stringWithFormat: @"PMManagedWindow (child=%x,decorationWindow=%x)",
		[child xcbWindowId],
		[decorationWindow xcbWindowId]];
}
@end
