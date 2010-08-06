/**
 * Étoilé ProjectManager - PMScreen.m
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
#import "PMScreen.h"
#import "EWMH.h"
#import "XCBScreen.h"
#import "XCBConnection.h"
#import "XCBRender.h"
#import "XCBFixes.h"
#import "XCBWindow.h"
#import "XCBPixmap.h"
#import "XCBAtomCache.h"
#import "XCBSelection.h"
#import "XCBDamage.h"
#import "XCBShape.h"

#import <EtoileFoundation/EtoileFoundation.h>

@interface PMScreen (Private)
- (XCBRenderPicture*)generateRootTile;
- (void)paintAllWithRegion: (XCBFixesRegion*)fixRegion;
- (PMCompositeWindow*)findCompositeWindow: (XCBWindow*)window;
- (void)childWindowBecomeAvailable: (NSNotification*)notification;
- (void)childWindowWillUnMap: (NSNotification*)notification;
- (void)childWindowDidUnMap: (NSNotification*)notification;
- (void)childWindowDamaged: (NSNotification*)notification;
@end

@implementation PMScreen
- (id)initWithScreen: (XCBScreen*)scr
                  id: (uint32_t)aId
{
	SELFINIT;
	screen = [scr retain];
	screen_id = aId;
	compositeMap = [NSMutableDictionary new];
	clipChanged = YES;
	rootTile = [[self generateRootTile] retain];

	XCBRenderPictureFormat *visualFormat =
		[XCBRender findVisualFormat: [screen defaultVisual]];
	if (nil == visualFormat)
		visualFormat = [XCBRender findStandardVisualFormat: XCB_PICT_STANDARD_RGB_24];
	uint32_t includeInferiors = 1;
	rootPicture =
		[[XCBRenderPicture alloc]
			initWithDrawable: [screen rootWindow]
			   pictureFormat: visualFormat
			       valueMask: XCB_RENDER_CP_SUBWINDOW_MODE
			       valueList: &includeInferiors]
		;
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		   selector: @selector(rootWindowFrameChanged:)
		       name: XCBWindowFrameDidChangeNotification
		     object: [screen rootWindow]];
	return self;
}
- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[manager_window destroy];
	[manager_window release];
	[rootBuffer release];
	[rootPicture release];
	[allDamage release];
	[rootTile release];
	[super dealloc];
}
- (XCBScreen*)screen { return screen; }
- (uint32_t)screenId { return screen_id; }
- (XCBRenderPicture*)rootBuffer { return rootBuffer; }
- (XCBRenderPicture*)rootPicture { return rootPicture; }
- (XCBWindow*)rootWindow { return [screen rootWindow]; }
/**
  * Setup the screen for compositing window management
  */
- (BOOL)manageScreen
{
	XCBWindow *rootWindow = [screen rootWindow];
	xcb_atom_t screen_atom = [[XCBAtomCache sharedInstance]
		atomNamed: [NSString stringWithFormat: @"WM_S%d", screen_id]];
	XCBWindow *window = [rootWindow createChildInRect: XCBMakeRect(0, 0, 1, 1) borderWidth: 0];
	if (!XCBAcquireManagerSelection([self screen], manager_window, screen_atom, NO))
	{
		NSLog(@"There is a window manager already running on screen #%d", screen_id);
		[window destroy];
		return NO;
	}
	ASSIGN(self->manager_window, window);

	[screen setTrackingChildren: YES];
	uint32_t events[2];
	// Must be in this order because of the order of the
	// XCB_CW_* flags
	events[0] = 1;
	events[1] =
		XCB_EVENT_MASK_FOCUS_CHANGE |
		XCB_EVENT_MASK_EXPOSURE | XCB_EVENT_MASK_BUTTON_PRESS |
		XCB_EVENT_MASK_KEY_PRESS | XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY |
		XCB_EVENT_MASK_STRUCTURE_NOTIFY |
		XCB_EVENT_MASK_SUBSTRUCTURE_REDIRECT;
	[rootWindow changeWindowAttributes: XCB_CW_EVENT_MASK | XCB_CW_OVERRIDE_REDIRECT
				    values: events];

	[[NSNotificationCenter defaultCenter]
		addObserver: self
		   selector: @selector(windowDidExpose:)
		       name: XCBWindowExposeNotification
		     object: [screen rootWindow]];

	EWMHSetSupported([screen rootWindow], manager_window,
		[NSArray arrayWithObjects: EWMH_WMWindowType,
			EWMH_WMWindowTypeDock,
			EWMH_WMWindowTypeDesktop,
			EWMH_WMWindowTypeMenu,
			EWMH_WMWindowTypeToolbar,
			EWMH_WMWindowTypeNormal,
			EWMH_WMWindowTypeUtility,
			EWMH_WMWindowTypeDialog,
			EWMH_WMWindowTypeDropdownMenu,
			EWMH_WMWindowTypePopupMenu,
			nil]);
	return YES;
}
- (PMCompositeWindow*)findCompositeWindow: (XCBWindow*)window
{
	return [compositeMap objectForKey: window];
}

- (void)childWindowDiscovered: (XCBWindow*)child
              compositeWindow: (PMCompositeWindow*)compositeWindow
{
	if (compositeWindow != nil)
	{
		[compositeMap setObject: compositeWindow
		                 forKey: child];
		[compositeWindow setDelegate: self];
		if ([child windowLoadState] == XCBWindowAvailableState)
		{
			NSNotification *fakeNotification =
				[NSNotification notificationWithName: XCBWindowBecomeAvailableNotification
							      object: child];
			[self childWindowBecomeAvailable: fakeNotification];
		}
		else
		{
			[[NSNotificationCenter defaultCenter]
				addObserver: self
				   selector: @selector(childWindowBecomeAvailable:)
				       name: XCBWindowBecomeAvailableNotification
				     object: child];
		}
	}
}
- (void)childWindowRemoved: (XCBWindow*)xcbWindow
{
	PMCompositeWindow *window = [self findCompositeWindow: xcbWindow];
	NSNotification *notification = [NSNotification
		notificationWithName: XCBWindowWillUnMapNotification
		              object: xcbWindow];

	[self childWindowWillUnMap: notification];
	[self childWindowDidUnMap: notification];

	XCBREM_OBSERVER(WindowDidDestroy, xcbWindow);
	XCBREM_OBSERVER(WindowFrameWillChange, xcbWindow);
	XCBREM_OBSERVER(WindowFrameDidChange, xcbWindow);
	XCBREM_OBSERVER(WindowDidUnMap, xcbWindow);
	XCBREM_OBSERVER(WindowDamageNotify, xcbWindow);
	if (window)
		[compositeMap removeObjectForKey: window];
}

- (void)childWindowBecomeAvailable: (NSNotification*)notification
{
	XCBWindow *child = [notification object];
	PMCompositeWindow *compositeWindow =
		[self findCompositeWindow: child];

	if ([compositeWindow extents] != nil)
		[self appendDamage: [compositeWindow extents]];
	clipChanged = YES;

	[[NSNotificationCenter defaultCenter]
		removeObserver: self
		          name: XCBWindowBecomeAvailableNotification
		        object: child];
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		   selector: @selector(childWindowDidDestroy:)
		       name: XCBWindowDidDestroyNotification
		     object: child];
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		   selector: @selector(childWindowWillUnMap:)
		       name: XCBWindowWillUnMapNotification
		     object: child];
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		   selector: @selector(childWindowDidUnMap:)
		       name: XCBWindowDidUnMapNotification
		     object: child];
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		   selector: @selector(childWindowDamaged:)
		       name: XCBWindowDamageNotifyNotification
		     object: child];
}
- (void)childWindowWillUnMap: (NSNotification*)notification
{
	PMCompositeWindow *window = [self findCompositeWindow: [notification object]];
	XCBFixesRegion *region = [window extents];
	if (region)
		[self appendDamage: region];
}
- (void)childWindowDidUnMap: (NSNotification*)notification
{
	clipChanged = YES;
}

- (void)childWindowDidDestroy: (NSNotification*)notification
{
	XCBWindow *xcbWindow = [notification object];
	[self childWindowRemoved: xcbWindow];
}

- (void)childWindowDamaged: (NSNotification*)notification
{
	XCBWindow *damagedWindow = [notification object];
	PMCompositeWindow *compositeWindow = [self findCompositeWindow: damagedWindow];
	if (compositeWindow != nil)
	{
		// FIXME: Find out why we don't deal with the area that was damaged
		// I'm thinking the XServer knows automatically, but I cannot understand
		// the spec (carmstrong)
		XCBFixesRegion *partsRegion = [compositeWindow windowDamaged];
		[self appendDamage: partsRegion];
	}
	else
		NSLog(@"-[PMConnectionDelegate damageNotify:] ERROR compositewindow for XCBWindow %@ not found.", damagedWindow);
}

- (void)setRootBuffer: (XCBRenderPicture*)picture
{
	ASSIGN(rootBuffer, picture);
}

- (void)setRootPicture: (XCBRenderPicture*)picture
{
	ASSIGN(rootPicture, picture);
}

- (void)compositeWindow: (PMCompositeWindow*)compositeWindow
         extentsChanged: (XCBFixesRegion*)extents
             oldExtents: (XCBFixesRegion*)oldExtents
{
	if (oldExtents)
		[self appendDamage: oldExtents];
	if (extents)
		[self appendDamage: extents];
	clipChanged = YES;
}

- (void)windowDidExpose: (NSNotification*)notification
{
	NSLog(@"-[XCBScreen windowDidExpose:]");
	// FIXME: Apparently we can optimize by accumulating the
	// the rects according to the anEvent->count parameter (see XLib manual)
	XCBRect exposeRect;
	xcb_rectangle_t exposeRectangle;
	[[[notification userInfo] objectForKey: @"Rect"]
		getValue: &exposeRect];
	exposeRectangle = XCBRectangleFromRect(exposeRect);

	XCBFixesRegion *exposeRegion = [XCBFixesRegion
		regionWithRectangles: &exposeRectangle
		               count: 1];
	[self appendDamage: exposeRegion];
}
- (void)appendDamage: (XCBFixesRegion*)damage
{
	if (nil == allDamage)
	{
		allDamage = [[XCBFixesRegion regionWithRectangles: 0 count: 0] retain];
	}
	[allDamage unionWithRegion: damage
	           intoDestination: allDamage];
	[XCBConn setNeedsFlush: YES];
}

- (void)rootWindowFrameChanged: (NSNotification*)notification
{
	XCBWindow *rootWindow = [notification object];
	NSLog(@"-[PMScreen rootWindowChanged:]");
	if (rootBuffer)
	{
		[rootBuffer release];
		rootBuffer = nil;
	}
	xcb_rectangle_t damage = XCBRectangleFromRect([rootWindow frame]);
	[self appendDamage: [XCBFixesRegion
		regionWithRectangles: &damage
		               count: 1]];
}
- (void)paintAll
{
	[self paintAllWithRegion: nil];
}
- (void)paintAllDamaged
{
	if (allDamage != nil)
	{
		[self paintAllWithRegion: allDamage];
		[XCBConn setNeedsFlush: YES];
		[allDamage release];
		allDamage = nil;
		clipChanged = NO;
	}
}
- (void)paintAllWithRegion: (XCBFixesRegion*)fixRegion
{
	XCBWindow *rootWindow = [screen rootWindow];
	uint32_t root_width = [rootWindow frame].size.width;
	uint32_t root_height = [rootWindow frame].size.height;
	// Clip region. Reduced each time in the window paint loop
	XCBFixesRegion *region;
	if (nil == fixRegion)
	{
		xcb_rectangle_t r;
		r.x = r.y = 0;
		r.width = root_width;
		r.height = root_height;
		region = [XCBFixesRegion regionWithRectangles: &r count: 1];
	}
	else
	{
		region = [XCBFixesRegion regionWithRectangles: 0 count: 0];
		[fixRegion copyIntoRegion: region];
	}
	if (nil == rootBuffer)
	{
		XCBPixmap *pixmap = [[XCBPixmap alloc]
			initWithDepth: [screen defaultDepth]
			     drawable: rootWindow
			        width: root_width
			       height: root_height];
		[self setRootBuffer: [XCBRenderPicture
			pictureWithDrawable: pixmap
			             format: [XCBRender findVisualFormat:[screen defaultVisual]]
			          valueMask: 0
			          valueList: 0]];
		[pixmap release];
	}
	[region clipPicture: rootPicture
	            atPoint: XCBMakePoint(0, 0)];

	// Use a reverse enumerator. Why?
	// Because when I was porting the code over from xcompmgr,
	// I didn't realise the algorithm it was using was top to bottom,
	// when we store our child windows in bottom to top order.
	NSEnumerator *window_enum = [[screen childWindows] reverseObjectEnumerator];
	for (XCBWindow *window = [window_enum nextObject];
		window != nil;
		window = [window_enum nextObject])
	{
		PMCompositeWindow *compositeWindow = [self findCompositeWindow: window];
		[compositeWindow
			paintIntoBuffer: rootBuffer
			     withRegion: region
			    clipChanged: clipChanged];
	}

	[region clipPicture: rootBuffer
	            atPoint: XCBMakePoint(0, 0)];
	[rootTile compositeWithOperation: XCB_RENDER_PICT_OP_SRC
	                            mask: nil
	                     destination: rootBuffer
		               fromPoint: XCBMakePoint(0, 0)
	                       maskPoint: XCBMakePoint(0,0)
	                        intoRect: XCBMakeRect(0, 0, root_width, root_height)];

	window_enum = [[screen childWindows] objectEnumerator];
	for (XCBWindow *window = [window_enum nextObject];
			nil != window;
			window = [window_enum nextObject])
	{
		PMCompositeWindow *compositeWindow = [self findCompositeWindow: window];
		[compositeWindow
			paintWithAlphaIntoBuffer: rootBuffer
			              withRegion: region
			             clipChanged: clipChanged];
	}

	[[XCBFixesRegion nilRegion]
		clipPicture: rootBuffer
		    atPoint: XCBMakePoint(0, 0)];
	[rootBuffer compositeWithOperation: XCB_RENDER_PICT_OP_SRC
	                              mask: nil
	                       destination: rootPicture
	                         fromPoint: XCBMakePoint(0, 0)
	                         maskPoint: XCBMakePoint(0, 0)
	                          intoRect: XCBMakeRect(0, 0, root_width, root_height)];
}
- (XCBRenderPicture*)generateRootTile
{
	// FIXME: This method should use the backgroup pixmap atom
	// set as per EWMH conventions, and updated when the atom
	// is updated. At the moment its just purple.
	XCBRenderPicture *picture;
	XCBPixmap *pixmap;
	uint32_t repeat = 1; // Repeat the tile

	pixmap = [[XCBPixmap alloc]
		initWithDepth: [screen defaultDepth]
		     drawable: [screen rootWindow]
		        width: 1
		       height: 1];
	picture = [XCBRenderPicture
		pictureWithDrawable: pixmap
		             format: [XCBRender findVisualFormat:[screen defaultVisual]]
		          valueMask: XCB_RENDER_CP_REPEAT
		          valueList: &repeat];

	xcb_rectangle_t rect = { 0, 0, 1, 1};
	[picture fillRectangles: &rect
	                  count: 1
	                  color: XCBRenderMakeColor(0x8000, 0x2000, 0x8000, 0xffff)
	              operation: XCB_RENDER_PICT_OP_SRC];

	[pixmap release];
	return picture;
}
- (NSString*)description
{
	return [NSString stringWithFormat:@"PMScreen (screen=%@)", screen];
}
@end
