#import "PMNormalWindowDecorator.h"
#import "PMManagedWindow.h"

#import <XCBKit/XCBShape.h>
#import <XCBKit/EWMH.h>
#import <XCBKit/XCBAtomCache.h>

/**
  * The width of the border used to house the
  * resize handles. This should be at least 1px
  * greater than the resize handle width to allow
  * some space between the outer child border and
  * the resize handles
  */
static const ICCCMBorderExtents BORDER_WIDTHS = { 8, 8, 8, 8};

static const uint32_t RH_WIDTH = 4;
static const uint32_t MIN_RH_LENGTH = 20;
static const float RH_QUOTIENT = 0.15;

static const uint16_t CHILD_BORDER_WIDTH = 1;
@interface PMNormalWindowDecorator (Private)

- (void)updateShapeWithManagedWindow: (PMManagedWindow*)managedWindow
                     decorationFrame: (XCBRect)decorationFrame
                          childFrame: (XCBRect)childFrame;
- (void)updateShapeWithManagedWindow: (PMManagedWindow*)managedWindow;
@end

@implementation PMNormalWindowDecorator
static PMNormalWindowDecorator *SharedInstance = nil;
+ (void)initialize
{
	if (SharedInstance == nil)
	{
		SharedInstance = [PMNormalWindowDecorator new];
	}
}
+ (PMNormalWindowDecorator*)sharedInstance
{
	return SharedInstance;
}
- (ICCCMBorderExtents)extentsForDecorationWindow: (PMManagedWindow*)managedWindow
{
	return BORDER_WIDTHS;
}

- (uint16_t)childBorderWidth: (PMManagedWindow*)managedWindow
{
	return CHILD_BORDER_WIDTH;
}

- (BOOL)shouldDecorateManagedWindow: (PMManagedWindow*)managedWindow
{
	BOOL decorate = YES;
	XCBAtomCache *atomCache = [XCBAtomCache sharedInstance];
	XCBCachedProperty *ewmhWindowType = [[managedWindow childWindow] cachedProperty: EWMH_WMWindowType];
	if (![ewmhWindowType isEmpty])
	{
		// FIXME: This is an atom list, not a single atom
		NSArray *atomArray = [ewmhWindowType asAtomArray];
		NSDebugLLog(@"PMManagedWindow", @"%@ window type = %@", managedWindow, atomArray);

		if ([ewmhWindowType hasAtomInAtomArray: EWMH_WMWindowTypeNormal] ||
			[ewmhWindowType hasAtomInAtomArray: EWMH_WMWindowTypeDialog])
			decorate = YES;
		else
			decorate = NO;
	}
	else
	{
		XCBCachedProperty *wmTransientFor = [[managedWindow childWindow] cachedProperty: ICCCMWMTransientFor];
		if (![wmTransientFor isEmpty])
		{
			// FIXME: Should check if transient for root window
			decorate = NO;
		}
	}
	return decorate;
}

- (void)managedWindowRepositioned: (PMManagedWindow*)managedWindow
                  decorationFrame: (XCBRect)decorationFrame
                       childFrame: (XCBRect)childFrame
{
	[self updateShapeWithManagedWindow: managedWindow
	                   decorationFrame: decorationFrame
	                        childFrame: childFrame];
}
- (XCBSize)minimumSizeForClientFrame: (PMManagedWindow*)managedWindow
{
	uint32_t extent = MIN_RH_LENGTH * 2 + RH_WIDTH * 2 + 2;
	return XCBMakeSize(extent, extent);
}
- (void)managedWindow: (PMManagedWindow*)managedWindow focusIn: (NSNotification*)aNot
{
	NSDebugLLog(@"PMNormalWindowDecorator", @"%@: bringing to top and releasing inactive grabs", self);
	// FIXME: This needs to be routed through managedWindow so that we
	// can later handle window levels
	XCBWindow *w = [managedWindow outermostWindow];
	[w restackAboveWindow: nil];
	// [managedWindow releaseInactiveGrabs];
	[self updateShapeWithManagedWindow: managedWindow];
}
- (void)managedWindow: (PMManagedWindow*)managedWindow focusOut: (NSNotification*)aNot
{
	NSDebugLLog(@"PMNormalWindowDecorator", @"%@: establishing inactive grabs on focus out", self);
	//[managedWindow establishInactiveGrabs];
	[self updateShapeWithManagedWindow: managedWindow];
}
- (void)updateShapeWithManagedWindow: (PMManagedWindow*)managedWindow
{
	[self updateShapeWithManagedWindow: managedWindow
	                   decorationFrame: [[managedWindow decorationWindow] frame]
	                        childFrame: [[managedWindow childWindow] frame]];
}
- (void)updateShapeWithManagedWindow: (PMManagedWindow*)managedWindow
                     decorationFrame: (XCBRect)decorationFrame
                          childFrame: (XCBRect)childFrame
{
	XCBWindow *decorationWindow = [managedWindow decorationWindow];
	XCBWindow *childWindow = [managedWindow childWindow];
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
		if ([managedWindow hasFocus])
		{
			xcb_rectangle_t rects[10] = {
				{ 0, 0, rhw + rhl, rhw }, // NW H
				{ ds.width - rhw - rhl, 0, rhw + rhl, rhw }, // NE H
				{ 0, rhw, rhw, rhl }, // NW V
				{ ds.width - rhw, rhw, rhw, rhl }, // NE V
				{ cp.x - cbw, cp.y - cbw, cs.width + cbw * 2, cs.height + cbw * 2}, 
				{ 0, ds.height - rhw - rhl, rhw, rhl }, // SW V
				{ ds.width - rhw, ds.height - rhl - rhw, rhw, rhl }, // SE V
				{ 0, ds.height - rhw, rhw + rhl, rhw }, // SW H
				{ ds.width - rhl - rhw, ds.height - rhw, rhl + rhw, rhw } // SE H
			};
			[decorationWindow 
				setShapeRectangles: rects
				             count: 9
				          ordering: XCB_SHAPE_YXSORTED
				         operation: XCB_SHAPE_SO_SET
				              kind: XCB_SHAPE_SK_BOUNDING
				            offset: XCBMakePoint(0, 0)];
			[decorationWindow 
				shapeCombineWithKind: XCB_SHAPE_SK_BOUNDING
				           operation: XCB_SHAPE_SO_UNION
				              offset: XCBMakePoint(BORDER_WIDTHS.left, BORDER_WIDTHS.top)
				              source: childWindow
				          sourceKind: XCB_SHAPE_SK_BOUNDING];
		}
		else
		{
			//xcb_rectangle_t rects[1] = {
			// 	{ cp.x - cbw, cp.y - cbw, cs.width + cbw *2, cs.height + cbw * 2 };
			[decorationWindow 
				shapeCombineWithKind: XCB_SHAPE_SK_BOUNDING
				           operation: XCB_SHAPE_SO_SET
				              offset: XCBMakePoint(BORDER_WIDTHS.left, BORDER_WIDTHS.top)
				              source: childWindow
				          sourceKind: XCB_SHAPE_SK_BOUNDING];
		}
	}
}
-   (int)managedWindow: (PMManagedWindow*)managedWindow
moveresizeTypeForPoint: (XCBPoint)point;
{

	XCBRect df = [[managedWindow decorationWindow] frame];
	XCBRect cf = [[managedWindow childWindow] frame];
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
- (void)managedWindow: (PMManagedWindow*)managedWindow changedState: (ICCCMWindowState) state
{
	switch (state)
	{
		case ICCCMNormalWindowState:
			// [managedWindow establishInactiveGrabs];
			break;
		default:
			break;
	}
}
@end
