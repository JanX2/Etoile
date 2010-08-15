/**
 * Étoilé ProjectManager - XCBFixes.h
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
#import <XCBKit/XCBRender.h>
#import <XCBKit/XCBGeometry.h>
#import <Foundation/NSObject.h>

#include <xcb/xfixes.h>

@interface XCBFixes : NSObject
{
}
+ (void)initializeExtensionWithConnection: (XCBConnection*)connection;
@end

@interface XCBFixesRegion : NSObject
{
	xcb_xfixes_region_t region_id;
}
- (id)initWithRegionId: (xcb_xfixes_region_t)regionId;
- (id)initWithRectangles: (xcb_rectangle_t*)rectangles
                   count: (uint32_t)length;
/**
  * shape may only be XCB_SHAPE_SK_BOUNDING or XCB_SHAPE_SK_CLIP
  */
- (id)initWithWindow: (XCBWindow*)window 
               shape: (xcb_shape_kind_t)bounding_or_clip;
- (void)clipPicture: (XCBRenderPicture*)picture 
            atPoint: (XCBPoint)point;
- (xcb_xfixes_region_t)xcbXFixesRegionId;
- (void)translateWithDX: (int16_t)dx 
                     dY: (int16_t)dy;
- (void)subtractRegion: (XCBFixesRegion*)source2 
       intoDestination: (XCBFixesRegion*)dest;
- (void)copyIntoRegion: (XCBFixesRegion*)dest;
- (void)unionWithRegion: (XCBFixesRegion*)source2 
        intoDestination: (XCBFixesRegion*)dest;
- (void)intersectRegion: (XCBFixesRegion*)source2
        intoDestination: (XCBFixesRegion*)dest;

+ (XCBFixesRegion*)regionWithWindow: (XCBWindow*)w 
                              shape: (xcb_shape_kind_t)k;
+ (XCBFixesRegion*)regionWithRectangles: (xcb_rectangle_t*)rectangles 
                                  count: (uint32_t)count;
+ (XCBFixesRegion*)nilRegion;
@end
