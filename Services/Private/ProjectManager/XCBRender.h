/**
 * Étoilé ProjectManager - XCBRender.h
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
#import "XCBConnection.h"
#import "XCBGeometry.h"
#import <Foundation/NSObject.h>

#include <xcb/render.h>
#include <xcb/xcb_renderutil.h>

@class XCBVisual;
@class XCBRenderPicture;
@class XCBRenderPictureFormat;
@protocol XCBDrawable;

@interface XCBRender : NSObject
{
}
+ (void)initializeExtensionWithConnection: (XCBConnection*)connection;
+ (XCBRenderPictureFormat*)findVisualFormat: (xcb_visualid_t)visual;
+ (XCBRenderPictureFormat*)findStandardVisualFormat: (xcb_pict_standard_t)visual;
@end

static inline xcb_render_color_t XCBRenderMakeColor(
		uint16_t r, 
		uint16_t g,
		uint16_t b, 
		uint16_t a)
{
	xcb_render_color_t c;
	c.red = r;
	c.green = g;
	c.blue = b;
	c.alpha = a;
	return c;
}

@interface XCBRenderPicture : NSObject
{
	xcb_render_picture_t picture_id;
}
+ (XCBRenderPicture*)pictureWithDrawable: (id<XCBDrawable>)drawable
                                  format: (XCBRenderPictureFormat*)format
                               valueMask: (uint32_t)mask
                               valueList: (uint32_t*)list;
- (id)initWithDrawable: (id<XCBDrawable>)drawable
         pictureFormat: (XCBRenderPictureFormat*)format
             valueMask: (uint32_t)mask
             valueList: (uint32_t*)list;
- (xcb_render_picture_t)xcbRenderPictureId;
- (void)compositeWithOperation: (xcb_render_pict_op_t)op
                          mask: (XCBRenderPicture*)mask
                   destination: (XCBRenderPicture*)dest
                     fromPoint: (XCBPoint)srcPoint
                     maskPoint: (XCBPoint)maskPoint
                      intoRect: (XCBRect)destRect;
- (void)fillRectangles: (xcb_rectangle_t*)rects
                 count: (uint32_t)count
                 color: (xcb_render_color_t)colour
             operation: (xcb_render_pict_op_t)op;
@end

@interface XCBRenderPictureFormat : NSObject
{
	xcb_render_pictforminfo_t format;
}

- (id)initWithFormatInfo: (xcb_render_pictforminfo_t*)format;
- (xcb_render_pictformat_t)xcbRenderPictureFormatId;
- (uint8_t)type;
- (uint8_t)depth;
- (xcb_render_directformat_t)direct;
- (xcb_colormap_t)colormap;
@end
