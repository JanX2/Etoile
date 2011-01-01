/**
 * Étoilé ProjectManager - XCBImage.m
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
#import "XCBImage.h"
#import "XCBDrawable.h"
#import "XCBException.h"
#import "XCBVisual.h"

@interface XCBImage (Private)
@end

@implementation XCBImage
- (id)initWithData: (NSData*)theData
            inRect: (XCBRect)aRect
            format: (xcb_image_format_t)aFormat
             depth: (uint8_t)aDepth;
{
	self = [super init];
	if (self == nil)
		return nil;
	data = [theData retain];
	rect = rect;
	depth = aDepth;
	format = aFormat;
	return self;
}
+ (XCBImage*)getImageWithDrawable: (id<XCBDrawable>)drawable
                           inRect: (XCBRect)rect
                           format: (xcb_image_format_t)format
                           planes: (uint32_t)planes
{
	xcb_get_image_cookie_t cookie;

	cookie = xcb_get_image([XCBConn connection],
		format,
		[drawable xcbDrawableId],
		rect.origin.x,
		rect.origin.y,
		rect.size.width,
		rect.size.height,
		planes);
	xcb_generic_error_t *error = NULL;
	xcb_get_image_reply_t *reply = xcb_get_image_reply(
		[XCBConn connection],
		cookie,
		&error);
	if (reply == NULL)
	{
		assert(error != NULL);
		XCBRaiseGenericErrorException(error, @"xcb_get_image", [NSString stringWithFormat: @"+[XCBImage getImageWithDrawable:inRect:format:planes] (drawable=%@, rect=%@, format=%d, planes=%d)", drawable, rect, format, planes]);
	}
	int data_length = xcb_get_image_data_length(reply);
	uint8_t *data_buffer = xcb_get_image_data(reply);
	NSData *data = [NSData dataWithBytes: data_buffer length: data_length];
	XCBImage *image = [[XCBImage alloc]
		initWithData: data
		      inRect: rect
		      format: format
		       depth: reply->depth];
	image->visual = reply->visual;
	free(reply);
	return [image autorelease];
}
- (void)dealloc
{
	[data release];
	[super dealloc];
}
- (NSData*)data
{
	return data;
}
- (uint8_t)depth
{
	return depth;
}
- (XCBVisual*)visual
{
	return [XCBVisual visualWithId: visual];
}
- (XCBRect)rect
{
	return rect;
}
- (xcb_image_format_t)format
{
	return format;
}
@end
