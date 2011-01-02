/**
 * Étoilé ProjectManager - PMManagedWindowDecorator.h
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
#import <XCBKit/ICCCM.h>

@class XCBWindow;
@class PMManagedWindow;

@protocol PMManagedWindowDecorator
- (BOOL)shouldDecorateManagedWindow: (PMManagedWindow*)managedWindow;
- (ICCCMBorderExtents)extentsForDecorationWindow: (PMManagedWindow*)managedWindow;
- (XCBSize)minimumSizeForClientFrame: (PMManagedWindow*)managedWindow;

- (void)managedWindowRepositioned: (PMManagedWindow*)managedWindow
                  decorationFrame: (XCBRect)decorationFrame
                       childFrame: (XCBRect)childFrame;
- (void)managedWindow: (PMManagedWindow*)managedWindow focusIn: (NSNotification*)aNot;
- (void)managedWindow: (PMManagedWindow*)managedWindow focusOut: (NSNotification*)aNot;
/**
  * Determine the type of move or resize based on the
  * specified point (in decoration window space). This method
  * depends on size of the resize handles. The move-resize
  * type is specified using the EWMH constants.
  *
  * The result is unspecified if there is no decoration
  * window.
  */
-   (int)managedWindow: (PMManagedWindow*)managedWindow
moveresizeTypeForPoint: (XCBPoint)point;

- (void)managedWindow: (PMManagedWindow*)managedWindow changedState: (ICCCMWindowState)newState;
@end
