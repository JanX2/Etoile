/**
 * Étoilé ProjectManager - PMCompositeWindow.m
 *
 * Copyright (C) 2009 David Chisnall
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
#import "PMCompositeWindow.h"

#import <EtoileFoundation/EtoileFoundation.h>
#import <Foundation/NSNotification.h>

#import "XCBWindow.h"
#import "XCBFixes.h"
#import "XCBRender.h"
#import "XCBDamage.h"
#import "XCBComposite.h"
#import "XCBPixmap.h"
#import "XCBShape.h"

const uint32_t OPAQUE = UINT32_MAX;
@interface PMCompositeWindow (Private)
@end

#define REGISTER_OBSERVER(x) \
	[[NSNotificationCenter defaultCenter] \
		addObserver: self \
		   selector: @selector(xcbWindow##x :) \
		       name: XCBWindow##x##Notification \
		     object: window]
@implementation PMCompositeWindow
+ (PMCompositeWindow*)windowWithXCBWindow: (XCBWindow*)xcbWindow
{
	return [[[self alloc] initWithXCBWindow: xcbWindow] 
		autorelease];
}
- (id)initWithXCBWindow: (XCBWindow*)win
{
	SELFINIT;
	self->window = [win retain];

	NSNotificationCenter * c =[NSNotificationCenter defaultCenter]; 
	REGISTER_OBSERVER(BecomeAvailable);
	REGISTER_OBSERVER(FrameDidChange);
	REGISTER_OBSERVER(FrameWillChange);
	REGISTER_OBSERVER(DidMap);
	REGISTER_OBSERVER(DidUnMap);
	REGISTER_OBSERVER(ShapeNotify);
	                         
	if ([window windowLoadState] == XCBWindowAvailableState)
	{
		[self xcbWindowFrameDidChange: nil];
		[self xcbWindowBecomeAvailable: nil];
	}
	self->opacity = OPAQUE;
	[win setShapeSelectInput: YES];
	return self;
}
- (void)dealloc
{
	[damage release];
	[picture release];
	[pixmap release];
	[clipRegion release];
	[borderClip release];
	[borderSize release];
	[extents release];
	[window release];
	[alphaPicture release];
	[[NSNotificationCenter defaultCenter] 
		removeObserver: self];
	[super dealloc];
}

- (void)setDelegate: (id)del
{
	self->delegate = del;
}

- (XCBWindow*)window 
{ 
	return window; 
}

- (void)determineMode
{
	if (alphaPicture)
		DESTROY(alphaPicture);
	
	XCBRenderPictureFormat *format;
	if ([window windowClass] == XCB_WINDOW_CLASS_INPUT_ONLY)
		format = nil;
	else
		format = [XCBRender findVisualFormat: [window visual]];
	if ((format && [format type] == XCB_RENDER_PICT_TYPE_DIRECT &&
			[format direct].alpha_mask != 0) ||
		opacity != OPAQUE)
		mode = PMCompositeWindowARGB;
	else
		mode = PMCompositeWindowSolid;
}

- (void)xcbWindowDidMap: (NSNotification*)notification
{
	damaged = NO;
}

- (void)xcbWindowDidUnMap: (NSNotification*)notification
{
	damaged = NO;
	[extents release];
	extents = nil;
	[pixmap release];
	pixmap = nil;
	[picture release];
	picture = nil;
	[borderSize release];
	borderSize = nil;
	[borderClip release];
	borderClip = nil;
}

- (void)xcbWindowFrameWillChange: (NSNotification*)notification
{
}

- (void)xcbWindowFrameDidChange: (NSNotification*)notification
{
	XCBFixesRegion *old_extents = [extents retain];

	// FIXME: need more information about what changed so that we don't
	// unnecessarily reallocate pixmaps
	if (pixmap)
	{
		[pixmap release];
		pixmap = nil;
		if (picture)
		{
			[picture release];
			picture = nil;
		}
	}
	
	[extents release];
	extents = [[self calculateExtents] retain];

	// Notify that we have damaged due to new extents
	if ([delegate respondsToSelector: @selector(compositeWindow:extentsChanged:oldExtents:)])
		[delegate compositeWindow: self
		           extentsChanged: extents
		               oldExtents: old_extents];
	
	[old_extents release];
}

- (void)xcbWindowBecomeAvailable: (NSNotification*)notification
{
	if ([window windowClass] != XCB_WINDOW_CLASS_INPUT_ONLY)
	{
		ASSIGN(damage, [XCBDamage 
			damageWithDrawable: window 
			       reportLevel: XCB_DAMAGE_REPORT_LEVEL_NON_EMPTY]);
	}

	[self determineMode];

	// We need to simulate this notification because
	// we may not get a ConfigureNotify event before the
	// window attributes becomes available (generally
	// because of newly created windows with a CreateNotify
	// event that notifies the frame values but does
	// not post a WindowFrameDidChange notification).
	[self xcbWindowFrameDidChange: nil];
}

- (void)xcbWindowShapeNotify: (NSNotification*)notification
{
	NSDebugLLog(@"PMCompositeWindow", @"Shape notify event for %@", self);
	// Damage ourselves by imitating ConfigureNotify
	[self xcbWindowFrameDidChange: nil];
}

- (void)paintIntoBuffer: (XCBRenderPicture*)buffer 
             withRegion: (XCBFixesRegion*)region
            clipChanged: (BOOL)clipChanged
{
	if (!damaged)
		return;
	XCBRect frame = [window frame];
	int16_t border_width = [window borderWidth];
	if (frame.origin.x + frame.size.width < 1 ||
		frame.origin.y + frame.size.height < 1 ||
		frame.origin.x > [[window parent] frame].size.width ||
		frame.origin.y > [[window parent] frame].size.height)
		return;
	if (nil == picture)
	{
		uint32_t pa = 1;
		XCBRenderPictureFormat *format;
		if (nil == pixmap)
			[pixmap release];
		pixmap = [[XCBComposite nameWindowPixmap: window] retain];
		format = [XCBRender findVisualFormat: [window visual]];
		picture = [[XCBRenderPicture 
			pictureWithDrawable: pixmap
				     format: format
				  valueMask: XCB_RENDER_CP_SUBWINDOW_MODE
				  valueList: &pa] retain];
	}
	if (clipChanged)
	{
		if (borderSize)
		{
			[borderSize release];
			borderSize = nil;
		}
#if 0
		if (extents)
		{
			[extents release];
			extents = nil;
		}
#endif
		if (borderClip)
		{
			[borderClip release];
			borderClip = nil;
		}
	}
	if (nil == borderSize) 
	{
		borderSize = [[XCBFixesRegion 
				regionWithWindow: window 
				           shape: XCB_SHAPE_SK_BOUNDING] retain];
		[borderSize translateWithDX: frame.origin.x + border_width
		                         dY: frame.origin.y + border_width];
	}
	if (nil == extents) 
	{
		extents = [[self calculateExtents] retain];
	}
	/** Assuming SOLID window mode */
	if (PMCompositeWindowSolid == mode)
	{
		XCBRect destRect = XCBMakeRect(
			frame.origin.x,
			frame.origin.y,
			frame.size.width + border_width * 2,
			frame.size.height + border_width * 2);
		[region clipPicture:buffer atPoint:XCBMakePoint(0, 0)];
		// Remove the bit that is shown of our window from the 
		// clip region. Do it after we clip the buffer so
		// that we can still paint our unobscured portion.
		[region subtractRegion: borderSize 
		       intoDestination: region];
		[picture 
			compositeWithOperation: XCB_RENDER_PICT_OP_SRC
					  mask: nil
				   destination: buffer
				     fromPoint: XCBMakePoint(0, 0)
				     maskPoint: XCBMakePoint(0, 0)
				      intoRect: destRect
			];
	}
	if (nil == borderClip)
	{
		borderClip = [[XCBFixesRegion regionWithRectangles: 0 count: 0] retain];
		[region copyIntoRegion: borderClip];
	}
}

- (void)paintWithAlphaIntoBuffer: (XCBRenderPicture*)buffer 
                      withRegion: (XCBFixesRegion*)region
                     clipChanged: (BOOL)clipChanged
{
	if (nil != picture)
	{
		if (OPAQUE != opacity &&
			nil == alphaPicture)
		{
			XCBRenderPictureFormat *format =
				[XCBRender findStandardVisualFormat: XCB_PICT_STANDARD_A_8];
			XCBPixmap *alphapixmap = 
				[XCBPixmap pixmapWithDepth: 8
				                  drawable: window
				                     width: 1
				                    height: 1];
			uint32_t repeat = 1;
			alphaPicture =
				[[XCBRenderPicture 
					pictureWithDrawable: alphapixmap
					             format: format
					          valueMask: XCB_RENDER_CP_REPEAT
					          valueList: &repeat] retain];
			xcb_rectangle_t rect = XCBRectangleFromRect(XCBMakeRect(0, 0, 1, 1));
			xcb_render_color_t col;
			uint16_t a = ((double)opacity / OPAQUE) * 0xFFFF;
			col = XCBRenderMakeColor(0, 0, 0, a);
			[alphaPicture 
				fillRectangles: &rect
				         count: 1
				         color: col
				     operation: XCB_RENDER_PICT_OP_SRC];
		}
		[borderClip intersectRegion: borderSize 
		            intoDestination: borderClip];
		[borderClip clipPicture: buffer atPoint: XCBMakePoint(0, 0)];

		if (PMCompositeWindowARGB == mode)
		{
			XCBRect rect = [window frame];
			rect.size.width += [window borderWidth] * 2;
			rect.size.height += [window borderWidth] * 2;
			[picture 
				compositeWithOperation: XCB_RENDER_PICT_OP_OVER
					          mask: alphaPicture
					   destination: buffer
					     fromPoint: XCBMakePoint(0, 0)
					     maskPoint: XCBMakePoint(0, 0)
					      intoRect: rect];
		}
	}
	if (nil != borderClip)
	{
		ASSIGN(borderClip, nil);
	}
}

- (XCBFixesRegion*)extents
{
	return extents;
}

- (XCBFixesRegion*)calculateExtents
{
	XCBRect frame = [window frame];
	int16_t border_width = [window borderWidth];
	xcb_rectangle_t rect;
	rect.x = frame.origin.x;
	rect.y = frame.origin.y;
	rect.width = frame.size.width + border_width * 2;
	rect.height = frame.size.height + border_width * 2;
	return [XCBFixesRegion regionWithRectangles:&rect count:1];
}
- (XCBFixesRegion*)windowDamaged
{
	XCBFixesRegion* parts;
	if (!self->damaged)
	{
		parts = [self calculateExtents];
		[damage subtractWithRepair: nil 
		                     parts: nil];
	}
	else
	{
		XCBRect frame = [window frame];
		int16_t border_width = [window borderWidth];
		parts = [XCBFixesRegion regionWithRectangles: NULL 
		                                       count: 0];
		[damage subtractWithRepair: nil 
		                     parts: parts];
		[parts translateWithDX: frame.origin.x + border_width
				    dY: frame.origin.y + border_width];
	}
	self->damaged = YES;
	return parts;
}
@end
