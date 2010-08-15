/**
 * Étoilé ProjectManager - PMCompositeWindow.h
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
#import <XCBKit/XCBConnection.h>

@class PMScreen;

@class XCBWindow;
@class XCBDamage;
@class XCBRenderPicture;
@class XCBPixmap;
@class XCBFixesRegion;
@class XCBScreen;

enum PMCompositeWindowMode
{
	PMCompositeWindowUnknownMode = 0,
	PMCompositeWindowSolid = 1,
	PMCompositeWindowARGB,
	//PMCompositeWindowTransparent
};

@interface PMCompositeWindow : NSObject
{
	XCBWindow *window;
	id delegate;
	BOOL damaged;
	XCBDamage *damage;
	XCBRenderPicture *picture, *alphaPicture;
	XCBPixmap *pixmap;
	XCBFixesRegion *clipRegion, *borderSize, *extents, *borderClip;
	uint32_t opacity;
	enum PMCompositeWindowMode mode;
}
+ (PMCompositeWindow*)windowWithXCBWindow: (XCBWindow*)xcbWindow;
- (id)initWithXCBWindow: (XCBWindow*)xcbWindow;
- (void)setDelegate: (id)delegate;
- (XCBWindow*)window;
- (void)paintIntoBuffer: (XCBRenderPicture*)buffer 
             withRegion: (XCBFixesRegion*)region 
            clipChanged: (BOOL)cc;
- (void)paintWithAlphaIntoBuffer: (XCBRenderPicture*)buffer 
                      withRegion: (XCBFixesRegion*)region
                     clipChanged: (BOOL)clipChanged;
/**
  * The current extents of the window. Only updated during painting.
  */
- (XCBFixesRegion*)extents;
/**
  * The window was damaged. This method
  * returns a newly created (autoreleased) region which is
  * the responsibility of the caller to -[XCBFixesRegion destroy]
  */
- (XCBFixesRegion*)windowDamaged;

/**
  * Creates a new extents object
  * calculating the extents of the
  * current window based on its frame. 
  * Used to perform extents calculation
  * outside that used by the window itself
  * Don't forget to destroy
  */
- (XCBFixesRegion*)calculateExtents;
@end

@interface NSObject (PMCompositeWindowDelegate)
- (void)compositeWindow: (PMCompositeWindow*)compositeWindow 
         extentsChanged: (XCBFixesRegion*)newExtents
             oldExtents: (XCBFixesRegion*)oldExtents;
@end
