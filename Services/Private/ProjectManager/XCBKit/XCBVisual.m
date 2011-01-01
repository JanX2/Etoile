/**
 * Étoilé ProjectManager - XCBVisual.m
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
#import <XCBKit/XCBVisual.h>

/**
  * A store of visual objects. This assumes
  * one connection (like the rest of XCBKit).
  */
static NSMapTable * VisualStore = nil;

@interface XCBVisual (Private)
- (id)initWithVisualType: (xcb_visualtype_t*)aVisualType;
@end

@implementation XCBVisual
+ (void)initialize
{
	if (VisualStore == nil)
	{
		VisualStore = NSCreateMapTable(NSIntMapKeyCallBacks,
			NSObjectMapValueCallBacks, 30);
	}
}

- (uint8_t)bitsPerRGBValue
{
	return visual_type.bits_per_rgb_value;
}

- (xcb_visualid_t)visualId
{
	return visual_type.visual_id;
}
- (uint16_t)colormapEntries
{
	return visual_type.colormap_entries;
}
- (uint32_t)redMask
{
	return visual_type.red_mask;
}
- (uint32_t)greenMask
{
	return visual_type.green_mask;
}
- (uint32_t)blueMask
{
	return visual_type.blue_mask;
}
- (xcb_visual_class_t)visualClass
{
	return visual_type._class;
}

+ (XCBVisual*)visualWithId: (xcb_visualid_t)visual_id
{
	XCBVisual *visual = NSMapGet(VisualStore, (void*)(intptr_t)visual_id);
	return visual;
}
@end

@implementation XCBVisual (Private)
- (id)initWithVisualType: (xcb_visualtype_t*)aVisualType
{
	self = [super init];
	if (self == nil)
		return nil;
	visual_type = *aVisualType;
	return self;
}
@end

@implementation XCBVisual (Package)
+ (XCBVisual*)discoveredVisualType: (xcb_visualtype_t*)visual_type
{
	XCBVisual *visual = NSMapGet(VisualStore, (void*)(intptr_t)visual_type->visual_id);
	if (visual == nil)
	{
		visual = [[XCBVisual alloc]
			initWithVisualType: visual_type];
		NSMapInsert(VisualStore, (void*)(intptr_t)[visual visualId], visual);
	}
	return visual;
}

@end
