/**
 * Étoilé ProjectManager - XCBScreen.m
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
#import "XCBScreen.h"
#import "XCBWindow.h"
#import "XCBVisual.h"

#import <EtoileFoundation/EtoileFoundation.h>

@implementation XCBScreen 
- (id) initWithXCBScreen: (xcb_screen_t*)aScreen
{
	SELFINIT;
	screen = *aScreen;
	root = [[XCBWindow windowWithXCBWindow: screen.root parent: XCB_NONE] 
		retain];
	return self;
}
- (NSString*)description
{
	return [NSString stringWithFormat: @"XCBScreen screen=%d rootWindow=%@", screen, root];
}
+ (XCBScreen*) screenWithXCBScreen: (xcb_screen_t*)aScreen
{
	return [[[self alloc] initWithXCBScreen: aScreen] autorelease];
}
- (id)copyWithZone: (NSZone*)zone
{
	return [self retain];
}
- (void) dealloc
{
	[root release];
	[super dealloc];
}
- (XCBWindow*)rootWindow
{
	return root;
}
- (xcb_screen_t*)screenInfo
{
	return &screen;
}

- (xcb_visualid_t)defaultVisual
{
	return screen.root_visual;
}
- (uint8_t)defaultDepth
{
	return screen.root_depth;
}
@end
