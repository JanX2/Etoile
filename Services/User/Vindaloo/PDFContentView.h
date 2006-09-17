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
 
#import "Document.h"
#import <AppKit/NSView.h>

// Notifications to be issued by PDFContentViews
//
/** Each time a PDFContentView changes it's zoom factor.  */
extern NSString* kZoomFactorChangedNotification;

/** Possible resize policies for live resizing.  */
typedef enum {
   ResizePolicyNone,
   ResizePolicyFitPage,
   ResizePolicyFitWidth,
   ResizePolicyFitHeight
} ResizePolicy;

/**
 * The PDFContentView defines the interface for views which are able
 * to display PDF content. The controller of a PDF document only sees
 * PDFContentView's.
 */
@protocol PDFContentView

/** Set the document to be displayed in the view. As a result, the
    view should display the current page of the document.  */
- (void) setDocument: (Document*)aDocument;

/** Get the view's preferred size. This size should be determined such
    that as much of the content as possible is visible. The preferred size
    can change over time depending on various factors, like zoom or the
    size of the current page.  */
- (NSSize) preferredSize;

/** Set the paper color. This is the color that has to be used for the
    content background. A view may decide to ignore a custom paper color.
    Each view must maintain an initial paper color, it cannot assume that
    the color is set from outside.  */
- (void) setPaperColor: (NSColor*)aColor;

/** Get the current paper color. A view must return a valid color. See
    setPaperColor: for further details.  */
- (NSColor*) paperColor;

/** Set the view's zoom factor in percent. The view is not required to
    update itself. The caller has to ensure that the view is redisplayed
    when appropriate.  */
- (void) setZoom: (float)aFactor;

/** Increase the zoom factor. It is up to the view to decide about the
    amount.  */
- (void) zoomIn;

/** Decrease the zoom factor. It is up to the view to decide about
    about the amount.  */
- (void) zoomOut;

/** Get the view's current zoom factor in percent.  */
- (float) zoom;

/** Zoom the view's contents to fit the given size. If the view cannot
    zoom, do nothing and simply return the aSize. Otherwise, the view
    should zoom it's contents and return the content's size after zooming.
    This size may be smaller than the given size but it must not be
    larger.  */
- (NSSize) zoomContentToFit: (NSSize)aSize;

/** Set the resize policy for this view. If the view supports the policy,
    it has to adjust it's zoom factor each time the window that hosts the
    view is resized.  */
- (void) setResizePolicy: (ResizePolicy)aPolicy;

/** Get the current resize policy for this view. Views which do not support
    auto resizing can return ResizePolicyNone.  */
- (ResizePolicy) resizePolicy;

/** Scroll up by the amount of a "page".  */
- (void) scrollUpOnePage;

/** Scroll down by the amount of a "page".  */
- (void) scrollDownOnePage;

/** Scroll up by the amount of a "line".  */
- (void) scrollUpOneLine;

/** Scroll down by the amount of a "line".  */
- (void) scrollDownOneLine;

/** Scroll left by the amount of a "line".  */
- (void) scrollLeftOneLine;

/** Scroll right by the amount of a "line".  */
- (void) scrollRightOneLine;

/** Ensure that the top of the content is visible. The receiver has
    to update it's scrolling state such that the enclosing scrollview
    shows the beginning of the content.  */
- (void) displayContentTop;

/** Ensure that the bottom of the content is visible. The receiver has
    to update it's scrolling state such that the enclosing scrollview
    shows the bottom of the content.  */
- (void) displayContentBottom;

/** Ensure that the left side of the content is visible. The receiver
    has to update it's scrolling state such that the encolsing scrollview
    shows the leftmost part of the content.  */
- (void) displayContentLeft;

/** Ensure that the right side of the content is visible. The receiver
    has to update it's scrolling state such that the encolsing scrollview
    shows the rightmost part of the content.  */
- (void) displayContentRight;

/** Redisplay the content with the document's current state.  */
- (void) update;

/** Scroll the receiver to show the specified area on the document's
    current page.  */
- (void) updateAndScrollToRect: (NSRect)aRect;

@end
