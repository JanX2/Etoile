/**
 * Étoilé ProjectManager - ICCCM.h
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
#import "XCBWindow.h"
#import "XCBCachedProperty.h"
#import <xcb/xcb_icccm.h>

@class NSString;

// Properties set by a Client on a Client Window
extern NSString* ICCCMWMName;
extern NSString* ICCCMWMIconName;
extern NSString* ICCCMWMNormalHints;
extern NSString* ICCCMWMSizeHints;
extern NSString* ICCCMWMHints;
extern NSString* ICCCMWMClass;
extern NSString* ICCCMWMTransientFor;
extern NSString* ICCCMWMProtocols;
extern NSString* ICCCMWMColormapWindows;
extern NSString* ICCCMWMClientMachine;

// Properties set by a Window Manager on a Client Window
extern NSString* ICCCMWMState;
extern NSString* ICCCMWMIconSize;

// ICCCM WM_PROTOCOLS
extern NSString* ICCCMWMTakeFocus;
extern NSString* ICCCMWMSaveYourself;
extern NSString* ICCCMWMDeleteWindow;

typedef enum _ICCCMWindowState
{
	ICCCMWithdrawnWindowState = 0,
	ICCCMNormalWindowState = 1,
	ICCCMIconicWindowState = 3
} ICCCMWindowState;

typedef enum _ICCCMGravity
{
	ICCCMNorthWestGravity = 1,
	ICCCMNorthGravity = 2,
	ICCCMNorthEastGravity = 3,
	ICCCMWestGravity = 4,
	ICCCMCenterGravity = 5,
	ICCCMEastGravity = 6,
	ICCCMSouthWestGravity = 7,
	ICCCMSouthGravity = 8,
	ICCCMSouthEastGravity = 9,
	ICCCMStaticGravity = 10
} ICCCMWindowGravity;

enum _ICCCMWMSizeHintsFlags
{
	ICCCMUSPosition = 1,
	ICCCMUSSize = 2,
	ICCCMPPosition = 4,
	ICCCMPSize = 8,
	ICCCMPMinSize = 16,
	ICCCMPMaxSize = 32,
	ICCCMPResizeInc = 64,
	ICCCMPAspect = 128,
	ICCCMPBaseSize = 256,
	ICCCMPWinGravity = 512
};

NSArray *ICCCMAtomsList(void);

@interface XCBWindow (ICCCM)
// - (void)setWMName: (NSString*)newWMName;
// - (void)setWMIconName: (NSString*)newWMIconName;
// - (void)setWMClientMachine: (NSString*)newWMClientMachine;
// - (void)setWMProtocols: (const xcb_atom_t*)newProtocols count: (uint32_t)len;
@end

@interface XCBCachedProperty (ICCCM)
- (xcb_size_hints_t)asWMSizeHints;
- (xcb_wm_hints_t)asWMHints;
@end

enum _BorderWidthDirection {
	ICCCMBorderNorth = 0,
	ICCCMBorderEast = 1,
	ICCCMBorderSouth = 2,
	ICCCMBorderWest = 3
};
XCBPoint ICCCMCalculateReferencePoint(ICCCMWindowGravity, XCBRect initialRect, const uint32_t border_widths[4]);
void ICCCMCalculateWindowFrame(XCBPoint *refPoint, ICCCMWindowGravity gravity, NSDictionary* values, const uint32_t border_widths[4], XCBRect *decorationWindowRect, XCBRect *childWindowRect, XCBRect* newReferenceFrame);
