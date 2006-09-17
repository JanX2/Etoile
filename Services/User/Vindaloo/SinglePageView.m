/*
 * Copyright (C) 2005  Stefan Kleine Stegemann
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

#import "SinglePageView.h"
#import "NSView+Scrolling.h"
#import "ExtendedScrollView.h"
#import "Preferences.h"
#include <float.h>

/**
 * Non-Public methods.
 */
@interface SinglePageView (Private)
- (NSSize) myZoomedSize;
- (void) myDrawPageBoundaries;
- (void) myApplyResizePolicy;
- (NSArray*) myBuildZoomFactors;
- (void) myDocumentPageDidChange: (NSNotification*)aNotification;
@end


@implementation SinglePageView

- (id) initWithFrame: (NSRect)aFrame
{
   self = [super initWithFrame: aFrame];
   if (self)
   {
      document   = nil;
      zoom       = [[ZoomFactorRange alloc] initWithFactors: [self myBuildZoomFactors]];
      [zoom setDelegate: self];
      resizePolicy = ResizePolicyNone;
      paperColor = nil;
      [self setPaperColor: [NSColor whiteColor]];
   }

   return self;
}

- (void) dealloc
{
   NSLog(@"dealloc SinglePageView");
   [self setDocument: nil];
   [self setPaperColor: nil];
   [zoom release];
   [super dealloc];
}

- (void) setDocument: (Document*)aDocument
{
   [[NSNotificationCenter defaultCenter] removeObserver: self];
   [document release];
   
   document = [aDocument retain];
   
   if (document)
   {
      [self setFrameSize: [self myZoomedSize]];
      [self displayContentTop];
      
      [[NSNotificationCenter defaultCenter]
            addObserver: self
               selector: @selector(myDocumentPageDidChange:)
                   name: kDocumentPageChangedNotification
                 object: document];
   }
}

- (NSSize) preferredSize
{
   return [self myZoomedSize];
}

- (void) setPaperColor: (NSColor*)aColor
{
   [paperColor release];
   paperColor = [aColor retain];
   [self setNeedsDisplay: YES];
}

- (NSColor*) paperColor
{
   return paperColor;
}

- (void) setZoom: (float)aFactor
{
   [zoom setFactor: [ZoomFactor factorWithValue: aFactor]];
}

- (void) zoomIn
{
   [zoom increment];
}

- (void) zoomOut
{
   [zoom decrement];
}

- (float) zoom
{
   return [[zoom factor] value];
}

- (NSSize) zoomContentToFit: (NSSize)aSize
{
   NSSize normalized = [document pageSize];

   float xFactor = aSize.width / normalized.width;
   float yFactor = aSize.height / normalized.height;
   
   float factor = (xFactor < yFactor ? xFactor : yFactor);
   [zoom setFactor: [ZoomFactor factorWithValue: 100.0 * factor]];

   return [self myZoomedSize];
}

- (void) setResizePolicy: (ResizePolicy)aPolicy
{
   resizePolicy = aPolicy;
   [self myApplyResizePolicy];
}

- (ResizePolicy) resizePolicy
{
   return resizePolicy;
}

- (void) scrollUpOnePage
{
   if (![self scrollPageUp])
   {
      if ([document previousPage])
      {
         [self scrollToBottom];
      }
   }
}

- (void) scrollDownOnePage
{
   if (![self scrollPageDown])
   {
      [document nextPage];
   }
}

- (void) scrollUpOneLine
{
   [self scrollLineUp]; // NSView+Scrolling
}

- (void) scrollDownOneLine
{
   [self scrollLineDown]; // NSView+Scrolling
}

- (void) scrollLeftOneLine
{
   [self scrollLineLeft]; // NSView+Scrolling
}

- (void) scrollRightOneLine
{
   [self scrollLineRight]; // NSView+Scrolling
}

- (void) displayContentTop
{
   [self scrollToTop]; // NSView+Scrolling
}

- (void) displayContentBottom
{
   [self scrollToBottom]; // NSView+Scrolling
}

- (void) displayContentLeft
{
   [self scrollToLeftEdge]; // NSView+Scrolling
}

- (void) displayContentRight
{
   [self scrollToRightEdge]; // NSView+Scrolling
}

- (void) update
{
   [self setNeedsDisplay: YES];
   [[self enclosingScrollView] setNeedsDisplay: YES];
}

- (void) updateAndScrollToRect: (NSRect)aRect;
{
   [self update];
   [self scrollRectToVisible: [[zoom factor] translateRect: aRect]];
}

- (BOOL) isOpaque
{
   return ([self paperColor] != nil);
}

- (void) drawRect: (NSRect)aRect
{
   NSRect contentRect;
   
   contentRect = NSMakeRect(0,  0, [self frame].size.width, [self frame].size.height);

   // background
   if ([self isOpaque])
   {
      [[self paperColor] set];
      [NSBezierPath fillRect: contentRect];
   }

   // page   
   [document drawPageAtPoint: contentRect.origin zoom: [zoom factor]];

   // mark page boundaries
   if ([[Preferences sharedPrefs] markPageBoundaries])
   {
      [self myDrawPageBoundaries];
   }
}

- (void) viewDidMoveToSuperview
{
   if ([self enclosingScrollView])
   {
      [[self enclosingScrollView] setVerticalPageScroll: 200];
      // TODO: possibly use a ratio that is proportional to
      //       the size of the page?
   }
}

- (void) scrollViewDidResize: (NSScrollView*)aScrollView
{
   NSLog(@"scrollViewDidResize");
   [self myApplyResizePolicy];
}

- (void) zoomFactorChanged: (ZoomFactorRange*)aRange
             withOldFactor: (ZoomFactor*)anOldFactor
{
   ZoomFactor* oldFactor = (anOldFactor != nil ? anOldFactor : [aRange factor]);
   
   NSRect oldVRect = [[self enclosingScrollView] documentVisibleRect];
   NSRect normRect = [oldFactor normalizeRect: oldVRect];

   [self setFrameSize: [self myZoomedSize]];

   NSRect scaledRect = [[zoom factor] translateRect: normRect];
   NSRect vRect = [[self enclosingScrollView] documentVisibleRect];

   NSPoint origin = NSMakePoint(NSMidX(scaledRect) - (NSWidth(vRect) / 2),
                                NSMidY(scaledRect) - (NSHeight(vRect) / 2));
   [self scrollPoint: origin];

   [[NSNotificationCenter defaultCenter]
         postNotificationName: kZoomFactorChangedNotification
                       object: self];
}

@end

/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation SinglePageView (Private)

- (NSSize) myZoomedSize
{
   return [[zoom factor] translateSize: [document pageSize]];
}

- (void) myDrawPageBoundaries
{
   // draw only if the enclosing clipview is bigger than
   // this view
   NSRect clipRect = [[[self enclosingScrollView] contentView] bounds];
   NSRect selfRect = [self frame];
   float diffWidth = NSWidth(clipRect) - NSWidth(selfRect);
   float diffHeight = NSHeight(clipRect) - NSHeight(selfRect);
   if ((diffWidth <= 2) && (diffHeight <= 2))
   {
      return;
   }
   
   NSSize pageSize = [self myZoomedSize];
   float minX = 1.0;
   float minY = 1.0;
   float maxX = (minX + pageSize.width) - 2.0;
   float maxY = (minY + pageSize.height) - 2.0;

   NSBezierPath* path = [NSBezierPath bezierPath];
   [[NSColor lightGrayColor] set];
   [path setLineWidth: 1.0];

   // lower left edge
   [path moveToPoint: NSMakePoint(minX, minY + 10)];
   [path lineToPoint: NSMakePoint(minX, minY)];
   [path lineToPoint: NSMakePoint(minX + 10, minY)];
   // lower right edge
   [path moveToPoint: NSMakePoint(maxX - 10, minY)];
   [path lineToPoint: NSMakePoint(maxX, minY)];
   [path lineToPoint: NSMakePoint(maxX, minY + 10)];
   // upper left edge
   [path moveToPoint: NSMakePoint(minX, maxY - 10)];
   [path lineToPoint: NSMakePoint(minX, maxY)];
   [path lineToPoint: NSMakePoint(minX + 10, maxY)];
   // upper right edge
   [path moveToPoint: NSMakePoint(maxX, maxY - 10)];
   [path lineToPoint: NSMakePoint(maxX, maxY)];
   [path lineToPoint: NSMakePoint(maxX - 10, maxY)];

   [path stroke];
}

- (void) myApplyResizePolicy
{
   NSSize contentSize = [[self enclosingScrollView] contentSize];

   switch (resizePolicy)
   {
      case ResizePolicyFitWidth:
         [self zoomContentToFit: NSMakeSize(contentSize.width, FLT_MAX)];
         break;
      case ResizePolicyFitHeight:
         [self zoomContentToFit: NSMakeSize(FLT_MAX, contentSize.height)];
         break;
      case ResizePolicyFitPage:
         [self zoomContentToFit: contentSize];
         break;
      case ResizePolicyNone:
      default:
         // do nothing
         break;
   }
}

- (NSArray*) myBuildZoomFactors
{
   return [NSArray arrayWithObjects:
              [ZoomFactor factorWithValue: 10.0],
              [ZoomFactor factorWithValue: 25.0],
              [ZoomFactor factorWithValue: 33.0],
              [ZoomFactor factorWithValue: 50.0],
              [ZoomFactor factorWithValue: 66.0],
              [ZoomFactor factorWithValue: 75.0],
              [ZoomFactor factorWithValue: 88.0],
              [ZoomFactor factorWithValue: 100.0],
              [ZoomFactor factorWithValue: 115.0],
              [ZoomFactor factorWithValue: 125.0],
              [ZoomFactor factorWithValue: 150.0],
              [ZoomFactor factorWithValue: 175.0],
              [ZoomFactor factorWithValue: 200.0],
              [ZoomFactor factorWithValue: 250.0],
              [ZoomFactor factorWithValue: 300.0],
              [ZoomFactor factorWithValue: 350.0],
              nil];
}

- (void) myDocumentPageDidChange: (NSNotification*)aNotification
{
   // scroll to the top of the page whenever a new page
   // is displayed
   [self displayContentTop];
}

@end
