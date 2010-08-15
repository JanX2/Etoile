/**
 * Étoilé ProjectManager - XCBFixes.m
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
#import <XCBKit/XCBFixes.h>
#import <XCBKit/XCBExtension.h>
#import <XCBKit/XCBWindow.h>
#include <xcb/xfixes.h>

#import <EtoileFoundation/EtoileFoundation.h>

@implementation XCBFixes

+ (void)initializeExtensionWithConnection: (XCBConnection*)connection
{
	static const char *extensionName = "XFIXES";
	xcb_query_extension_reply_t* reply;
	
	reply = XCBInitializeExtension(
			connection,
			extensionName);

	xcb_xfixes_query_version_cookie_t version_cookie = 
		xcb_xfixes_query_version([connection connection], 
			XCB_XFIXES_MAJOR_VERSION,
			XCB_XFIXES_MINOR_VERSION);
	xcb_xfixes_query_version_reply_t* version_reply = 
		xcb_xfixes_query_version_reply(
				[connection connection], version_cookie, NULL);
	if (!XCBCheckExtensionVersion(
				XCB_XFIXES_MAJOR_VERSION,
				XCB_XFIXES_MINOR_VERSION,
				version_reply->major_version,
				version_reply->minor_version))
	{
		free(reply);
		free(version_reply);
		[[NSException 
			exceptionWithName: XCBExtensionNotPresentException
			           reason: @"Unable to find the xfixes extension with the version required."
			         userInfo: [NSDictionary dictionary]]
			raise];
	}
	NSLog(@"Initialized %s extension (%d.%d) for connection %@ ", 
		extensionName,
		version_reply->major_version,
		version_reply->minor_version,
		connection
		);
	free(reply);
	free(version_reply);
}

@end

@implementation XCBFixesRegion

- (id)initWithRegionId: (xcb_xfixes_region_t)regionId
{
	SELFINIT;
	region_id = regionId;
	return self;
}
- (id)initWithRectangles: (xcb_rectangle_t*)rectangles
                   count: (uint32_t)length
{
	SELFINIT;
	region_id = xcb_generate_id([XCBConn connection]);
	xcb_xfixes_create_region(
			[XCBConn connection],
			region_id,
			length,
			rectangles
			);
	return self;
}
+ (XCBFixesRegion*)regionWithRectangles: (xcb_rectangle_t*)rectangles count: (uint32_t)count
{
	return [[[self alloc] 
		initWithRectangles: rectangles 
		              count: count]
			autorelease];
}
/**
  * shape may only be XCB_SHAPE_SK_BOUNDING or XCB_SHAPE_SK_CLIP
  */
- (id)initWithWindow: (XCBWindow*)window shape: (xcb_shape_kind_t)bounding_or_clip
{
	SELFINIT;
	region_id = xcb_generate_id([XCBConn connection]);
	xcb_xfixes_create_region_from_window(
			[XCBConn connection], 
			region_id, 
			[window xcbWindowId], 
			bounding_or_clip);
	return self;
}

+ (XCBFixesRegion*)regionWithWindow: (XCBWindow*)w shape: (xcb_shape_kind_t)k
{
	return [[[self alloc] initWithWindow:w shape:k] autorelease];
}

+ (XCBFixesRegion*)nilRegion
{
	return [[[self alloc] initWithRegionId:0] autorelease];
}

- (void)translateWithDX: (int16_t)dx dY: (int16_t)dy
{
	xcb_xfixes_translate_region([XCBConn connection], region_id, dx, dy);
}

- (xcb_xfixes_region_t)xcbXFixesRegionId
{
	return region_id;
}
- (void)clipPicture: (XCBRenderPicture*)picture atPoint: (XCBPoint)point
{
	xcb_xfixes_set_picture_clip_region(
			[XCBConn connection],
			[picture xcbRenderPictureId],
			region_id,
			point.x,
			point.y);
}
- (void)subtractRegion: (XCBFixesRegion*)source2 intoDestination: (XCBFixesRegion*)dest
{
	xcb_xfixes_subtract_region(
			[XCBConn connection],
			self->region_id,
			source2->region_id,
			dest->region_id);
}
- (void)unionWithRegion: (XCBFixesRegion*)source2 intoDestination: (XCBFixesRegion*)dest
{
	xcb_xfixes_union_region(
			[XCBConn connection],
			self->region_id,
			source2->region_id,
			dest->region_id);
}
- (void)intersectRegion: (XCBFixesRegion*)source2
        intoDestination: (XCBFixesRegion*)dest
{
	xcb_xfixes_intersect_region(
			[XCBConn connection],
			self->region_id,
			source2->region_id,
			dest->region_id);
}

- (void)copyIntoRegion: (XCBFixesRegion*)dest
{
	xcb_xfixes_copy_region([XCBConn connection], self->region_id, dest->region_id);
}
- (id)copyWithZone: (NSZone*)zone
{
	return [self retain];
}
- (void) dealloc
{
	xcb_xfixes_destroy_region([XCBConn connection], region_id);
	[super dealloc];	
}
@end
