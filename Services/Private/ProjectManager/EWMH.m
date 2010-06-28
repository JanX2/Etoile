/*
 * Étoilé ProjectManager - EWMH.m
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
#import "EWMH.h"
#import "XCBAtomCache.h"

// Root window properties (some are also messages too)
NSString* EWMH_Supported = @"_NET_SUPPORTED";
NSString* EWMH_ClientList = @"_NET_CLIENT_LIST";
NSString* EWMH_ClientListStacking = @"_NET_CLIENT_LIST_STACKING";
NSString* EWMH_NumberOfDesktops = @"_NET_NUMBER_OF_DESKTOPS";
NSString* EWMH_DesktopGeometry = @"_NET_DESKTOP_GEOMETRY";
NSString* EWMH_DesktopViewport = @"_NET_DESKTOP_VIEWPORT";
NSString* EWMH_CurrentDesktop = @"_NET_CURRENT_DESKTOP";
NSString* EWMH_DesktopNames = @"_NET_DESKTOP_NAMES";
NSString* EWMH_ActiveWindow = @"_NET_ACTIVE_WINDOW";
NSString* EWMH_Workarea = @"_NET_WORKAREA";
NSString* EWMH_SupportingWMCheck = @"_NET_SUPPORTING_WM_CHECK";
NSString* EWMH_VirtualRoots = @"_NET_VIRTUAL_ROOTS";
NSString* EWMH_DesktopLayout = @"_NET_DESKTOP_LAYOUT";
NSString* EWMH_ShowingDesktop = @"_NET_SHOWING_DESKTOP";

// Root Window Messages
NSString* EWMH_CloseWindow = @"_NET_CLOSE_WINDOW";
NSString* EWMH_MoveresizeWindow = @"_NET_MOVERESIZE_WINDOW";
NSString* EWMH_WMMoveresize = @"_NET_WM_MOVERESIZE";
NSString* EWMH_RestackWindow = @"_NET_RESTACK_WINDOW";
NSString* EWMH_RequestFrameExtents = @"_NET_REQUEST_FRAME_EXTENTS";

// Application window properties
NSString* EWMH_WMName = @"_NET_WM_NAME";
NSString* EWMH_WMVisibleName = @"_NET_WM_VISIBLE_NAME";
NSString* EWMH_WMIconName = @"_NET_WM_ICON_NAME";
NSString* EWMH_WMVisibleIconName = @"_NET_WM_VISIBLE_ICON_NAME";
NSString* EWMH_WMDesktop = @"_NET_WM_DESKTOP";
NSString* EWMH_WMWindowType = @"_NET_WM_WINDOW_TYPE";
NSString* EWMH_WMState = @"_NET_WM_STATE";
NSString* EWMH_WMAllowedActions = @"_NET_WM_ALLOWED_ACTIONS";
NSString* EWMH_WMStrut = @"_NET_WM_STRUT";
NSString* EWMH_WMStrutPartial = @"_NET_WM_STRUT_PARTIAL";
NSString* EWMH_WMIconGeometry = @"_NET_WM_ICON_GEOMETRY";
NSString* EWMH_WMIcon = @"_NET_WM_ICON";
NSString* EWMH_WMPid = @"_NET_WM_PID";
NSString* EWMH_WMHandledIcons = @"_NET_WM_HANDLED_ICONS";
NSString* EWMH_WMUserTime = @"_NET_WM_USER_TIME";
NSString* EWMH_WMUserTimeWindow = @"_NET_WM_USER_TIME_WINDOW";
NSString* EWMH_WMFrameExtents = @"_NET_FRAME_EXTENTS";

// The window types (used with EWMH_WMWindowType)
NSString* EWMH_WMWindowTypeDesktop = @"_NET_WM_WINDOW_TYPE_DESKTOP";
NSString* EWMH_WMWindowTypeDock = @"_NET_WM_WINDOW_TYPE_DOCK";
NSString* EWMH_WMWindowTypeToolbar = @"_NET_WM_WINDOW_TYPE_TOOLBAR";
NSString* EWMH_WMWindowTypeMenu = @"_NET_WM_WINDOW_TYPE_MENU";
NSString* EWMH_WMWindowTypeUtility = @"_NET_WM_WINDOW_TYPE_UTILITY";
NSString* EWMH_WMWindowTypeSplash = @"_NET_WM_WINDOW_TYPE_SPLASH";
NSString* EWMH_WMWindowTypeDialog = @"_NET_WM_WINDOW_TYPE_DIALOG";
NSString* EWMH_WMWindowTypeDropdownMenu = @"_NET_WM_WINDOW_TYPE_DROPDOWN_MENU";
NSString* EWMH_WMWindowTypePopupMenu = @"_NET_WM_WINDOW_TYPE_POPUP_MENU";

NSString* EWMH_WMWindowTypeTooltip = @"_NET_WM_WINDOW_TYPE_TOOLTIP";
NSString* EWMH_WMWindowTypeNotification = @"_NET_WM_WINDOW_TYPE_NOTIFICATION";
NSString* EWMH_WMWindowTypeCombo = @"_NET_WM_WINDOW_TYPE_COMBO";
NSString* EWMH_WMWindowTypeDnd = @"_NET_WM_WINDOW_TYPE_DND";

NSString* EWMH_WMWindowTypeNormal = @"_NET_WM_WINDOW_TYPE_NORMAL";

// The application window states (used with EWMH_WMWindowState)
NSString* EWMH_WMStateModal = @"_NET_WM_STATE_MODAL";
NSString* EWMH_WMStateSticky = @"_NET_WM_STATE_STICKY";
NSString* EWMH_WMStateMaximizedVert = @"_NET_WM_STATE_MAXIMIZED_VERT";
NSString* EWMH_WMStateMaximizedHorz = @"_NET_WM_STATE_MAXIMIZED_HORZ";
NSString* EWMH_WMStateShaded = @"_NET_WM_STATE_SHADED";
NSString* EWMH_WMStateSkipTaskbar = @"_NET_WM_STATE_SKIP_TASKBAR";
NSString* EWMH_WMStateSkipPager = @"_NET_WM_STATE_SKIP_PAGER";
NSString* EWMH_WMStateHidden = @"_NET_WM_STATE_HIDDEN";
NSString* EWMH_WMStateFullscreen = @"_NET_WM_STATE_FULLSCREEN";
NSString* EWMH_WMStateAbove = @"_NET_WM_STATE_ABOVE";
NSString* EWMH_WMStateBelow = @"_NET_WM_STATE_BELOW";
NSString* EWMH_WMStateDemandsAttention = @"_NET_WM_STATE_DEMANDS_ATTENTION";

// The application window allowed actions (used with EWMH_WMAllowedActions)
NSString* EWMH_WMActionMove = @"_NET_WM_ACTION_MOVE";
NSString* EWMH_WMActionResize = @"_NET_WM_ACTION_RESIZE";
NSString* EWMH_WMActionMinimize = @"_NET_WM_ACTION_MINIMIZE";
NSString* EWMH_WMActionShade = @"_NET_WM_ACTION_SHADE";
NSString* EWMH_WMActionStick = @"_NET_WM_ACTION_STICK";
NSString* EWMH_WMActionMaximizeHorz = @"_NET_WM_ACTION_MAXIMIZE_HORZ";
NSString* EWMH_WMActionMaximizeVert = @"_NET_WM_ACTION_MAXIMIZE_VERT";
NSString* EWMH_WMActionFullscreen = @"_NET_WM_ACTION_FULLSCREEN";
NSString* EWMH_WMActionChangeDesktop = @"_NET_WM_ACTION_CHANGE_DESKTOP";
NSString* EWMH_WMActionClose = @"_NET_WM_ACTION_CLOSE";
NSString* EWMH_WMActionAbove = @"_NET_WM_ACTION_ABOVE";
NSString* EWMH_WMActionBelow = @"_NET_WM_ACTION_BELOW";

// Window Manager Protocols
NSString* EWMH_WMPing = @"_NET_WM_PING";
NSString* EWMH_WMSyncRequest = @"_NET_WM_SYNC_REQUEST";
NSString* EWMH_WMFullscreenMonitors = @"_NET_WM_FULLSCREEN_MONITORS";

// Other properties
NSString* EWMH_WMFullPlacement = @"_NET_WM_FULL_PLACEMENT";

// Compositing Managers

NSArray* EWMHAtomsList() 
{
	NSString* atoms[] = {
		EWMH_Supported,
		EWMH_ClientList,
		EWMH_ClientListStacking,
		EWMH_NumberOfDesktops,
		EWMH_DesktopGeometry,
		EWMH_DesktopViewport,
		EWMH_CurrentDesktop,
		EWMH_DesktopNames,
		EWMH_ActiveWindow,
		EWMH_Workarea,
		EWMH_SupportingWMCheck,
		EWMH_VirtualRoots,
		EWMH_DesktopLayout,
		EWMH_ShowingDesktop,
		EWMH_CloseWindow,
		EWMH_MoveresizeWindow,
		EWMH_WMMoveresize,
		EWMH_RestackWindow,
		EWMH_RequestFrameExtents,
		EWMH_WMName,
		EWMH_WMVisibleName,
		EWMH_WMIconName,
		EWMH_WMVisibleIconName,
		EWMH_WMDesktop,
		EWMH_WMWindowType,
		EWMH_WMState,
		EWMH_WMAllowedActions,
		EWMH_WMStrut,
		EWMH_WMStrutPartial,
		EWMH_WMIconGeometry,
		EWMH_WMIcon,
		EWMH_WMPid,
		EWMH_WMHandledIcons,
		EWMH_WMUserTime,
		EWMH_WMUserTimeWindow,
		EWMH_WMFrameExtents,
		EWMH_WMWindowTypeDesktop,
		EWMH_WMWindowTypeDock,
		EWMH_WMWindowTypeToolbar,
		EWMH_WMWindowTypeMenu,
		EWMH_WMWindowTypeUtility,
		EWMH_WMWindowTypeSplash,
		EWMH_WMWindowTypeDialog,
		EWMH_WMWindowTypeDropdownMenu,
		EWMH_WMWindowTypePopupMenu,
		EWMH_WMWindowTypeTooltip,
		EWMH_WMWindowTypeNotification,
		EWMH_WMWindowTypeCombo,
		EWMH_WMWindowTypeDnd,
		EWMH_WMWindowTypeNormal,
		EWMH_WMStateModal,
		EWMH_WMStateSticky,
		EWMH_WMStateMaximizedVert,
		EWMH_WMStateMaximizedHorz,
		EWMH_WMStateShaded,
		EWMH_WMStateSkipTaskbar,
		EWMH_WMStateSkipPager,
		EWMH_WMStateHidden,
		EWMH_WMStateFullscreen,
		EWMH_WMStateAbove,
		EWMH_WMStateBelow,
		EWMH_WMStateDemandsAttention,
		EWMH_WMActionMove,
		EWMH_WMActionResize,
		EWMH_WMActionMinimize,
		EWMH_WMActionShade,
		EWMH_WMActionStick,
		EWMH_WMActionMaximizeHorz,
		EWMH_WMActionMaximizeVert,
		EWMH_WMActionFullscreen,
		EWMH_WMActionChangeDesktop,
		EWMH_WMActionClose,
		EWMH_WMActionAbove,
		EWMH_WMActionBelow,
		EWMH_WMPing,
		EWMH_WMSyncRequest,
		EWMH_WMFullscreenMonitors,
		EWMH_WMFullPlacement
	};
	return [NSArray arrayWithObjects: atoms
	                           count: sizeof(atoms) / sizeof(NSString*)];
}

void EWMHSetSupported(XCBWindow *rootWindow, XCBWindow* checkWindow, NSArray* supportedAtoms)
{
	xcb_window_t checkWindowId = [checkWindow xcbWindowId];
	[checkWindow changeProperty: EWMH_SupportingWMCheck
	                       type: @"WINDOW"
	                     format: 32
	                       mode: XCB_PROP_MODE_REPLACE
	                       data: &checkWindowId
	                      count: 1];
	[rootWindow changeProperty: EWMH_SupportingWMCheck
	                      type: @"WINDOW"
	                    format: 32
	                      mode: XCB_PROP_MODE_REPLACE
	                      data: &checkWindowId
	                     count: 1];

	xcb_atom_t *atomList = calloc([supportedAtoms count], sizeof(xcb_atom_t));
	XCBAtomCache *atomCache = [XCBAtomCache sharedInstance];
	for (int i = 0; i < [supportedAtoms count]; i++)
	{
		atomList[i] = [atomCache atomNamed: [supportedAtoms objectAtIndex: i]];
	}
	[rootWindow changeProperty: EWMH_Supported
	                      type: @"ATOM"
	                    format: 32
	                      mode: XCB_PROP_MODE_REPLACE
	                      data: atomList
	                     count: [supportedAtoms count]];
	free(atomList);
}
