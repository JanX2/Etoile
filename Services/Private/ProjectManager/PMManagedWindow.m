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
/**
  * Configure the frame of a decorated window. This process is:
  *  1. Getting the newly requested frame from a ConfigureRequest (or otherwise),
  *  2. Calculating the new decoration and child frames, 
  *  3. Issuing the configure requests for the new frames
  *  4. Notifying the client via a fake ConfigureNotify (if necessary)
  *
  * This method should not be used for non-decorated managed windows.
  * 
  * valueMask should have the bits set for the X, Y, WIDTH, and HEIGHT
  * components of a ConfigureRequest that have changed.
  */ 
- (void)configureDecoratedWindowFrame: (XCBRect)newRequestedFrame 
                            valueMask: (int)valueMask;
/**
  * Calculate the so called reference frame. This is the child
  * window rectangle in root coordinates. If the child window
  * is reparented, this gives the origin of it in root instead
  * of decoration window coordinates.
  */
- (XCBRect)referenceFrame;
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
	if (state == PMManagedWindowWithdrawnState)
		return;
	NSDebugLLog(@"PMManagedWindow", @"%@ focus out, grabbing", self);
	XCBWindow *w = reparented ? decorationWindow : child;
	[w grabButton: XCB_BUTTON_INDEX_1
	    modifiers: XCB_MOD_MASK_ANY
	  ownerEvents: YES
	    eventMask: XCB_EVENT_MASK_BUTTON_PRESS | XCB_EVENT_MASK_BUTTON_1_MOTION | XCB_EVENT_MASK_BUTTON_RELEASE
	  pointerMode: XCB_GRAB_MODE_ASYNC
	 keyboardMode: XCB_GRAB_MODE_ASYNC
	    confineTo: nil
	       cursor: XCB_NONE];
}
- (void)managedWindowButton1Press: (NSNotification*)aNotification
{
	if (state == PMManagedWindowWithdrawnState)
		return;
	lastMovePosition = [[[aNotification userInfo] objectForKey: @"RootPoint"] xcbPointValue];
	lastRefPosition = [self referenceFrame].origin;
	isMoving = NO;
}
- (void)managedWindowButton1Move: (NSNotification*)notification
{
	XCBPoint currentPosition = [[[notification userInfo] objectForKey: @"RootPoint"] xcbPointValue];
	int16_t x_diff = currentPosition.x - lastMovePosition.x;
	int16_t y_diff = currentPosition.y - lastMovePosition.y;
	if (0 == x_diff && 0 == y_diff)
		return;
	isMoving = YES;
	lastRefPosition.x += x_diff;
	lastRefPosition.y += y_diff;
	if (nil != decorationWindow)
	{
		[self 
			configureDecoratedWindowFrame: XCBMakeRect(lastRefPosition.x, lastRefPosition.y, 0, 0)
		                            valueMask: XCB_CONFIG_WINDOW_X | XCB_CONFIG_WINDOW_Y];
	}
	else
	{
		
		[child moveWindow: lastRefPosition];  
	}
	lastMovePosition = currentPosition;
}
- (void)managedWindowButton1Release: (NSNotification*)notification
{
	NSDebugLLog(@"PMManagedWindow", @"%@ button press and release, focusing window", self);
	if (!isMoving) 
	{
		[child setInputFocus: XCB_INPUT_FOCUS_PARENT time: [XCBConn currentTime]];
	}
	else
	{
		isMoving = NO;
	}
	[XCBConn allowEvents: XCB_ALLOW_ASYNC_POINTER timestamp: [XCBConn currentTime]];
}
- (void)managedWindowDidMap: (NSNotification*)notification
{
	if (state == PMManagedWindowWithdrawnState)
		return;
	NSDebugLLog(@"PMManagedWindow", @"%@ managed top-level window (child or decoration) mapped", self);
	[delegate managedWindowDidMap: self];
}

- (void)xcbWindowDidMap: (NSNotification*)notification
{
	NSDebugLLog(@"PMManagedWindow", @"%@: -[PMManagedWindow xcbWindowDidMap:] child window mapped.", self);
	// If we are withdrawn and get a map request, we
	// re-manage the window
	if (state == PMManagedWindowWithdrawnState)
		[self handleMapRequest];
}
- (void)xcbWindowConfigureRequest: (NSNotification*)aNotification
{
	// We receive configure requests in root window coordinates, even
	// when the client has been reparented into one of our decoration 
	// windows (this is an ICCCM requirement)
	
	// FIXME: We will need to do stacking and window size constraints here
	NSDebugLLog(@"PMManagedWindow", @"%@, -[PMManagedWindow xcbWindowConfigureRequest:]",  self);
	if (nil == decorationWindow)
		XCBWindowForwardConfigureRequest(aNotification);
	else
	{
		XCBRect requestedFrame = [[[aNotification userInfo] 
			objectForKey: @"Frame"] xcbRectValue];
		NSInteger valueMask = [[[aNotification userInfo] 
			objectForKey: @"ValueMask"] intValue];
		[self configureDecoratedWindowFrame: requestedFrame
		                          valueMask: valueMask];
	}
}

- (void)configureDecoratedWindowFrame: (XCBRect)newRequestedFrame valueMask: (int)valueMask
{
	XCBRect newReferenceFrame, decorationFrame, childFrame;
	// Need to set these values as they are used by the following 
	// function call (they are in and out values)
	childFrame = [child frame];
	decorationFrame = [decorationWindow frame];
	ICCCMCalculateWindowFrame(&refPoint, window_gravity, newRequestedFrame, valueMask,
		BORDER_WIDTHS, &decorationFrame, &childFrame,
		&newReferenceFrame);
	[[self childWindow] setFrame: childFrame];
	[[self decorationWindow] setFrame: decorationFrame];
	// FIXME: Post fake ConfigureNotify
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
	state = PMManagedWindowWithdrawnState;
	[delegate managedWindowWithdrawn: self];
	[delegate managedWindowDestroyed: self];
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
	uint32_t mapState = ICCCMNormalWindowState;

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
	if (state == PMManagedWindowWaitingOnPropertiesState || 
		state == PMManagedWindowWithdrawnState)
	{
		XCBCachedProperty *wmHintsProperty = [child cachedPropertyValue: ICCCMWMHints];
		if (![wmHintsProperty isEmpty])
		{
			icccm_wm_hints_t wm_hints = [wmHintsProperty asWMHints];
			if (wm_hints.flags & ICCCMStateHint)
				mapState = wm_hints.initial_state;
			else
				mapState = ICCCMNormalWindowState;
			if (wm_hints.flags & ICCCMWindowGroupHint)
				window_group = wm_hints.window_group;
			else
				window_group = XCB_NONE;
		}
		else
		{
			mapState = ICCCMNormalWindowState;
			window_group = XCB_NONE;
		}
		XCBCachedProperty *ewmhWindowType = [child cachedPropertyValue: EWMH_WMWindowType];
		if (![ewmhWindowType isEmpty])
		{
			// FIXME: This is an atom list, not a single atom
			xcb_atom_t value = [ewmhWindowType asAtom];
			if (/*[atomCache atomNamed: EWMH_WMWindowTypeNormal] == value || */
				[atomCache atomNamed: EWMH_WMWindowTypeUtility] == value ||
				[atomCache atomNamed: EWMH_WMWindowTypeDialog] == value)
				decorate = YES;
			else
				decorate = NO;
		}
		XCBCachedProperty *wmNormalHintsProperty = [child cachedPropertyValue: ICCCMWMNormalHints];
		if (![wmNormalHintsProperty isEmpty])
		{
			icccm_wm_size_hints_t h = [wmNormalHintsProperty asWMSizeHints];
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
	}

	// 2. Perform window transition to new state
	ignoreUnmap = YES;
	switch (mapState)
	{
	case ICCCMNormalWindowState:
		if (state == PMManagedWindowWithdrawnState || 
			state == PMManagedWindowWaitingOnPropertiesState)
		{
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
		else
		{
			if (decorationWindow)
			{
				[self mapDecorationWindow];
				[self mapChildWindow];
			}
			else
				[self mapChildWindow];
		}
		state = PMManagedWindowNormalState;
		break;
	case ICCCMIconicWindowState:
		state = PMManagedWindowIconicState;
		break;
	case ICCCMWithdrawnWindowState:
		[decorationWindow destroy];
		ASSIGN(decorationWindow, nil);
		state = PMManagedWindowWithdrawnState;
		break;
	}

	// Update WM_STATE
	[child setWMState: mapState iconWindow: nil];
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
		   selector: @selector(managedWindowButton1Press:)
		       name: XCBWindowButtonPressNotification
		     object: reparented ? decorationWindow : child];
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		   selector: @selector(managedWindowButton1Move:)
		       name: XCBWindowMotionNotifyNotification
		     object: reparented ? decorationWindow : child];
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		   selector: @selector(managedWindowButton1Release:)
		       name: XCBWindowButtonReleaseNotification
		     object: reparented ? decorationWindow : child];
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		   selector: @selector(managedWindowDidMap:)
		       name: XCBWindowDidMapNotification
		     object: reparented ? decorationWindow : child];

	uint32_t values[1];
	// These must be in the same order as the increasing
	// order of mask bit values.
	values[0] = XCB_EVENT_MASK_EXPOSURE |
		XCB_EVENT_MASK_BUTTON_PRESS | 
		XCB_EVENT_MASK_BUTTON_RELEASE | 
		XCB_EVENT_MASK_STRUCTURE_NOTIFY |
		XCB_EVENT_MASK_FOCUS_CHANGE | 
		XCB_EVENT_MASK_PROPERTY_CHANGE;
	[child changeWindowAttributes: XCB_CW_EVENT_MASK values: values];
	// If we are attached to a window that has already
	// been mapped, we need to call this manually because
	// there will be no MapNotify
	if ([child mapState] == XCB_MAP_STATE_VIEWABLE)
		[delegate managedWindowDidMap: self];
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
	[[NSNotificationCenter defaultCenter] removeObserver: self name: XCBWindowButtonReleaseNotification object: managed];
	[[NSNotificationCenter defaultCenter] removeObserver: self name: XCBWindowMotionNotifyNotification object: managed];
	if (reparented)
	{
		[decorationWindow unmap];
		// FIXME: Should we calculate where it was before?
		[child reparentToWindow: [decorationWindow parent]
				     dX: refPoint.x
				     dY: refPoint.y];
	}
	reparented = NO;
	[child removeFromSaveSet];
	[delegate managedWindowWithdrawn: self];
}

- (NSString*)description
{
	return [NSString stringWithFormat: @"PMManagedWindow (child=%x,decorationWindow=%x)",
		[child xcbWindowId],
		[decorationWindow xcbWindowId]];
}
- (XCBRect)referenceFrame
{
	XCBRect decorationFrame = [decorationWindow frame];
	XCBRect childFrame =  [child frame];
	if (nil == decorationWindow)
		return childFrame;
	else
		return XCBMakeRect(decorationFrame.origin.x + BORDER_WIDTHS[ICCCMBorderWest],
			decorationFrame.origin.y + BORDER_WIDTHS[ICCCMBorderNorth],
			childFrame.size.width,
			childFrame.size.height);
}
@end
