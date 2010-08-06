/**
 * Étoilé ProjectManager - XCBShape.h
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
#import <Foundation/NSObject.h>
#import "XCBWindow.h"

#include <xcb/shape.h>

extern NSString* XCBWindowShapeNotifyNotification;

enum
{
	XCB_SHAPE_UNSORTED = 0,
	XCB_SHAPE_YSORTED = 1,
	XCB_SHAPE_YXSORTED = 2,
	XCB_SHAPE_YXBANDED = 4
};

@interface XCBShape : NSObject
+ (void)initializeExtensionWithConnection: (XCBConnection*)connection;
@end

@interface XCBWindow (XCBShape)
/**
  * Change the rectangles that define the Bounding,
  * Clip or Input client regions of a window using
  * a set operation.
  */
- (void)setShapeRectangles: (xcb_rectangle_t*)rects
                     count: (uint32_t)len
                  ordering: (uint8_t)ordering
                 operation: (xcb_shape_op_t)op
                      kind: (xcb_shape_kind_t)kind
                    offset: (XCBPoint)offset;
/**
  * Turn ShapeNotify events on or off.
  */
- (void)setShapeSelectInput: (BOOL)selectShapeInput;
- (void)shapeCombineWithKind: (xcb_shape_kind_t)destKind
                   operation: (xcb_shape_op_t)op
                      offset: (XCBPoint)offset
                      source: (XCBWindow*)sourceWindow
                  sourceKind: (xcb_shape_kind_t)sourceKind;
@end

@interface NSObject (XCBShape_Delegate)
- (void)xcbWindowShapeNotify: (NSNotification*)notification;
@end
