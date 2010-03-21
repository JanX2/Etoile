/**
 * Étoilé ProjectManager - XCBGeometry.h
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
#include <stdint.h>
#include <xcb/xproto.h>

typedef struct _XCBPoint
{
	int16_t x;
	int16_t y;
} XCBPoint;

typedef struct _XCBSize
{
	int16_t width;
	int16_t height;
} XCBSize;

typedef struct _XCBRect 
{
	XCBPoint origin;
	XCBSize size;
	int16_t border_width;
} XCBRect;

static const XCBRect XCBInvalidRect = {{0xffff, 0xffff}, {0xffff, 0xffff}};

static inline XCBPoint XCBMakePoint(int16_t x, int16_t y) 
{
	XCBPoint p = { x, y};
	return p;
}
static inline XCBRect XCBMakeRect(int16_t x,
                                  int16_t y,
                                  int16_t width,
                                  int16_t height)
{
	XCBRect rect = { {x, y}, {width, height} };
	return rect;
}

static inline NSString *XCBStringFromRect(XCBRect rect)
{
	return [NSString stringWithFormat:@"(%hd, %hd), (%hd, %hd)",
		   rect.origin.x, rect.origin.y, rect.size.width, rect.size.height];
}

static inline xcb_rectangle_t XCBRectangleFromRect(XCBRect rect)
{
	xcb_rectangle_t r = 
		{rect.origin.x, rect.origin.y, rect.size.width, rect.size.height};
	return r;
}
static inline XCBRect XCBRectFromRectangle(xcb_rectangle_t rect)
{
	XCBRect r = {{rect.x, rect.y}, {rect.width, rect.height}};
	return r;
}
