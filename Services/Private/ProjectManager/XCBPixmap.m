/**
 * Étoilé ProjectManager - XCBPixmap.m
 *
 * Copyright (C) 2009 David Chisnall
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
#import "XCBPixmap.h"
#import <Foundation/NSObject.h>

#import <EtoileFoundation/EtoileFoundation.h>

@implementation XCBPixmap

+ (XCBPixmap*)pixmapWithDepth: (uint8_t)depth
                     drawable: (id<XCBDrawable>)drawable
                        width: (uint16_t)width
                       height: (uint16_t)height
{
	XCBPixmap *pixmap = [self alloc];
	return [[pixmap initWithDepth: depth
	                     drawable: drawable
	                        width: width
	                       height: height] autorelease];
}
- (id)initWithPixmapId: (xcb_pixmap_t)id
{
	self = [super init]; 
	if (!self) return 0;
	pixmap_id = id;
	return self;
}

- (id)initWithDepth: (uint8_t)depth
            drawable: (id<XCBDrawable>)drawable
               width: (uint16_t)width
              height: (uint16_t)height
{
	SUPERINIT;
	XCBConnection* connection = XCBConn;

	pixmap_id = xcb_generate_id([connection connection]);
	xcb_create_pixmap(
		[connection connection], 
		depth, 
		pixmap_id, 
		[drawable xcbDrawableId], 
		width, 
		height);
	return self;
}

- (id)copyWithZone: (NSZone*)zone
{
	return [self retain];
}
- (void)dealloc
{
	xcb_free_pixmap([XCBConn connection], pixmap_id);
	[super dealloc];
}
- (xcb_pixmap_t)xcbPixmapId
{
	return pixmap_id;
}
- (xcb_drawable_t)xcbDrawableId
{
	return pixmap_id;
}

@end
