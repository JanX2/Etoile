/**
 * Étoilé ProjectManager - ICCCM.m
 *
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
#import "ICCCM.h"
#import "XCBGeometry.h"

NSString* ICCCMWMName = @"WM_NAME";
NSString* ICCCMWMIconName = @"WM_ICON_NAME";
NSString* ICCCMWMNormalHints = @"WM_NORMAL_HINTS";
NSString* ICCCMWMSizeHints = @"WM_SIZE_HINTS";
NSString* ICCCMWMHints = @"WM_HINTS";
NSString* ICCCMWMClass = @"WM_CLASS";
NSString* ICCCMWMTransientFor = @"WM_TRANSIENT_FOR";
NSString* ICCCMWMProtocols = @"WM_PROTOCOLS";
NSString* ICCCMWMColormapWindows = @"WM_COLORMAP_WINDOWS";
NSString* ICCCMWMClientMachine = @"WM_CLIENT_MACHINE";

// Properties set by a Window Manager on a Client Window
NSString* ICCCMWMState = @"WM_STATE";
NSString* ICCCMWMIconSize = @"WM_ICON_SIZE";

// ICCCM WM_PROTOCOLS
NSString* ICCCMWMTakeFocus = @"WM_TAKE_FOCUS";
NSString* ICCCMWMSaveYourself = @"WM_SAVE_YOURSELF";
NSString* ICCCMWMDeleteWindow = @"WM_DELETE_WINDOW";

NSArray *ICCCMAtomsList(void)
{
	NSString* atoms[] = {
		ICCCMWMName,
		ICCCMWMIconName,
		ICCCMWMNormalHints, 
		ICCCMWMSizeHints, 
		ICCCMWMHints, 
		ICCCMWMClass, 
		ICCCMWMTransientFor, 
		ICCCMWMProtocols, 
		ICCCMWMColormapWindows, 
		ICCCMWMClientMachine, 
		ICCCMWMState, 
		ICCCMWMIconSize, 

		ICCCMWMTakeFocus, 
		ICCCMWMSaveYourself, 
		ICCCMWMDeleteWindow
	};
	// Remember, only works with static allocated arrays
	return [NSArray arrayWithObjects: atoms 
	                           count: sizeof(atoms) / sizeof(NSString*)];
}

@implementation XCBWindow (ICCCM)
- (void)setWMState: (uint32_t)newState iconWindow: (XCBWindow*)iconWindow
{
	icccm_wm_state_t new_icccm_state = { newState, [iconWindow xcbWindowId] };
	[self replaceProperty: ICCCMWMState
	                  type: ICCCMWMState
	                format: XCB32PropertyFormat
	                  data: &new_icccm_state
	                 count: 2];
}
@end

@implementation XCBCachedProperty (ICCCM)
- (icccm_wm_size_hints_t)asWMSizeHints
{
	icccm_wm_size_hints_t size_hints;
	[self checkAtomType: ICCCMWMSizeHints];
	[[self data] getBytes: &size_hints
	               length: sizeof(icccm_wm_size_hints_t)];
	return size_hints;
}
- (icccm_wm_hints_t)asWMHints
{
	icccm_wm_hints_t hints;
	[self checkAtomType: ICCCMWMHints];
	[[self data] getBytes: &hints
	               length: sizeof(icccm_wm_hints_t)];
	return hints;
}
- (icccm_wm_state_t)asWMState
{
	icccm_wm_state_t hints;
	[self checkAtomType: ICCCMWMState];
	[[self data] getBytes: &hints
	               length: sizeof(icccm_wm_state_t)];
	return hints;
}
@end

// void ICCCMCalculateWindowFrame(XCBPoint *refPoint, ICCCMWindowGravity gravity, int16_t client_border_width, XCBRect notificationFrame, int notificationValueMask, const uint32_t border_widths[4], XCBRect *decorationWindowRect, XCBRect *childWindowRect, XCBRect* clientFrame)
// {
// 	int valueMask = notificationValueMask;
// 	// The position child frame if it was not reparented (i.e. with the same internal 
// 	// width and height, but the x and y translated to root window coordinates, and
// 	// adjusted for the client-specified border width, not the decoration window one)
// 	XCBPoint rfp; XCBSize rfs;
// 
// 	// The request frame rect (could contain incomplete values; it depends
// 	// on the valueMask (some values may be invalid)
// 	XCBRect reqFrame = notificationFrame;
// 
// 	// 1. Copy in the original coordinates. These are calculated
// 	// from the decoration window and the child window
// 	if (valueMask & XCB_CONFIG_WINDOW_X)
// 		rfp.x = reqFrame.origin.x;
// 	else
// 		rfp.x = decorationWindowRect->origin.x + border_widths[ICCCMBorderWest];
// 	if (valueMask & XCB_CONFIG_WINDOW_Y)
// 		rfp.y = reqFrame.origin.y;
// 	else
// 		rfp.y = decorationWindowRect->origin.y + border_widths[ICCCMBorderNorth];
// 	if (valueMask & XCB_CONFIG_WINDOW_WIDTH)
// 		rfs.width = reqFrame.size.width;
// 	else
// 		rfs.width = childWindowRect->size.width;
// 	if (valueMask & XCB_CONFIG_WINDOW_HEIGHT)
// 		rfs.height = reqFrame.size.height;
// 	else
// 		rfs.height = childWindowRect->size.height;
// 
// 	// 2. If a reposition was requested, we need to calculate
// 	// the new reference point
// 	if (valueMask & (XCB_CONFIG_WINDOW_X | XCB_CONFIG_WINDOW_Y))
// 	{
// 		*refPoint = ICCCMCalculateRefPointForClientFrame(gravity, 
// 			XCBMakeRect(rfp.x, rfp.y, rfs.width, rfs.height),
// 			border_widths);
// 	}
// 
// 	// 3. Use the reference point and gravity to calculate the new reference frame based on the
// 	// requested width and height. This is really just a reverse of the
// 	// process performed above to get back to the reference frame, but
// 	// it is needed when a new width/height pair is given without a
// 	// change in the reference point (see EWMH Window Geometry clarifications
// 	// for more details). 
// 	
// 	// When a new size (but not ref point) is given,
// 	// this process moves the (x,y) of the reference frame in the
// 	// opposite direction of the gravity.
// 	switch (gravity)
// 	{
// 	case ICCCMNorthWestGravity:
// 	case ICCCMStaticGravity:
// 		break;
// 	case ICCCMNorthGravity:
// 		rfp.x = refPoint->x - (rfs.width / 2);
// 		break;
// 	case ICCCMNorthEastGravity:
// 		rfp.x = refPoint->x -  rfs.width - border_widths[ICCCMBorderEast];
// 		break;
// 	case ICCCMWestGravity:
// 		rfp.y = refPoint->y - (rfs.height / 2);
// 		break;
// 	case ICCCMCenterGravity:
// 		rfp.x = refPoint->x - rfs.width / 2;
// 		rfp.y = refPoint->y - rfs.height / 2;
// 		break;
// 	case ICCCMEastGravity:
// 		rfp.x = refPoint->x - rfs.width - border_widths[ICCCMBorderEast];
// 		rfp.y = refPoint->y - rfs.height / 2;
// 		break;
// 	case ICCCMSouthWestGravity:
// 		rfp.y = refPoint->y - rfs.height - border_widths[ICCCMBorderSouth];
// 		break;
// 	case ICCCMSouthGravity:
// 		rfp.x = refPoint->x - rfs.width / 2;
// 		rfp.y = refPoint->y - rfs.height - border_widths[ICCCMBorderSouth];
// 		break;
// 	case ICCCMSouthEastGravity:
// 		rfp.x = refPoint->x - rfs.width - border_widths[ICCCMBorderEast];
// 		rfp.y = refPoint->y - rfs.height - border_widths[ICCCMBorderSouth];
// 		break;
// 	default:
// 		break;
// 	}
// 	
// 	// Now that we have the new reference frame, calculate the new decoration
// 	// and child rect
// 	*childWindowRect = XCBMakeRect(border_widths[ICCCMBorderWest], border_widths[ICCCMBorderNorth],
// 		rfs.width, rfs.height);
// 	*decorationWindowRect = XCBMakeRect(
// 			rfp.x - border_widths[ICCCMBorderWest], 
// 			rfp.y - border_widths[ICCCMBorderNorth],
// 			rfs.width + border_widths[ICCCMBorderWest] + border_widths[ICCCMBorderEast],
// 			rfs.height + border_widths[ICCCMBorderNorth] + border_widths[ICCCMBorderSouth]);
// 	newReferenceFrame->origin = rfp;
// 	newReferenceFrame->size = rfs;
// }
XCBRect ICCCMDecorationFrameWithReferencePoint(ICCCMWindowGravity gravity, XCBPoint rp, XCBSize cs, const uint32_t bws[4])
{
	int16_t w = cs.width + bws[ICCCMBorderWest] + bws[ICCCMBorderEast];
	int16_t h = cs.height + bws[ICCCMBorderNorth] + bws[ICCCMBorderSouth];
	switch (gravity)
	{
	case ICCCMNorthWestGravity:
		return XCBMakeRect(rp.x, rp.y, w, h);
	case ICCCMNorthGravity:
		return XCBMakeRect(rp.x - w / 2, rp.y, w, h);
	case ICCCMNorthEastGravity:
		return XCBMakeRect(rp.x - w, rp.y, w, h);
	case ICCCMWestGravity:
		return XCBMakeRect(rp.x, rp.y - h / 2, w, h);
	case ICCCMCenterGravity:
		return XCBMakeRect(rp.x - w/2, rp.y - h/2, w, h);
	case ICCCMEastGravity:
		return XCBMakeRect(rp.x - w, rp.y - h/2, w, h);
	case ICCCMSouthWestGravity:
		return XCBMakeRect(rp.x, rp.y - h, w, h);
	case ICCCMSouthGravity:
		return XCBMakeRect(rp.x - w/2, rp.y - h, w, h);
	case ICCCMSouthEastGravity:
		return XCBMakeRect(rp.x - w, rp.y - h, w, h);
	default:
		NSLog(@"ICCCMCalculateWindowFrame called with unknown gravity %d; using Static gravity instead",
				gravity);
	case ICCCMStaticGravity:
		return XCBMakeRect(rp.x - bws[ICCCMBorderWest], rp.y - bws[ICCCMBorderNorth], w, h);
	}
}
XCBPoint ICCCMCalculateRefPointForClientFrame(ICCCMWindowGravity gravity, XCBRect initialRect, uint32_t bw)
{
	XCBPoint refPoint;
	XCBPoint rfp = initialRect.origin;
	XCBSize rfs = initialRect.size;
	switch (gravity)
	{
	case ICCCMNorthWestGravity:
		refPoint.x = rfp.x - bw;
		refPoint.y = rfp.y - bw;
		break;
	case ICCCMNorthGravity:
		refPoint.x = rfp.x + rfs.width / 2;
		refPoint.y = rfp.y;
		break;
	case ICCCMNorthEastGravity:
		refPoint.x = rfp.x + rfs.width + bw;
		refPoint.y = rfp.y - bw;
		break;
	case ICCCMWestGravity:
		refPoint.x = rfp.x - bw;
		refPoint.y = rfp.y + rfs.height / 2;
		break;
	case ICCCMCenterGravity:
		refPoint.x = rfp.x + rfs.width / 2;
		refPoint.y = rfp.y + rfs.height / 2;
		break;
	case ICCCMEastGravity:
		refPoint.x = rfp.x + rfs.width + bw;
		refPoint.y = rfp.y + rfs.height / 2;
		break;
	case ICCCMSouthWestGravity:
		refPoint.x = rfp.x + bw;
		refPoint.y = rfp.y + rfs.height + bw;
		break;
	case ICCCMSouthGravity:
		refPoint.x = rfp.x + rfs.width / 2; 
		refPoint.y = rfp.y + rfs.height + bw;
		break;
	case ICCCMSouthEastGravity:
		refPoint.x = rfp.x + rfs.width + bw;
		refPoint.y = rfp.y + rfs.height + bw;
		break;
	default:
		NSLog(@"ICCCMCalculateWindowFrame called with unknown gravity %d; using Static gravity instead",
				gravity);
	case ICCCMStaticGravity:
		refPoint.x = rfp.x;
		refPoint.y = rfp.y;
		break;
	}
	return refPoint;
}
