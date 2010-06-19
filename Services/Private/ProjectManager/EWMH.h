/*
 * Étoilé ProjectManager - EWMH.h
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
#import "XCBWindow.h"
#import "XCBCachedProperty.h"

@class NSString;

// Root window properties (some are also messages too)
extern NSString* EWMH_Supported;
extern NSString* EWMH_ClientList;
extern NSString* EWMH_ClientListStacking;
extern NSString* EWMH_NumberOfDesktops;
extern NSString* EWMH_DesktopGeometry;
extern NSString* EWMH_DesktopViewport;
extern NSString* EWMH_CurrentDesktop;
extern NSString* EWMH_DesktopNames;
extern NSString* EWMH_ActiveWindow;
extern NSString* EWMH_Workarea;
extern NSString* EWMH_SupportingWMCheck;
extern NSString* EWMH_VirtualRoots;
extern NSString* EWMH_DesktopLayout;
extern NSString* EWMH_ShowingDesktop;

// Constants used with _NET_DESKTOP_LAYOUT (EWMHDesktopLayout)
enum 
{
	EWMH_WMOrientationHorz = 0,
	EWMH_WMOrientationVert = 1
};
enum 
{
	EWMH_WMTopLeft = 0,
	EWMH_WMTopRight = 1,
	EWMH_WMBottomRight = 2,
	EWMH_WMBottomLeft = 3
};

// Root Window Messages
extern NSString* EWMH_CloseWindow;
extern NSString* EWMH_MoveresizeWindow;
extern NSString* EWMH_WMMoveresize;
extern NSString* EWMH_RestackWindow;
extern NSString* EWMH_RequestFrameExtents;

// Constants used with EWMH_WMMoveresize;
enum
{
	EWMH_WMMoveresizeSizeTopLeft = 0,
	EWMH_WMMoveresizeSizeTop = 1,
	EWMH_WMMoveresizeSizeTopRight = 2,
	EWMH_WMMoveresizeSizeRight = 3,
	EWMH_WMMoveresizeSizeBottomRight = 4,
	EWMH_WMMoveresizeSizeBottom = 5,
	EWMH_WMMoveresizeSizeBottomLeft = 6,
	EWMH_WMMoveresizeSizeLeft = 7,
	EWMH_WMMoveresizeMove = 8,
	EWMH_WMMoveresizeSizeKeyboard = 9,
	EWMH_WMMoveresizeMoveKeyboard = 10,
	EWMH_WMMoveresizeCancel = 11
};

// Application window properties
extern NSString* EWMH_WMName;
extern NSString* EWMH_WMVisibleName;
extern NSString* EWMH_WMIconName;
extern NSString* EWMH_WMVisibleIconName;
extern NSString* EWMH_WMDesktop;
extern NSString* EWMH_WMWindowType;
extern NSString* EWMH_WMState;
extern NSString* EWMH_WMAllowedActions;
extern NSString* EWMH_WMStrut;
extern NSString* EWMH_WMStrutPartial;
extern NSString* EWMH_WMIconGeometry;
extern NSString* EWMH_WMIcon;
extern NSString* EWMH_WMPid;
extern NSString* EWMH_WMHandledIcons;
extern NSString* EWMH_WMUserTime;
extern NSString* EWMH_WMUserTimeWindow;
extern NSString* EWMH_WMFrameExtents;

// The window types (used with EWMH_WMWindowType)
extern NSString* EWMH_WMWindowTypeDesktop;
extern NSString* EWMH_WMWindowTypeDock;
extern NSString* EWMH_WMWindowTypeToolbar;
extern NSString* EWMH_WMWindowTypeMenu;
extern NSString* EWMH_WMWindowTypeUtility;
extern NSString* EWMH_WMWindowTypeSplash;
extern NSString* EWMH_WMWindowTypeDialog;
extern NSString* EWMH_WMWindowTypeDropdownMenu;
extern NSString* EWMH_WMWindowTypePopupMenu;

extern NSString* EWMH_WMWindowTypeTooltip;
extern NSString* EWMH_WMWindowTypeNotification;
extern NSString* EWMH_WMWindowTypeCombo;
extern NSString* EWMH_WMWindowTypeDnd;

extern NSString* EWMH_WMWindowTypeNormal;

// The application window states (used with EWMH_WMWindowState)
extern NSString* EWMH_WMStateModal;
extern NSString* EWMH_WMStateSticky;
extern NSString* EWMH_WMStateMaximizedVert;
extern NSString* EWMH_WMStateMaximizedHorz;
extern NSString* EWMH_WMStateShaded;
extern NSString* EWMH_WMStateSkipTaskbar;
extern NSString* EWMH_WMStateSkipPager;
extern NSString* EWMH_WMStateHidden;
extern NSString* EWMH_WMStateFullscreen;
extern NSString* EWMH_WMStateAbove;
extern NSString* EWMH_WMStateBelow;
extern NSString* EWMH_WMStateDemandsAttention;

// The application window allowed actions (used with EWMH_WMAllowedActions)
extern NSString* EWMH_WMActionMove;
extern NSString* EWMH_WMActionResize;
extern NSString* EWMH_WMActionMinimize;
extern NSString* EWMH_WMActionShade;
extern NSString* EWMH_WMActionStick;
extern NSString* EWMH_WMActionMaximizeHorz;
extern NSString* EWMH_WMActionMaximizeVert;
extern NSString* EWMH_WMActionFullscreen;
extern NSString* EWMH_WMActionChangeDesktop;
extern NSString* EWMH_WMActionClose;
extern NSString* EWMH_WMActionAbove;
extern NSString* EWMH_WMActionBelow;

// Window Manager Protocols
extern NSString* EWMH_WMPing;
extern NSString* EWMH_WMSyncRequest;
extern NSString* EWMH_WMFullscreenMonitors;

// Other properties
extern NSString* EWMH_WMFullPlacement;

// Compositing Managers

// Functions
NSArray* EWMHAtomsList();
