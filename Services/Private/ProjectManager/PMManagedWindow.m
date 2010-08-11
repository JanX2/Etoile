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
#import "XCBShape.h"
#import <EtoileFoundation/EtoileFoundation.h>

/**
  * XCB_MOD_MASK_MANY, renamed to workaround old
  * version of XCB not declaring it in xproto.h
  */
const uint16_t PM_XCB_MOD_MASK_ANY = 32768;

/**
  * The width of the border used to house the
  * resize handles. This should be at least 1px
  * greater than the resize handle width to allow
  * some space between the outer child border and
  * the resize handles
  */
static const uint32_t BORDER_WIDTHS[4] = { 8, 8, 8, 8};

static const uint32_t CHILD_BORDER_WIDTH = 1;

static const uint32_t RH_WIDTH = 4;
static const uint32_t MIN_RH_LENGTH = 20;
static const float RH_QUOTIENT = 0.15;

@interface PMManagedWindow (Private)
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
  * The term "client frame", as used in this file, is a rectangle
  * with the size (w,h) of the child window, and with the
  * position (x,y) of the outer border-adjusted or decoration-adjusted
  * north-west corner. A window that has been reparented will
  * use the decoration frame position, whilst an undecorated 
  * window will use the child-specified position (which is the
  * same as the outer-north west corner of the frame and which
  * automatically disregards border width
  */
- (XCBRect)clientFrame;
- (XCBRect)calculateDecorationFrame: (XCBRect)clientFrame;
- (void)sendSyntheticConfigureNotify: (XCBRect)clientFrame;
/**
  * Update the reference point of the window. This is the
  * point on the outer window frame (either the outer part
  * of a decoration window or on the outer part of a border)
  * selected for the current window gravity. 
  * 
  * This method must be called when the position of the frame
  * is to be adjusted, before -[PMManagedWindow repositionManagedWindow].
  */
- (void)updateRefPoint: (XCBRect)newRect gravity: (int)gravity;
/**
  * Changed the decoration frame and child frame on the server
  */
- (void)repositionManagedWindow: (XCBRect)newRect
                        gravity: (int)gravity;
- (void)updateShape;
- (void)updateShapeWithDecorationFrame: (XCBRect)decorationFrame
                            childFrame: (XCBRect)childFrame;
/**
  * Convert a point specified in root window space into
  * decoration window space. For example, with a root decoration window
  * at (45, 198) and a point in root space at (79, 210) will give
  * the result (34, 12)
  */
- (XCBPoint)convertScreenToBase: (XCBPoint)point;

/**
  * Determine the type of move or resize based on the
  * specified point (in decoration window space). This method
  * depends on size of the resize handles. The move-resize
  * type is specified using the EWMH constants.
  *
  * The result is unspecified if there is no decoration
  * window.
  */
- (int)moveresizeTypeForPoint: (XCBPoint)point;

/**
  * Adjusts the proposed client frame so that it
  * complies with the size hints specified when the
  * window was mapped, or otherwise, sane values (e.g.
  * positive size).
  */
- (XCBSize)adjustSizeForHints: (XCBSize)newSize;
- (void)establishInactiveGrabs;
- (void)setFocus;
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
	[[NSNotificationCenter defaultCenter]
		removeObserver: self];
	[child setDelegate: nil];
	[child release];
	[pendingEvents release];
	[decorationWindow release];
	[super dealloc];
}
- (NSString*)description
{
	return [NSString stringWithFormat: @"PMManagedWindow (child=%x,decorationWindow=%x)",
		[child xcbWindowId],
		[decorationWindow xcbWindowId]];
}
- (XCBWindow*)childWindow
{
	return child;
}
- (void)setDelegate: (id)dg
{
	self->delegate = dg;
}
- (XCBWindow*)decorationWindow
{
	return decorationWindow;
}
@end
@implementation PMManagedWindow (Private)
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
	
	req_border_width = [child borderWidth];
	// We send synthetic ConfigureNotify events but we
	// must ignore them because they mess up our child
	// frame values stored in XCBWindow and used to
	// calculate a range of internal values
	[child setIgnoreSyntheticConfigureNotify: YES];

	if ([pendingWindowProperties count] == 0) {
		NSDebugLLog(@"PMManagedWindow", @"Become ready for transition form xcbWindowBecomeAvailable");
		[self windowReadyForTransition];
	}
}
/**
  * TODO: Candidate for decoration class 
  */
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
		XCB_EVENT_MASK_BUTTON_1_MOTION |
		XCB_EVENT_MASK_STRUCTURE_NOTIFY |
		XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY |
		XCB_EVENT_MASK_SUBSTRUCTURE_REDIRECT |
		XCB_EVENT_MASK_FOCUS_CHANGE;
	decorationWindow = 
		[[root createChildInRect: [self calculateDecorationFrame: [child frame]]
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
	           selector: @selector(managedWindowButton1Press:)
	               name: XCBWindowButtonPressNotification
	             object: decorationWindow];
	[center addObserver: self
	           selector: @selector(managedWindowButton1Release:)
	               name: XCBWindowButtonReleaseNotification
	             object: decorationWindow];
	[center addObserver: self
	           selector: @selector(managedWindowButton1Move:)
	               name: XCBWindowMotionNotifyNotification
	             object: decorationWindow];
}
/**
  * Refactor so that border widths supplied by decoration
  * class or strategy
  */
- (XCBRect)calculateDecorationFrame: (XCBRect)clientFrame
{
	XCBRect frame = clientFrame;
	frame.origin.x -= BORDER_WIDTHS[ICCCMBorderWest];
	frame.origin.y -= BORDER_WIDTHS[ICCCMBorderNorth];
	frame.size.height += BORDER_WIDTHS[ICCCMBorderNorth] + BORDER_WIDTHS[ICCCMBorderSouth] ;
	frame.size.width += BORDER_WIDTHS[ICCCMBorderWest] + BORDER_WIDTHS[ICCCMBorderEast];
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
	NSDebugLLog(@"PMManagedWindow", @"%@ received focus in, raising to top and releasing grab", self);
	XCBWindow *w = reparented ? decorationWindow : child;
	[w restackAboveWindow: nil];
	self->has_focus = YES;
	[child ungrabButton: XCB_BUTTON_INDEX_1 modifiers: PM_XCB_MOD_MASK_ANY];
	// TODO: Move to decoration strategy through delegate or callback
	[self updateShape];
}
- (void)managedWindowFocusOut: (NSNotification*)aNotification
{
	//if (state == PMManagedWindowWithdrawnState)
	//	return;
	NSDebugLLog(@"PMManagedWindow", @"%@ focus out, grabbing", self);
	// FIXME: Move this so it occurs when the window is below the top,
	// not when it loses its focus.
	// 
	[self establishInactiveGrabs];
	self->has_focus = NO;

	// TODO: Move to decoration strategy through delegate or callback
	[self updateShape];
}
- (void)establishInactiveGrabs
{
	XCBWindow *w = reparented ? decorationWindow : child;
	int status = [child grabButton: XCB_BUTTON_INDEX_1
	    modifiers: PM_XCB_MOD_MASK_ANY
	    // Must be false so that the real window doesn't get normal events and undo the grab
	  ownerEvents: YES
	    eventMask: XCB_EVENT_MASK_BUTTON_PRESS | XCB_EVENT_MASK_BUTTON_1_MOTION | XCB_EVENT_MASK_BUTTON_RELEASE
	  pointerMode: XCB_GRAB_MODE_SYNC
	 keyboardMode: XCB_GRAB_MODE_ASYNC
	    confineTo: nil
	       cursor: XCB_NONE];
	NSDebugLLog(@"PMManagedWindow", @"%@ Grabbed button with status %d", self, status);
}
- (void)managedWindowButton1Press: (NSNotification*)aNotification
{
	if (state == PMManagedWindowWithdrawnState)
		return;
	NSDebugLLog(@"PMManagedWindow", @"%@ managedWindowButton1Press:", self);
	[XCBConn allowEvents: XCB_ALLOW_SYNC_POINTER timestamp: XCB_CURRENT_TIME /*[XCBConn currentTime]*/];
	//[XCBConn allowEvents: XCB_ALLOW_REPLAY_POINTER timestamp: XCB_CURRENT_TIME /*[XCBConn currentTime]*/];
	mouseDownPosition = [[[aNotification userInfo] objectForKey: @"RootPoint"] xcbPointValue];
	mouseDownClientFrame = [self clientFrame];
	moveresizeType = EWMH_WMMoveresizeCancel;

	uint8_t type = [self moveresizeTypeForPoint: [self convertScreenToBase: mouseDownPosition]];
	switch (type)
	{
	EWMH_WMMoveresizeSizeTopLeft:
	EWMH_WMMoveresizeSizeTop:
	EWMH_WMMoveresizeSizeTopRight:
	EWMH_WMMoveresizeSizeRight:
	EWMH_WMMoveresizeSizeBottomRight:
	EWMH_WMMoveresizeSizeBottom:
	EWMH_WMMoveresizeSizeBottomLeft:
	EWMH_WMMoveresizeSizeLeft:
	EWMH_WMMoveresizeSizeKeyboard:
		// Active grab pointer
		[XCBConn grabPointerWithWindow: decorationWindow
		                   ownerEvents: NO
		                     eventMask: XCB_EVENT_MASK_BUTTON_1_MOTION | XCB_EVENT_MASK_BUTTON_RELEASE 
		                   pointerMode: XCB_GRAB_MODE_SYNC
		                  keyboardMode: XCB_GRAB_MODE_SYNC
		                     confineTo: nil
		                        cursor: XCB_NONE
		                          time: [XCBConn currentTime]];
		break;
	EWMH_WMMoveresizeMove:
	EWMH_WMMoveresizeMoveKeyboard:
	EWMH_WMMoveresizeCancel:
	default:
		break;
	}
}
- (void)managedWindowButton1Move: (NSNotification*)notification
{
	XCBPoint currentPosition = [[[notification userInfo] objectForKey: @"RootPoint"] xcbPointValue];
	int16_t x_diff = currentPosition.x - mouseDownPosition.x;
	int16_t y_diff = currentPosition.y - mouseDownPosition.y;

	if (0 == x_diff && 0 == y_diff)
		return;

	if (moveresizeType == EWMH_WMMoveresizeCancel)
		moveresizeType = [self moveresizeTypeForPoint: [self convertScreenToBase: mouseDownPosition]];

	XCBRect newClientFrame;
	BOOL move = NO, drawProposed = NO;
	int gravity;
	switch (moveresizeType)
	{
		case EWMH_WMMoveresizeMove:
			{
				if (x_diff == 0 && y_diff == 0)
					return;
				// Update the reference positions
				XCBPoint newPoint = mouseDownClientFrame.origin;
				newPoint.x +=x_diff;
				newPoint.y += y_diff;

				move = YES;
				newClientFrame = XCBMakeRect(newPoint.x, newPoint.y, mouseDownClientFrame.size.width, mouseDownClientFrame.size.height);
				gravity = wm_size_hints.win_gravity;
			}
			break;
		case EWMH_WMMoveresizeSizeTopLeft:
			{
				XCBSize newSize = [self adjustSizeForHints: XCBMakeSize(mouseDownClientFrame.size.width - x_diff, mouseDownClientFrame.size.height - y_diff)];

				x_diff = mouseDownClientFrame.size.width - newSize.width;
				y_diff = mouseDownClientFrame.size.height - newSize.height;

				// Calculate the proposed client frame
				newClientFrame = XCBMakeRect(mouseDownClientFrame.origin.x + x_diff,
						mouseDownClientFrame.origin.y + y_diff,
						mouseDownClientFrame.size.width - x_diff,
						mouseDownClientFrame.size.height - y_diff);
				move = YES;
				drawProposed = NO;
				gravity = wm_size_hints.win_gravity;
			}
			break;
		case EWMH_WMMoveresizeSizeBottomRight:
			{
				XCBSize newSize = [self adjustSizeForHints: XCBMakeSize(mouseDownClientFrame.size.width + x_diff, mouseDownClientFrame.size.height + y_diff)];

				x_diff = mouseDownClientFrame.size.width - newSize.width;
				y_diff = mouseDownClientFrame.size.height - newSize.height;

				newClientFrame = XCBMakeRect(mouseDownClientFrame.origin.x,
					mouseDownClientFrame.origin.y,
					mouseDownClientFrame.size.width - x_diff,
					mouseDownClientFrame.size.height - y_diff);
				move = YES;
				drawProposed = NO;
				gravity = wm_size_hints.win_gravity;
			}
			break;
		case EWMH_WMMoveresizeSizeBottomLeft:
			{
				XCBSize newSize = [self adjustSizeForHints: XCBMakeSize(mouseDownClientFrame.size.width - x_diff, mouseDownClientFrame.size.height + y_diff)];

				x_diff = mouseDownClientFrame.size.width - newSize.width;
				y_diff = mouseDownClientFrame.size.height - newSize.height;

				newClientFrame = XCBMakeRect(mouseDownClientFrame.origin.x + x_diff,
					mouseDownClientFrame.origin.y,
					mouseDownClientFrame.size.width - x_diff,
					mouseDownClientFrame.size.height - y_diff);
				move = YES;
				drawProposed = NO;
				gravity = wm_size_hints.win_gravity;
			}
			break;
		case EWMH_WMMoveresizeSizeTopRight:
			{
				XCBSize newSize = [self adjustSizeForHints: XCBMakeSize(mouseDownClientFrame.size.width + x_diff, mouseDownClientFrame.size.height - y_diff)];

				x_diff = mouseDownClientFrame.size.width - newSize.width;
				y_diff = mouseDownClientFrame.size.height - newSize.height;

				newClientFrame = XCBMakeRect(mouseDownClientFrame.origin.x,
					mouseDownClientFrame.origin.y + y_diff,
					mouseDownClientFrame.size.width - x_diff,
					mouseDownClientFrame.size.height - y_diff);
				move = YES;
				drawProposed = NO;
				gravity = wm_size_hints.win_gravity;
			}
			break;
		case EWMH_WMMoveresizeCancel:
		default:
			break;
	}
	if (move)
	{
		[self updateRefPoint: newClientFrame gravity: gravity];
		[self repositionManagedWindow: newClientFrame gravity: gravity];
	}
	if (drawProposed)
	{
		xcb_gcontext_t id = xcb_generate_id([XCBConn connection]);
		xcb_create_gc(([XCBConn connection]), id, [[decorationWindow parent] xcbDrawableId],
				0, 0);
		xcb_rectangle_t rect = XCBRectangleFromRect(mouseDownClientFrame);
		xcb_poly_rectangle([XCBConn connection], [[decorationWindow parent] xcbDrawableId],
				id, 1, &rect);
		xcb_free_gc([XCBConn connection], id);
		xcb_flush([XCBConn connection]);

	}
}
- (void)managedWindowButton1Release: (NSNotification*)notification
{
	[XCBConn allowEvents: XCB_ALLOW_ASYNC_POINTER timestamp: [XCBConn currentTime]];

	if (moveresizeType == EWMH_WMMoveresizeCancel)
	{
		NSDebugLLog(@"PMManagedWindow", @"%@ button press and release, focusing window", self);
		// FIXME: Raise the window, offer/give it the focus and release
		// the grab
		[child ungrabButton: XCB_BUTTON_INDEX_1 modifiers: PM_XCB_MOD_MASK_ANY];
		[self setFocus];
	}
	else if (moveresizeType == EWMH_WMMoveresizeMove || moveresizeType == EWMH_WMMoveresizeMoveKeyboard)
	{
		NSDebugLLog(@"PMManagedWindow", @"%@ move complete", self);
	}

	else
	{
		NSDebugLLog(@"PMManagedWindow", @"%@ resize complete", self);
		[XCBConn ungrabPointer: [XCBConn currentTime]];
	}
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
	//if (state == PMManagedWindowWithdrawnState)
	//	[self handleMapRequest];
}
- (void)xcbWindowConfigureRequest: (NSNotification*)aNotification
{
	// We receive configure requests in root window coordinates, even
	// when the client has been reparented into one of our decoration 
	// windows (this is an ICCCM requirement)

	NSDictionary *userInfo = [aNotification userInfo];
	XCBRect requestedFrame = [[userInfo 
		objectForKey: @"Frame"] xcbRectValue];
	NSInteger valueMask = [[userInfo
		objectForKey: @"ValueMask"] intValue];

	XCBRect newRect;
	if (valueMask & XCB_CONFIG_WINDOW_X)
		newRect.origin.x = requestedFrame.origin.x;
	else
		newRect.origin.x = [child frame].origin.x;
	if (valueMask & XCB_CONFIG_WINDOW_Y)
		newRect.origin.y = requestedFrame.origin.y;
	else
		newRect.origin.y = [child frame].origin.y;
	if (valueMask & XCB_CONFIG_WINDOW_WIDTH)
		newRect.size.width = requestedFrame.size.width;
	else
		newRect.size.width = [child frame].size.width;
	if (valueMask & XCB_CONFIG_WINDOW_HEIGHT)
		newRect.size.height = requestedFrame.size.height;
	else
		newRect.size.height = [child frame].size.height;

	if (valueMask & XCB_CONFIG_WINDOW_BORDER_WIDTH)
	{
		req_border_width = [[userInfo objectForKey: @"BorderWidth"] intValue];
	}

	if (valueMask & (XCB_CONFIG_WINDOW_X | XCB_CONFIG_WINDOW_Y))
		[self updateRefPoint: newRect gravity: wm_size_hints.win_gravity];
	[self repositionManagedWindow: newRect gravity: wm_size_hints.win_gravity];

	// FIXME: We will need to do stacking and window size constraints here
	NSDebugLLog(@"PMManagedWindow", @"%@, -[PMManagedWindow xcbWindowConfigureRequest:]",  self);
}
- (void)updateRefPoint: (XCBRect)newRect gravity: (int)gravity
{
	// 1. Calculate reference point of child window outer frame
	XCBRect childInnerFrame = XCBCalculateBorderAdjustedFrame(newRect, req_border_width);
	// Update the reference point if origin changed
	refPoint =  ICCCMCalculateRefPointForClientFrame(gravity,
			childInnerFrame, 
			req_border_width);
}
- (void)repositionManagedWindow: (XCBRect)newRect gravity: (int)gravity
{
	if (decorationWindow)
	{
		// 2. Align decoration frame's ref point with the
		//    child's reference point.
		XCBRect decorationFrame = ICCCMDecorationFrameWithReferencePoint(
				gravity, refPoint, newRect.size, BORDER_WIDTHS);
		XCBRect childFrame = XCBMakeRect(
				BORDER_WIDTHS[ICCCMBorderWest] - CHILD_BORDER_WIDTH, BORDER_WIDTHS[ICCCMBorderNorth] - CHILD_BORDER_WIDTH, 
				newRect.size.width, newRect.size.height);
		[child setFrame: childFrame
		         border: CHILD_BORDER_WIDTH];
		[decorationWindow setFrame: decorationFrame border: 0];
		[self updateShapeWithDecorationFrame: decorationFrame childFrame: childFrame];
		[self sendSyntheticConfigureNotify: newRect];
	}
	else
	{
		// 2. Align decoration frame's ref point (in this case just a 1px border) with the
		//    child's reference point.
		uint32_t bws[4] = { 1, 1, 1, 1 };
		XCBRect decorationFrame = ICCCMDecorationFrameWithReferencePoint(gravity, refPoint, newRect.size, bws);
		// Okay, the width and size in decorationFrame is wrong, because the X server
		// automatically takes into account the border_width when specified. We really
		// just want the point from this function, as it tells us where to plonk
		// the child frame, adjusted for the child frame

		// No need for decoration window update or synthentic ConfigureNotify
		// because there is only the child window
		[child setFrame: XCBMakeRect(decorationFrame.origin.x, decorationFrame.origin.y, newRect.size.width, newRect.size.height)
		         border: CHILD_BORDER_WIDTH];
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
	state = PMManagedWindowWithdrawnState;
	[delegate managedWindowWithdrawn: self];
	[delegate managedWindowDestroyed: self];
}
- (void)xcbWindowFrameDidChange: (NSNotification*)aNotification
{
	NSDebugLLog(@"PMManagedWindow", @"%@: -[PMManagedWindow xcbWindowFrameDidChange]", self);
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
		mapState = ICCCMNormalWindowState;
		window_group = XCB_NONE;
		if (![wmHintsProperty isEmpty])
		{
			icccm_wm_hints_t wm_hints = [wmHintsProperty asWMHints];
			if (wm_hints.flags & ICCCMStateHint)
				mapState = wm_hints.initial_state;
			if (wm_hints.flags & ICCCMWindowGroupHint)
				window_group = wm_hints.window_group;
			if (wm_hints.flags & ICCCMInputHint)
				input_hint = wm_hints.input ? YES : NO;
			else
				input_hint = YES;
		}

		XCBCachedProperty *ewmhWindowType = [child cachedPropertyValue: EWMH_WMWindowType];
		if (![ewmhWindowType isEmpty])
		{
			// FIXME: This is an atom list, not a single atom
			xcb_atom_t value = [ewmhWindowType asAtom];
			NSDebugLLog(@"PMManagedWindow", @"%@ window type = %@", self, [[XCBAtomCache sharedInstance] nameForAtom: value]);

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
			wm_size_hints = [wmNormalHintsProperty asWMSizeHints];
		}
		if (!(wm_size_hints.flags & ICCCMPWinGravity))
		{
			wm_size_hints.win_gravity = ICCCMNorthWestGravity;
		}

		XCBCachedProperty *wmProtocols = [child cachedPropertyValue: ICCCMWMProtocols];
		if (![wmProtocols isEmpty])
		{
			NSDebugLLog(@"PMManagedWindow", @"%@ WM_PROTOCOLS found: %@", self, [wmProtocols asAtomArray]);
			wm_take_focus = [[wmProtocols asAtomArray] containsObject: ICCCMWMTakeFocus];
		}
		else
		{
			wm_take_focus = NO;
		}
		NSDebugLLog(@"PMManagedWindow", @"%@ wm_take_focus = %d", self, wm_take_focus);
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
	[child setWMState: state iconWindow: nil];
}
- (void)mapDecorationWindow
{
	reparented = YES;
	// Reposition the decoration window just above the original
	// window before reparenting so it comes out in the same
	// position
	[decorationWindow restackAboveWindow: child];
	[[self decorationWindow] map];
	[child 
		reparentToWindow: decorationWindow
		              dX: BORDER_WIDTHS[ICCCMBorderWest] - CHILD_BORDER_WIDTH
		              dY: BORDER_WIDTHS[ICCCMBorderEast] - CHILD_BORDER_WIDTH];

	[XCBConn setNeedsFlush: YES];
}

- (void)mapChildWindow
{
	// Reposition the decoration and child window
	// to where they were requested, based on gravity
	XCBRect childFrame = [child frame];
	[self updateRefPoint: childFrame gravity: wm_size_hints.win_gravity];
	[self repositionManagedWindow: childFrame gravity: wm_size_hints.win_gravity];

	// Register for useful notifications
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		   selector: @selector(managedWindowFocusIn:)
		       name: XCBWindowFocusInNotification
		     object: reparented ? decorationWindow : child];
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		   selector: @selector(managedWindowFocusOut:)
		       name: XCBWindowFocusOutNotification
		     object: reparented ? decorationWindow : child];
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		   selector: @selector(managedWindowButton1Press:)
		       name: XCBWindowButtonPressNotification
		     object: child];
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		   selector: @selector(managedWindowButton1Move:)
		       name: XCBWindowMotionNotifyNotification
		     object: child];
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		   selector: @selector(managedWindowButton1Release:)
		       name: XCBWindowButtonReleaseNotification
		     object: child];
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
	[child changeWindowAttributes: XCB_CW_EVENT_MASK 
	                       values: values];
	[child map];
	// If we are attached to a window that has already
	// been mapped, we need to call this manually because
	// there will be no MapNotify
	if ([child mapState] == XCB_MAP_STATE_VIEWABLE)
		[delegate managedWindowDidMap: self];
	[self establishInactiveGrabs];
	// FIXME: Establish a more sophisticated system of setting
	// initial window mapping focus
	//[self setFocus];
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
	[[NSNotificationCenter defaultCenter] 
		removeObserver: self 
		          name: XCBWindowFocusInNotification 
		        object: managed];
	[[NSNotificationCenter defaultCenter] 
		removeObserver: self 
		          name: XCBWindowFocusOutNotification 
		        object: managed];
	[[NSNotificationCenter defaultCenter] 
		removeObserver: self 
		          name: XCBWindowButtonPressNotification 
		        object: child];
	[[NSNotificationCenter defaultCenter] 
		removeObserver: self 
		          name: XCBWindowButtonReleaseNotification 
		        object: child];
	[[NSNotificationCenter defaultCenter] 
		removeObserver: self 
		          name: XCBWindowMotionNotifyNotification 
		        object: child];
	[[NSNotificationCenter defaultCenter] 
		removeObserver: self 
		          name: XCBWindowDidMapNotification 
		        object: managed];
	if (reparented)
	{
		[decorationWindow unmap];
		// FIXME: Should we calculate where it was before?
		XCBRect clientFrame = [self clientFrame];
		[child reparentToWindow: [decorationWindow parent]
		                     dX: clientFrame.origin.x
		                     dY: clientFrame.origin.y];

		// Reparenting windows does not send ConfigureNotify events.
		// According to Metacity bug 399552, we should not expect
		// clients to track ReparentNotify events to check their position,
		// so we should send a synthentic configure notify for 
		// them so they can update their internal state.
		[self sendSyntheticConfigureNotify: clientFrame];
	}
	reparented = NO;
	[child removeFromSaveSet];
	[delegate managedWindowWithdrawn: self];
}

- (XCBRect)clientFrame
{
	XCBRect decorationFrame = [decorationWindow frame];
	XCBRect childFrame =  [child frame];
	if (nil == decorationWindow)
	{
		return childFrame;
	}
	else
		return XCBMakeRect(decorationFrame.origin.x,
			decorationFrame.origin.y,
			childFrame.size.width,
			childFrame.size.height);
}
- (void)sendSyntheticConfigureNotify: (XCBRect)clientFrame
{
	xcb_configure_notify_event_t event;
	event.response_type = XCB_CONFIGURE_NOTIFY | 0x80;
	event.event = [[self childWindow] xcbWindowId];
	event.window = [[self childWindow] xcbWindowId];
	event.x = clientFrame.origin.x;
	event.y = clientFrame.origin.y;
	event.width = clientFrame.size.width;
	event.height = clientFrame.size.height;
	event.above_sibling = XCB_NONE;
	event.border_width = req_border_width;
	event.override_redirect = 0;
	[[self childWindow] 
		sendEvent: XCB_EVENT_MASK_STRUCTURE_NOTIFY
		propagate: 0
		     data: (const char*)&event];
}
/**
  * TODO: Move to decoration class
  */
- (void)updateShape
{
	[self updateShapeWithDecorationFrame: [decorationWindow frame]
	                          childFrame: [child frame]];
}
/**
  * TODO: Move to decoration class
  */
- (void)updateShapeWithDecorationFrame: (XCBRect)decorationFrame
                            childFrame: (XCBRect)childFrame
{
	if (nil != decorationWindow)
	{
		// Child location
		XCBPoint cp = childFrame.origin;

		// Child size
		XCBSize cs = childFrame.size;

		// Decoration Size
		XCBSize ds = decorationFrame.size;

		// Resize Handle Length
		int16_t rhl = MIN_RH_LENGTH;

		// Resize Handle Width
		int16_t rhw = RH_WIDTH;

		// Child border width
		int16_t cbw = CHILD_BORDER_WIDTH;
		if (has_focus)
		{

			xcb_rectangle_t rects[9] = {
				{ 0, 0, rhw + rhl, rhw }, // NW H
				{ ds.width - rhw - rhl, 0, rhw + rhl, rhw }, // NE H
				{ 0, rhw, rhw, rhl }, // NW V
				{ ds.width - rhw, rhw, rhw, rhl }, // NE V
				/* { cp.x, cp.y, cs.width + cbw * 2, cs.height + cbw * 2}, // Child */
				{ 0, ds.height - rhw - rhl, rhw, rhl }, // SW V
				{ ds.width - rhw, ds.height - rhl - rhw, rhw, rhl }, // SE V
				{ 0, ds.height - rhw, rhw + rhl, rhw }, // SW H
				{ ds.width - rhl - rhw, ds.height - rhw, rhl + rhw, rhw } // SE H
			};
			[decorationWindow setShapeRectangles: rects
						       count: 8
						    ordering: XCB_SHAPE_YXSORTED
						   operation: XCB_SHAPE_SO_SET
							kind: XCB_SHAPE_SK_BOUNDING
						      offset: XCBMakePoint(0, 0)];
			[decorationWindow 
				shapeCombineWithKind: XCB_SHAPE_SK_BOUNDING
				           operation: XCB_SHAPE_SO_UNION
				              offset: XCBMakePoint(BORDER_WIDTHS[ICCCMBorderWest], BORDER_WIDTHS[ICCCMBorderNorth])
				              source: child
				          sourceKind: XCB_SHAPE_SK_BOUNDING];
		}
		else
		{
			[decorationWindow 
				shapeCombineWithKind: XCB_SHAPE_SK_BOUNDING
				           operation: XCB_SHAPE_SO_SET
				              offset: XCBMakePoint(BORDER_WIDTHS[ICCCMBorderWest], BORDER_WIDTHS[ICCCMBorderNorth])
				              source: child
				          sourceKind: XCB_SHAPE_SK_BOUNDING];
			// xcb_rectangle_t rect = { cp.x, cp.y, cs.width + cbw * 2, cs.height + cbw*2};
			// [decorationWindow setShapeRectangles: &rect
			// 			       count: 1
			// 			    ordering: XCB_SHAPE_UNSORTED
			// 			   operation: XCB_SHAPE_SO_SET
			// 				kind: XCB_SHAPE_SK_BOUNDING
			// 			      offset: XCBMakePoint(0, 0)];
		}
	}
}
/**
  * TODO: Move to decoration class
  */
- (int)moveresizeTypeForPoint: (XCBPoint)point
{
	XCBRect df = [decorationWindow frame];
	XCBRect cf = [child frame];
	// Resize handle square size - the length of a resize handle square
	int16_t rhss = RH_WIDTH + MIN_RH_LENGTH;
	if (XCBPointInRect(point, cf))
		return EWMH_WMMoveresizeMove;
	else if (point.x < rhss && point.y < rhss)
		return EWMH_WMMoveresizeSizeTopLeft;
	else if (point.x >= (df.size.width - rhss) && point.y < rhss)
		return EWMH_WMMoveresizeSizeTopRight;
	else if (point.x < rhss && point.y >= (df.size.height - rhss))
		return EWMH_WMMoveresizeSizeBottomLeft;
	else if (point.x >= (df.size.width - rhss) && point.y >= (df.size.height - rhss))
		return EWMH_WMMoveresizeSizeBottomRight;
	else
		return EWMH_WMMoveresizeCancel;
}
- (XCBPoint)convertScreenToBase: (XCBPoint)point
{
	if (reparented)
	{
		XCBPoint decorationPoint = [decorationWindow frame].origin;
		return XCBMakePoint(point.x - decorationPoint.x, point.y - decorationPoint.y);
	}
	else
		return point;
}
- (XCBSize)adjustSizeForHints: (XCBSize)newSize
{
	int32_t min_width, min_height, max_width, max_height;
	// FIXME: This should be delegated out somehow and justifiable
	// Set the minimum width and height to be no smaller than the resize handles + some space
	int32_t min_size = MIN_RH_LENGTH * 2 + RH_WIDTH * 2 + 2;
	XCBSize ns = newSize;

	min_width = MAX(wm_size_hints.flags & ICCCMPMinSize ? wm_size_hints.min_width : 0, min_size);
	min_height = MAX(wm_size_hints.flags & ICCCMPMinSize ? wm_size_hints.min_height: 0, min_size);

	max_width = MIN(wm_size_hints.flags & ICCCMPMaxSize ? wm_size_hints.max_width : INT32_MAX, INT32_MAX);
	max_height = MIN(wm_size_hints.flags & ICCCMPMaxSize ? wm_size_hints.max_height : INT32_MAX, INT32_MAX);
	if (max_width < min_width)
		max_width = min_width;
	if (max_height < min_height)
		max_height = min_height;

	if (ns.width < min_width)
		ns.width = min_width;
	else if (ns.width > max_width)
		ns.width = max_width;

	if (ns.height < min_height)
		ns.height = min_height;
	else if (ns.height > max_height)
		ns.height = max_height;
	return ns;
}
- (void)setFocus
{
	if (input_hint)
	{
		NSLog(@"%@ Setting focus by SetInputFocus", self);
		[child setInputFocus: XCB_INPUT_FOCUS_PARENT time: [XCBConn currentTime]];
	}
	if (wm_take_focus)
	{
		NSLog(@"%@ Setting focus by WM_TAKE_FOCUS", self);
		xcb_client_message_event_t m;
		m.response_type = XCB_CLIENT_MESSAGE ;
		m.format = 32;
		m.type = [[XCBAtomCache sharedInstance] atomNamed: ICCCMWMProtocols];
		m.window = [child xcbWindowId];
		m.data.data32[0] = [[XCBAtomCache sharedInstance] atomNamed: ICCCMWMTakeFocus];
		m.data.data32[1] = [XCBConn currentTime];
		[child sendEvent: XCB_EVENT_MASK_NO_EVENT
		       propagate: NO
		            data: (const char*)&m];
	}
}
@end
