/**
 * Étoilé ProjectManager - XCBPixmap.h
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
#import <XCBKit/XCBConnection.h>
#import <Foundation/NSObject.h>
#import <XCBKit/XCBDrawable.h>
#include <xcb/xcb.h>

@interface XCBPixmap : NSObject <XCBDrawable>
{
	xcb_pixmap_t pixmap_id;
}
+ (XCBPixmap*)pixmapWithDepth: (uint8_t)depth
                     drawable: (id<XCBDrawable>)drawable
                        width: (uint16_t)width
                       height: (uint16_t)height;
- (id)initWithPixmapId: (xcb_pixmap_t)id;
- (id)initWithDepth: (uint8_t)depth
           drawable: (id<XCBDrawable>)drawable
              width: (uint16_t)width
             height: (uint16_t)height;
- (xcb_pixmap_t)xcbPixmapId;
- (xcb_drawable_t)xcbDrawableId;
@end
