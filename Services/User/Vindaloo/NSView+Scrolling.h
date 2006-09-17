/*
 * Copyright (C) 2004  Stefan Kleine Stegemann
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

/**
 * Adds some handy scrolling methods to NSView. All methods
 * return and leave a view's scrolling state unmodfied if
 * the receiving view is not embedded in an NSScrollView.
 */
@interface NSView (Scrolling)

/** Make the top of the view visible. Preserves the scrolling
    state of the x axis.  */
- (void) scrollToTop;

/** Make the bottom of the view visible. Preserves the scrolling
    state of the x axis.  */
- (void) scrollToBottom;

/** Scroll up by an amount that corresponds to the "PageUp" key.
    Returns NO if the view cannot be scrolled up any further, YES
    otherwise.  */
- (BOOL) scrollPageUp;

/** Scroll down by an amount that corresponds to the "PageDown" key.
    Returns NO if the view cannot be scrolled down any further, YES
    otherwise.  */
- (BOOL) scrollPageDown;

/** Scroll up by an amount that corresponds to the "Arrow Up" key.
    Returns NO if the view cannot be scrolled up any further, YES
    otherwise.  */
- (BOOL) scrollLineUp;

/** Scroll down by an amount that corresponds to the "Arrow Down" key.
    Returns NO if the view cannot be scrolled down any further, YES
    otherwise.  */
- (BOOL) scrollLineDown;

/** Scroll up by a given amount. Returns NO if the view cannot be scrolled
    up any further, YES otherwise.  */
- (BOOL) scrollUp: (float)amount;

/** Scroll down by a given amount. Returns NO if the view cannot be scrolled
    down any further, YES otherwise.  */
- (BOOL) scrollDown: (float)amount;

/** Make the leftmost part of the view visible. Preserves the
    scrolling state of the y axis.  */
- (void) scrollToLeftEdge;

/** Make the rightmost part of the view visible. Preserves the
    scrolling state of the y axis.  */
- (void) scrollToRightEdge;

/** Scroll left by an amount that corresponds to the "Arrow Left" key.
    Returns NO if the view cannot be scrolled to the left side any further,
    YES otherwise.  */
- (BOOL) scrollLineLeft;

/** Scroll right by an amount that corresponds to the "Arrow Right" key.
    Returns NO if the view cannot be scrolled to the right side any further,
    YES otherwise.  */
- (BOOL) scrollLineRight;

/** Scroll left by a given amount. Returns NO if the view cannot be scrolled
    to the left side any further, YES otherwise.  */
- (BOOL) scrollLeft: (float)amount;

/** Scroll right by a given amount. Returns NO if the view cannot be scrolled
    to the right side any further, YES otherwise.  */
- (BOOL) scrollRight: (float)amount;

@end
