/**
 * Étoilé ProjectManager - XCBRender.m
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
#import "XCBRender.h"
#import "XCBExtension.h"
#import "XCBVisual.h"
#import "XCBDrawable.h"
#import <xcb/render.h>
#import <xcb/xcb_renderutil.h>

#import <EtoileFoundation/EtoileFoundation.h>

@implementation XCBRender

+ (void)initializeExtensionWithConnection: (XCBConnection*)connection;
{
	static const char *extensionName = "RENDER";
	NSObject *delegate = [connection delegate];
	xcb_query_extension_reply_t* reply;
	
	reply = XCBInitializeExtension(
			connection,
			extensionName);

	xcb_render_query_version_cookie_t version_cookie = 
		xcb_render_query_version([connection connection], 
			XCB_RENDER_MAJOR_VERSION,
			XCB_RENDER_MINOR_VERSION);
	xcb_render_query_version_reply_t* version_reply = 
		xcb_render_query_version_reply(
				[connection connection], version_cookie, NULL);
	if (!XCBCheckExtensionVersion(
				XCB_RENDER_MAJOR_VERSION,
				XCB_RENDER_MINOR_VERSION,
				version_reply->major_version,
				version_reply->minor_version))
	{
		free(reply);
		free(version_reply);
		[[NSException 
			exceptionWithName: XCBExtensionNotPresentException
			           reason: @"Unable to find the render extension with the version required."
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

+ (XCBRenderPictureFormat*)findVisualFormat: (xcb_visualid_t)visual_id
{
	const xcb_render_query_pict_formats_reply_t* formats;
	xcb_render_pictvisual_t *pictvisual;
	xcb_render_pictforminfo_t *format;

	formats = xcb_render_util_query_formats([XCBConn connection]);
	pictvisual = xcb_render_util_find_visual_format(formats, visual_id);
	if (pictvisual != NULL)
	{
		xcb_render_pictforminfo_t template;
		template.id = pictvisual->format;
		format = xcb_render_util_find_format(formats, XCB_PICT_FORMAT_ID, &template, 0);
		return [[[XCBRenderPictureFormat alloc] 
			initWithFormatInfo: format] 
				autorelease];
	}
	else
		return nil;
}
+ (XCBRenderPictureFormat*)findStandardVisualFormat: (xcb_pict_standard_t)pict_format
{
	const xcb_render_query_pict_formats_reply_t* formats;
	xcb_render_pictvisual_t *pictvisual;
	xcb_render_pictforminfo_t *format;

	formats = xcb_render_util_query_formats([XCBConn connection]);
	format = xcb_render_util_find_standard_format(formats, pict_format);
	return [[[XCBRenderPictureFormat alloc] initWithFormatInfo: format] 
		autorelease];
}

@end

@implementation XCBRenderPictureFormat

- (id)initWithFormatInfo: (xcb_render_pictforminfo_t*)form
{
	SELFINIT;
	format = *form;
	return self;
}
- (xcb_render_pictformat_t)xcbRenderPictureFormatId
{
	return format.id;
}
- (uint8_t) type
{
	return format.type;
}
- (uint8_t) depth
{
	return format.depth;
}
- (xcb_render_directformat_t) direct
{
	return format.direct;
}
- (xcb_colormap_t) colormap
{
	return format.colormap;
}
@end

@implementation XCBRenderPicture
+ (XCBRenderPicture*)pictureWithDrawable: (id<XCBDrawable>)drawable
                                  format: (XCBRenderPictureFormat*)format
                               valueMask: (uint32_t)mask
                               valueList: (uint32_t*)list;
{
	return [[[self alloc]
		initWithDrawable: drawable
		   pictureFormat: format
		       valueMask: mask
		       valueList: list]
		autorelease];
}

- (id)initWithDrawable: (id<XCBDrawable>)drawable
         pictureFormat: (XCBRenderPictureFormat*)format
             valueMask: (uint32_t)mask
             valueList: (uint32_t*)list;
{
	SELFINIT;
	picture_id = xcb_generate_id([XCBConn connection]);
	xcb_render_create_picture([XCBConn connection], picture_id, [drawable xcbDrawableId],
			[format xcbRenderPictureFormatId],
			mask, list);
	return self;
}
- (xcb_render_picture_t)xcbRenderPictureId;
{
	return picture_id;
}
- (id)copyWithZone: (NSZone*)zone
{
	return [self retain];
}
- (void)dealloc
{
	xcb_render_free_picture([XCBConn connection], picture_id);
	[super dealloc];
}
- (void)compositeWithOperation: (xcb_render_pict_op_t)op
	                  mask: (XCBRenderPicture*)mask
                   destination: (XCBRenderPicture*)dest
                     fromPoint: (XCBPoint)srcPoint
                     maskPoint: (XCBPoint)maskPoint
                      intoRect: (XCBRect)destRect;
{
	xcb_render_picture_t mask_id = 0;
	if (mask)
		mask_id = mask->picture_id;
	xcb_render_composite([XCBConn connection],
			op,
			self->picture_id,
			mask_id,
			dest->picture_id,
			srcPoint.x, srcPoint.y,
			maskPoint.x, maskPoint.y,
			destRect.origin.x, destRect.origin.y,
			destRect.size.width, destRect.size.height
			);
}
- (void)fillRectangles: (xcb_rectangle_t*)rects
                 count: (uint32_t)count
                 color: (xcb_render_color_t)colour
	     operation: (xcb_render_pict_op_t)op;
{
	xcb_render_fill_rectangles([XCBConn connection],
			op,
			self->picture_id,
			colour,
			count,
			rects);
}
@end
