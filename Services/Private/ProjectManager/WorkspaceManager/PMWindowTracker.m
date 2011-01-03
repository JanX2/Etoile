/**
 * Étoilé ProjectManager - WorkspaceManager - PMWindowTracker.m
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
#import "PMWindowTracker.h"

#import <XCBKit/ICCCM.h>
#import <XCBKit/XCBComposite.h>
#import <XCBKit/XCBPixmap.h>
#import <XCBKit/XCBRender.h>
#import <XCBKit/XCBImage.h>
#import <XCBKit/XCBVisual.h>
#import <XCBKit/XCBDamage.h>
#import <XWindowServerKit/XWindowImageRep.h>
#import <XWindowServerKit/XFunctions.h>

NSString* PMProjectWindowProperty = @"__ETOILE_PROJECT_ID";
NSString* PMViewWindowProperty = @"__ETOILE_VIEW_ID";

const static uint16_t MAX_WIDTH = 128, MAX_HEIGHT = 128;

static double ScaleFactorForMaxSize(XCBSize currentSize, uint16_t maxWidth, uint16_t maxHeight)
{
	double widthFactor = (double)currentSize.width / (double)maxWidth;
	double heightFactor = (double)currentSize.height / (double)maxHeight;
	return MAX(widthFactor, heightFactor);
}


@interface PMWindowTracker (Private)
- (void)checkViewAvailable;
- (void)windowAvailable: (NSNotification*)notification;
- (void)windowDidResize: (NSNotification*)notification;
- (XCBWindow*)findChildWindow: (XCBWindow*)topWindow;
- (void)recreatePixmap;
@end

@implementation PMWindowTracker
- (id)initByTrackingWindow: (XCBWindow*)aWindow
{
	SELFINIT;
	window = [[self findChildWindow: aWindow] retain];
	if (nil == window)
	{
		[self release];
		return nil;
	}
	topLevelWindow = [aWindow retain];
	waitingOnProperties = [[NSMutableSet setWithCapacity: 2] retain];
	NSDebugLLog(@"PMWindowTracker", @"Created tracker for top level window %@ (child %@)", topLevelWindow, window);
	[waitingOnProperties addObjectsFromArray: A(PMProjectWindowProperty, PMViewWindowProperty, ICCCMWMState, ICCCMWMName)];

	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	if (![window isEqual: topLevelWindow])
		[window setEventMask: XCB_EVENT_MASK_PROPERTY_CHANGE | XCB_EVENT_MASK_STRUCTURE_NOTIFY];
	damageTracker = [[XCBDamage damageWithDrawable: topLevelWindow
	                                  reportLevel: XCB_DAMAGE_REPORT_LEVEL_NON_EMPTY] retain];

	[defaultCenter
		addObserver: self
		   selector: @selector(windowAvailable:)
		       name: XCBWindowBecomeAvailableNotification
		     object: window];
	[defaultCenter
		addObserver: self
		   selector: @selector(propertyDidRefresh:)
		       name: XCBWindowPropertyDidRefreshNotification
		     object: window];
	[defaultCenter
		addObserver: self
		   selector: @selector(propertyDidChange:)
		       name: XCBWindowPropertyDidChangeNotification
		     object: window];
	[defaultCenter
		addObserver: self
		   selector: @selector(windowDidMap:)
		       name: XCBWindowDidMapNotification
		     object: topLevelWindow];
	[defaultCenter
		addObserver: self
		   selector: @selector(windowDidUnmap:)
		       name: XCBWindowDidUnMapNotification
		     object: topLevelWindow];
	[defaultCenter
		addObserver: self
		   selector: @selector(windowDidDestroy:)
		       name: XCBWindowDidDestroyNotification
		     object: window];
	[defaultCenter
		addObserver: self
		   selector: @selector(windowDidResize:)
		       name: XCBWindowFrameWillChangeNotification
		     object: topLevelWindow];
	[defaultCenter
		addObserver: self
		   selector: @selector(propertyDidUpdate:)
		       name: XCBWindowPropertyDidChangeNotification
		     object: window];
	[defaultCenter 
		addObserver: self
		   selector: @selector(windowDamaged:)
		       name: XCBWindowDamageNotifyNotification
		     object: topLevelWindow];
	scalingPixmap = [[XCBPixmap 
		pixmapWithDepth: 32
		       drawable: topLevelWindow
		          width: MAX_WIDTH
		         height: MAX_HEIGHT] retain];
	scalingPicture = [[XCBRenderPicture
		pictureWithDrawable: scalingPixmap
		             format: [XCBRender findStandardVisualFormat: XCB_PICT_STANDARD_ARGB_32]
		          valueMask: 0
		          valueList: 0] retain];
	
	[window refreshCachedProperties: [waitingOnProperties allObjects]];
	return self;
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[window release];
	[topLevelWindow release];
	[waitingOnProperties release];
	[viewName release];
	[projectName release];
	[damageTracker release];

	[scalingPicture release];
	[scalingPixmap release];

	[super dealloc];
}
- (XCBWindow*)findChildWindow: (XCBWindow*)topWindow
{
	XCBCachedProperty *stateProperty = [topWindow retrieveAndCacheProperty: ICCCMWMState];
	XCBCachedProperty *nameProperty = [topWindow retrieveAndCacheProperty: ICCCMWMName];
	if (![stateProperty isEmpty] && ![nameProperty isEmpty])
		return topWindow;

	NSArray *childWindows = [topWindow queryTree];
	FOREACH(childWindows, childWindow, XCBWindow*)
	{
		XCBWindow *testWindow = [self findChildWindow: childWindow];
		if (testWindow != nil)
			return testWindow;
	}
	return nil;
}

- (void)propertyDidChange: (NSNotification*)notification
{
	NSString *propertyName = [[notification userInfo] objectForKey: @"PropertyName"];
	[window refreshCachedProperty: propertyName];
}

- (void)propertyDidRefresh: (NSNotification*)notification
{
	NSString *propName; 
	XCBCachedProperty *propValue;
	propName = [[notification userInfo] valueForKey: @"PropertyName"];
	[waitingOnProperties removeObject: propName];
	propValue = [[notification userInfo] valueForKey: @"PropertyValue"];
	if (NO == [propValue isEmpty])
	{
		if ([propName isEqual: PMViewWindowProperty])
			viewName = [[propValue asString] retain];
		if ([propName isEqual: PMProjectWindowProperty])
			projectName = [[propValue asString] retain];
	}
	[self checkViewAvailable];
}

- (void)propertyDidUpdate: (NSNotification*)notification
{
	[window refreshCachedProperty: [[notification userInfo] valueForKey: @"PropertyName"]];
}

- (void)checkViewAvailable
{
	if ([window windowLoadState] != XCBWindowAvailableState ||
		[waitingOnProperties count] != 0)
		return;

	// Determine the new window state.
	ICCCMWindowState new_window_state;
	
	XCBCachedProperty *wmStateProp = [window cachedProperty: ICCCMWMState];
	if (![wmStateProp isEmpty])
	{
		icccm_wm_state_t wmState = [wmStateProp asWMState];
		new_window_state = wmState.state;
	}
	else
	{
		new_window_state = ICCCMWithdrawnWindowState;
	}

	if (!activated)
	{
		window_state = new_window_state;
		if (new_window_state != ICCCMWithdrawnWindowState)
		{
			NSDebugLLog(@"PMTrackedWindow", @"Tracked window activated (%@)", window);
			activated = YES;
			[delegate trackedWindowActivated: self];
		}
		else
		{
			// Send a deactivated notification so that the
			// delegate knows this tracker is invalid.
			[delegate trackedWindowDeactivated: self];
			return;
		}
	}
	else
	{
		// Only send state notifications when the window has
		// already been activated
		if (new_window_state != window_state)
		{
			window_state = new_window_state;
			switch (window_state)
			{
			case ICCCMNormalWindowState:
				NSDebugLLog(@"PMWindowTracker", @"Tracked window shown (%@)", window);
				[delegate trackedWindowDidShow: self];
				break;
			case ICCCMIconicWindowState:
				NSDebugLLog(@"PMWindowTracker", @"Tracked window iconic (%@)", window);
				[delegate trackedWindowDidHide: self];
				break;
			case ICCCMWithdrawnWindowState:
			default:
				activated = NO;
				NSDebugLLog(@"PMWindowTracker", @"Tracked window deactivated (%@)", window);
				[delegate trackedWindowDeactivated: self];
				break;
			}
		}
	}
}

- (void)windowAvailable: (NSNotification*)notification
{
	mapped = ([window mapState] == XCB_MAP_STATE_VIEWABLE);
	[self checkViewAvailable];
	[self recreatePixmap];
}

- (void)windowDamaged: (NSNotification*)notification
{
	//NSDebugLLog(@"PMWindowTracker", @"DamageNotify on %@, recreating pixmap", topLevelWindow);
	[self recreatePixmap];
	[damageTracker subtractWithRepair: nil parts: nil];
}

- (void)setDelegate: (id)aDelegate
{
	self->delegate = aDelegate;
}

- (void)windowDidMap: (NSNotification*)notification
{
	NSDebugLLog(@"PMWindowTracker", @"Top level window %@ mapped - recreating pixmap", topLevelWindow);
	mapped = YES;
	ASSIGN(windowPixmap, nil);
	[self recreatePixmap];
}

- (void)windowDidUnmap: (NSNotification*)notification
{
	if (activated == NO)
		return;
	NSDebugLLog(@"PMWindowTracker", @"Top level window %@ unmapped", topLevelWindow);
	if (mapped)
	{
		// Initial Unmap event - don't assume hiding
		// because we will get the
		// property state change for that.
		mapped = NO;
	}
	else
	{
		// This is a second UnMap event in a row. Assume window withdrawn.
		activated = NO;
		NSDebugLLog(@"PMWindowTracker", @"Tracked window deactivated (%@)", window);
		[delegate trackedWindowDeactivated: self];
	}
}

- (void)windowDidResize: (NSNotification*)notification
{
	NSDictionary* userInfo = [notification userInfo];
	if ([[userInfo objectForKey: @"SendEvent"] boolValue])
		return;
	XCBRect oldRect = [topLevelWindow frame];
	XCBRect frameRect;
	[(NSValue*)[userInfo objectForKey: @"Rect"] getValue:&frameRect];
	if (oldRect.size.width == frameRect.size.width && 
		oldRect.size.height == frameRect.size.height)
		return;

	NSDebugLLog(@"PMWindowTracker", @"Top level window (%@) resized, recreating pixmap", topLevelWindow);
	ASSIGN(windowPixmap, nil);
	[self recreatePixmap];
}

- (void)recreatePixmap
{
	if ([topLevelWindow mapState] != XCB_MAP_STATE_VIEWABLE)
		return;
	// NSDebugLLog(@"PMWindowTracker", @"Window %@ is visible so creating pixmap", topLevelWindow);
	XCBSize xcbWindowSize = [topLevelWindow frame].size;
	//NSSize windowSize = NSMakeSize(xcbWindowSize.width, xcbWindowSize.height);
	double scale = 1.0 / ScaleFactorForMaxSize(xcbWindowSize, MAX_WIDTH, MAX_HEIGHT);
	XCBSize imageSize = XCBMakeSize(MAX_WIDTH, MAX_HEIGHT);

	if (windowPixmap == nil)
		windowPixmap = [[XCBComposite nameWindowPixmap: topLevelWindow] retain];
	
	uint32_t pa = 1; // IncludeInferiors
	XCBRenderPicture *sourcePicture = [XCBRenderPicture
		pictureWithDrawable: windowPixmap
		             format: [XCBRender findVisualFormat: [topLevelWindow visual]]
		          valueMask: XCB_RENDER_CP_SUBWINDOW_MODE
		          valueList: &pa];
	xcb_render_transform_t transform = {
		XCB_RENDER_D2F(1), XCB_RENDER_D2F(0), XCB_RENDER_D2F(0),
		XCB_RENDER_D2F(0), XCB_RENDER_D2F(1), XCB_RENDER_D2F(0), 
		XCB_RENDER_D2F(0), XCB_RENDER_D2F(0), XCB_RENDER_D2F(scale)
		};
	[sourcePicture setTransform: transform];
	[sourcePicture setFilter: @"good" values: 0 valuesLength: 0];
	[sourcePicture compositeWithOperation: XCB_RENDER_PICT_OP_SRC
	                                 mask: nil
	                          destination: scalingPicture
	                            fromPoint: XCBMakePoint(0, 0)
	                            maskPoint: XCBMakePoint(0, 0)
	                             intoRect: XCBMakeRect(0, 0, imageSize.width, imageSize.height)];
	XCBImage *image = [XCBImage 
		getImageWithDrawable: scalingPixmap
		              inRect: XCBMakeRect(0, 0, imageSize.width, imageSize.height)
		              format: XCB_IMAGE_FORMAT_Z_PIXMAP
		              planes: UINT32_MAX];
	NSData *data = [image data];
	
	NSBitmapImageRep *newImageRep;
	newImageRep = [[NSBitmapImageRep alloc]
		initWithBitmapDataPlanes: NULL
		              pixelsWide: imageSize.width
		              pixelsHigh: imageSize.height
		           bitsPerSample: 8
		         samplesPerPixel: 4
		                hasAlpha: YES
		                isPlanar: NO
		          colorSpaceName: NSDeviceRGBColorSpace
		             bytesPerRow: 0 
		            bitsPerPixel: 32];

	// Store the data in the correct format
	// uint8_t *dd = [newImageRep bitmapData];
	// const uint8_t *sd = [data bytes];
	// // Assuming the server is little-endian
	// uint32_t bpr = [newImageRep bytesPerRow];
	// NSDebugLLog(@"PMWindowTracker", @"New image has depth of %d and visual %@", [image depth], [image visual]);
	// for (int i = 0; i < imageSize.height; i++)
	// {
	// 	for (int j = 0; j < imageSize.width; j++)
	// 	{
	// 		dd[i * bpr + j * 4 + 0] = sd[(i * imageSize.width * 4) + j * 4 + 0];
	// 		dd[i * bpr + j * 4 + 1] = sd[(i * imageSize.width * 4) + j * 4 + 1];
	// 		dd[i * bpr + j * 4 + 2] = sd[(i * imageSize.width * 4) + j * 4 + 2];
	// 		dd[i * bpr + j * 4 + 3] = sd[(i * imageSize.width * 4) + j * 4 + 3];
	// 		//dd[i * bpr + j * 4 + 3] = 0xFF; 
	// 	}
	// }

	// Copy the bitmap data. Because we created the destination pixmap
	// in RGBA format, it should be possible to just copy it over. 
	// Endian-difference in the server and client could cause problems
	// here.
	[data getBytes: [newImageRep bitmapData] length: [data length]];
	
	ASSIGN(imageRep, [newImageRep autorelease]);

	[delegate trackedWindowPixmapUpdated: self];
}

- (void)windowDidDestroy: (NSNotification*)notification
{
	[delegate trackedWindowDeactivated: self];
}

- (BOOL)isTrackingWindow: (XCBWindow*)aWindow
{
	return [aWindow isEqual: window];
}

- (NSString*)projectName
{
	return projectName;
}

- (NSString*)viewName
{
	return viewName;
}

- (XCBWindow*)topLevelWindow
{
	return topLevelWindow;
}
- (XCBWindow*)window
{
	return window;
}
- (NSImage*)windowPixmap
{
	if (imageRep == nil)
		return nil;
	NSImage* image = [[NSImage alloc]
		initWithSize: [imageRep size]];
	[image addRepresentation: imageRep];
	return [image autorelease];
}
- (NSString*)windowName
{
	XCBCachedProperty *prop = [window cachedProperty: ICCCMWMName];
	if (![prop isEmpty])
	{
		return [prop asString];
	}
	else
	{
		return @"<unknown>";
	}
}
- (BOOL)activated
{
	return activated;
}
- (ICCCMWindowState)windowState
{
	return window_state;
}
@end
