/**
 * Étoilé ProjectManager - PMScreen.h
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
#import "PMCompositeWindow.h"

@class XCBScreen;
@class XCBRenderPicture;
@class XCBFixesRegion;
@class NSMutableArray;

@interface PMScreen : NSObject
{
	XCBScreen *screen;
	XCBRenderPicture *rootBuffer, *rootPicture;
	XCBRenderPicture *rootTile;
	XCBFixesRegion *allDamage;
	NSMutableArray *childWindows;
	NSMutableDictionary *compositeMap;
	
	BOOL clipChanged;
}

- (id)initWithScreen: (XCBScreen*)screen;
- (XCBScreen*)screen;
- (XCBWindow*)rootWindow;
- (XCBRenderPicture*)rootBuffer;
- (void)setRootBuffer: (XCBRenderPicture*)rb;
- (XCBRenderPicture*)rootPicture;
- (void)setRootPicture: (XCBRenderPicture*)rp;
- (NSArray*)childWindows;
- (void)appendDamage: (XCBFixesRegion*)damage;

// Event handlers
- (void)childWindowDiscovered: (XCBWindow*)child
              compositeWindow: (PMCompositeWindow*)compositeWindow;
- (void)childWindowRemoved: (XCBWindow*)child;

// Paint the damaged areas and remove accumulated damage
- (void)paintAllDamaged;
// Paint everything regardless of accumulated damage
- (void)paintAll;
@end
