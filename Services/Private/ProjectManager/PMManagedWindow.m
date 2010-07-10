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

const uint16_t XCB_MOD_MASK_ANY = 32768;

static const int DecorationWindowBorderSize = 4;
static const uint32_t BORDER_WIDTHS[4] = { 4, 4, 4, 4};

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
	values[0] = 0x00000000;
	values[1] = 0;
	values[2] = XCB_EVENT_MASK_EXPOSURE |
		XCB_EVENT_MASK_BUTTON_PRESS | 
		XCB_EVENT_MASK_BUTTON_RELEASE | 
		XCB_EVENT_MASK_STRUCTURE_NOTIFY |
		XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY |
		XCB_EVENT_MASK_SUBSTRUCTURE_REDIRECT |
		XCB_EVENT_MASK_FOCUS_CHANGE;
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
- (void)managedWindowFocusIn: (NSNotification*)aNotification
{
	NSDebugLLog(@"PMManagedWindow", @"%@ raising to top and releasing grab", self);
	XCBWindow *w = reparented ? decorationWindow : child;
	[w ungrabButton: XCB_BUTTON_INDEX_1 modifiers: XCB_MOD_MASK_ANY];
	[w restackAboveWindow: nil];
}
- (void)managedWindowFocusOut: (NSNotification*)aNotification
{
	NSDebugLLog(@"PMManagedWindow", @"%@ focus out, grabbing", self);
	XCBWindow *w = reparented ? decorationWindow : child;
	[w grabButton: XCB_BUTTON_INDEX_1
	    modifiers: XCB_MOD_MASK_ANY
	  ownerEvents: NO
	    eventMask: XCB_EVENT_MASK_BUTTON_PRESS
	  pointerMode: XCB_GRAB_MODE_ASYNC
	 keyboardMode: XCB_GRAB_MODE_ASYNC
	    confineTo: nil
	       cursor: XCB_NONE];
}
- (void)managedWindowButtonPress: (NSNotification*)aNotification
{
	NSDebugLLog(@"PMManagedWindow", @"%@ button press, focusing window", self);
	XCBWindow *w = reparented ? decorationWindow : child;
	[child setInputFocus: XCB_INPUT_FOCUS_PARENT time: [XCBConn currentTime]];
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
		XCBRect newReferenceFrame, newDecorationFrame, newChildFrame;
		ICCCMCalculateWindowFrame(&refPoint, window_gravity, [aNotification userInfo],
			BORDER_WIDTHS, &newDecorationFrame, &newChildFrame,
			&newReferenceFrame);
		[[self childWindow] setFrame: newChildFrame];
		[[self decorationWindow] setFrame: newDecorationFrame];
		// FIXME: Post fake ConfigureNotify
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
	XCBCachedProperty *wmNormalHintsProperty = [child cachedPropertyValue: ICCCMWMNormalHints];
	if (![wmNormalHintsProperty isEmpty])
	{
		xcb_size_hints_t h = [wmNormalHintsProperty asWMSizeHints];
		if (h.flags & ICCCMPMinSize)
		{
			min_width = h.min_width;
			min_height = h.min_height;
		}
		else if (h.flags & ICCCMPBaseSize)
		{
			min_width = h.base_width;
			min_height = h.base_height;
		}
		else
		{
			min_width = 10;
			min_height = 10;
		}

		if (h.flags & ICCCMPBaseSize)
		{
			base_width = h.base_width;
			base_height = h.base_height;
		}
		else
		{
			base_width = min_width;
			base_width = min_height;
		}

		if (h.flags & ICCCMPMaxSize)
		{
			max_width = h.max_width;
			max_height = h.max_height;
		}
		else
		{
			max_width = -1;
			min_width = -1;
		}

		if (h.flags & ICCCMPWinGravity)
			window_gravity = h.win_gravity;
		else
			window_gravity = ICCCMNorthWestGravity;
		// FIXME: Complete
	}
	else
	{
		// FIXME: Complete
	}
	refPoint = ICCCMCalculateReferencePoint(window_gravity, [[self childWindow] frame], BORDER_WIDTHS);
	ignoreUnmap = YES;
	if (decorate)
	{
		NSDebugLLog(@"PMManagedWindow", @"%@: mapping the decoration window and then reparenting the child.", self);
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
		NSDebugLLog(@"PMManagedWindow", @"%@: mapping the child without decoration.", self);
		[self mapChildWindow];
	}
}
- (void)mapDecorationWindow
{
	reparented = YES;
	// Reposition the decoration window just above the original
	// window before reparenting so it comes out in the same
	// position
	[decorationWindow restackAboveWindow: child];
	[[self decorationWindow] map];
	child_origin = [child frame].origin;
	[child reparentToWindow: decorationWindow
	                     dX: DecorationWindowBorderSize
	                     dY: DecorationWindowBorderSize];
	
	[XCBConn setNeedsFlush: YES];
}

- (void)mapChildWindow
{
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		   selector: @selector(managedWindowFocusIn:)
		       name: XCBWindowFocusInNotification
		     object: child];
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		   selector: @selector(managedWindowFocusOut:)
		       name: XCBWindowFocusOutNotification
		     object: child];
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		   selector: @selector(managedWindowButtonPress:)
		       name: XCBWindowButtonPressNotification
		     object: reparented ? decorationWindow : child];

	uint32_t values[1];
	// FIXME: Do these have to be in the same order as the
	// mask declarations?
	values[0] = XCB_EVENT_MASK_EXPOSURE |
		XCB_EVENT_MASK_BUTTON_PRESS | 
		XCB_EVENT_MASK_BUTTON_RELEASE | 
		XCB_EVENT_MASK_STRUCTURE_NOTIFY |
		XCB_EVENT_MASK_FOCUS_CHANGE | 
		XCB_EVENT_MASK_PROPERTY_CHANGE;
	[child changeWindowAttributes: XCB_CW_EVENT_MASK values: values];
	[child map];
	[child setInputFocus: XCB_INPUT_FOCUS_PARENT time: [XCBConn currentTime]];
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
	XCBWindow *managed = reparented ? decorationWindow : child;
	[[NSNotificationCenter defaultCenter] removeObserver: self name: XCBWindowFocusInNotification object: managed];
	[[NSNotificationCenter defaultCenter] removeObserver: self name: XCBWindowFocusOutNotification object: managed];
	[[NSNotificationCenter defaultCenter] removeObserver: self name: XCBWindowButtonPressNotification object: managed];
	if (reparented)
	{
		[decorationWindow unmap];
		// FIXME: Should we calculate where it was before?
		[child reparentToWindow: [decorationWindow parent]
				     dX: child_origin.x
				     dY: child_origin.y];
	}
	reparented = NO;
	[child removeFromSaveSet];
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
