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

#import "Controller.h"
#import "Document.h"
#import "CenteringClipView.h"

/**
 * Non-Public methods.
 */
@interface Controller (Private)
- (Document*) myDocument;
- (void) myUpdatePage: (NSNotification*)aNotification;
- (void) myRefreshPage: (NSNotification*)aNotification;
- (void) myZoomFactorUpdated: (NSNotification*)aNotification;
- (void) myToggleResizePolicy: (ResizePolicy)aPolicy;
- (void) mySetResizePolicy: (ResizePolicy)aPolicy;
- (void) mySetupScrollView;
- (void) myAddDocumentTools;
- (void) myCreateSinglePageView;
- (void) mySetInitialWindowSize;
- (NSRect) myCalcPreferredFrameInFrame: (NSRect)maxFrame withPDFSize: (NSSize)aPDFSize;
- (NSSize) myCalcPDFContentSize: (NSSize)aSize add: (BOOL)addToSize;
@end


@implementation Controller

- (id) initWithWindow: (NSWindow*)aWindow
{
   self = [super initWithWindow: aWindow];
   if (self)
   {
      singlePageView = nil;
      scrollView = nil;
      tools = nil;
      menuState = nil;
      windowIsVisible = NO;
   }

   return self;
}

- (void) dealloc
{
   NSLog(@"dealloc Controller");

   [[NSNotificationCenter defaultCenter] removeObserver: self];
   [menuState release];
   [singlePageView release];
   [tools release];
   [super dealloc];
}

- (void) windowDidLoad
{
   [super windowDidLoad];
   
   [self mySetupScrollView];
   [self myAddDocumentTools];
   [self myCreateSinglePageView];
   [self goSinglePage: nil];

   [singlePageView setDocument: [self myDocument]];
   [searchController setDocument: [self myDocument]];
   
   [[NSNotificationCenter defaultCenter]
         addObserver: self
            selector: @selector(myZoomFactorUpdated:)
                name: kZoomFactorChangedNotification
              object: singlePageView];

   [[NSNotificationCenter defaultCenter]
         addObserver: self
            selector: @selector(myUpdatePage:)
                name: kDocumentPageChangedNotification
              object: [self myDocument]];
   
   [[NSNotificationCenter defaultCenter]
         addObserver: self
            selector: @selector(myRefreshPage:)
                name: kDocumentSelectionChangedNotification
              object: [self myDocument]];

   // setup the multipageview
   //multipageview = [[MultiPageView alloc] initWithFrame: [pdfview frame]
   //                                            scaleFactor: 25];
   //[multipageview setDocument: [[self myDocument] pdfDocument]];
   //[scrollview setDocumentView: multipageview];
   
   [self mySetInitialWindowSize];
   [[self myDocument] setPageByIndex: 1];
   [tools setZoom: [singlePageView zoom]];
   [tools setPageCount: [[self myDocument] countPages]];
   menuState = [[MenuState alloc] initWithDocument: [self myDocument] contentView: singlePageView];
}

- (void) windowDidBecomeMain: (NSNotification*)aNotification
{
   // We need to ensure, that the top of the content is visible
   // right after the window appeaerd on the screen for the first
   // time. windowDidLoad doesn't work because the window manager
   // may decide to change the window size when it is put on the
   // screen (which takes place AFTER windowDidLoad)
   if (!windowIsVisible)
   {
      [singlePageView displayContentTop];
      windowIsVisible = YES;
   }
   
   [menuState stateChanged];
}

- (NSRect) windowWillUseStandardFrame: (NSWindow*)aWindow defaultFrame: (NSRect)aFrame
{
   return [self myCalcPreferredFrameInFrame: aFrame withPDFSize: [singlePageView preferredSize]];
}

- (void) windowWillClose: (NSNotification*)notification;
{
   [searchController forceQuit];
}

- (SearchController*) searchController
{
   return searchController;
}

- (IBAction) nextPage: (id)aSender
{
   [[self myDocument] nextPage];
}

- (IBAction) previousPage: (id)aSender
{
   [[self myDocument] previousPage];
}

- (IBAction) firstPage: (id)aSender
{
   [[self myDocument] setPageByIndex: 1];
}

- (IBAction) lastPage: (id)aSender
{
   [[self myDocument] setPageByIndex: [[self myDocument] countPages]];
}

- (IBAction) takePageFrom: (id)aSender
{
   int page = [aSender intValue];
   if ((page > 0) && (page <= [[self myDocument] countPages])) {
      [[self myDocument] setPageByIndex: page];
   }
   else {
      // if the user entered "0", go to last page
      NSString* test = [[aSender stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
      if ([test hasPrefix: @"0"])
         [self lastPage: nil];
      else
         [self myUpdatePage: nil];
   }
}

- (IBAction) enterPageNumber: (id)aSender
{
   [tools focusPageField];
}

- (IBAction) takeZoomFrom: (id)aSender
{
   float zoom = [aSender floatValue];
   if (zoom > 0)
   {
      [singlePageView setZoom: zoom];
   }
   else
   {
      [self myZoomFactorUpdated: nil];
   }
}

- (IBAction) zoomIn: (id)aSender
{
   [self mySetResizePolicy: ResizePolicyNone];
   [singlePageView zoomIn];
}

- (IBAction) zoomOut: (id)aSender
{
   [self mySetResizePolicy: ResizePolicyNone];
   [singlePageView zoomOut];
}

- (IBAction) zoomActualSize: (id)aSender
{
   [self mySetResizePolicy: ResizePolicyNone];
   [singlePageView setZoom: 100.0];
}

- (IBAction) zoomToFit: (id)aSender
{
   [self mySetResizePolicy: ResizePolicyNone];
   [singlePageView zoomContentToFit: [scrollView contentSize]];
}

- (IBAction) toggleFitWidth: (id)aSender
{
   [self myToggleResizePolicy: ResizePolicyFitWidth];
}

- (IBAction) toggleFitHeight: (id)aSender
{
   [self myToggleResizePolicy: ResizePolicyFitHeight];
}

- (IBAction) toggleFitPage: (id)aSender
{
   [self myToggleResizePolicy: ResizePolicyFitPage];
}

- (IBAction) scrollPageUp: (id)aSender
{
   [singlePageView scrollUpOnePage];
}

- (IBAction) scrollPageDown: (id)aSender
{
   [singlePageView scrollDownOnePage];
}

- (IBAction) scrollLineUp: (id)aSender
{
   [singlePageView scrollUpOneLine];
}

- (IBAction) scrollLineDown: (id)aSender
{
   [singlePageView scrollDownOneLine];
}

- (IBAction) scrollToTop: (id)aSender
{
   [singlePageView displayContentTop];
}

- (IBAction) scrollToBottom: (id)aSender
{
   [singlePageView displayContentBottom];
}

- (IBAction) scrollLineLeft: (id)aSender
{
   [singlePageView scrollLeftOneLine];
}

- (IBAction) scrollLineRight: (id)aSender
{
   [singlePageView scrollRightOneLine];
}

- (IBAction) scrollToLeftEdge: (id)aSender
{
   [singlePageView displayContentLeft];
}

- (IBAction) scrollToRightEdge: (id)aSender;
{
   [singlePageView displayContentRight];
}

- (IBAction) findText: (id)aSender;
{
   [searchController showView];
}

- (IBAction) goSinglePage: (id)aSender
{
   [scrollView setDocumentView: singlePageView];
   NSAssert([singlePageView paperColor], @"content view does not have a paper color");
   [scrollView setBackgroundColor: [singlePageView paperColor]];
}

- (IBAction) close: (id)aSender
{
   [self close];
}

- (IBAction) abortCurrentAction: (id)aSender;
{
   [searchController hideView];
}

@end

/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation Controller (Private)

- (Document*) myDocument
{
   return (Document*)[self document];
}

- (void) myUpdatePage: (NSNotification*)aNotification
{
   [tools setPage: [[self myDocument] pageIndex]];
   
   id rect = [[aNotification userInfo] objectForKey: kUserInfoKeyPageRect];
   if (rect)
      [singlePageView updateAndScrollToRect: [rect rectValue]];
   else
      [singlePageView update];
}

- (void) myRefreshPage: (NSNotification*)aNotification;
{
   [singlePageView update];
}

- (void) myZoomFactorUpdated: (NSNotification*)aNotification
{
   [tools setZoom: [singlePageView zoom]];
   [singlePageView update];
}

- (void) myToggleResizePolicy: (ResizePolicy)aPolicy
{
   ResizePolicy newPolicy;

   if ([singlePageView resizePolicy] == aPolicy)
   {
      newPolicy = ResizePolicyNone;
   }
   else
   {
      newPolicy = aPolicy;
   }

   [self mySetResizePolicy: newPolicy];
}

- (void) mySetResizePolicy: (ResizePolicy)aPolicy
{
   if ([singlePageView resizePolicy] == aPolicy)
   {
      return;
   }

   [singlePageView setResizePolicy: aPolicy];
   [tools setResizePolicy: [singlePageView resizePolicy]];
   [menuState stateChanged];
}

- (void) mySetupScrollView
{
   NSAssert(scrollView, @"scrollview not set");
   
   // make the scrollview center it's document view
   id docView = [[scrollView documentView] retain];
   NSRect clipViewFrame = [[scrollView contentView] frame];
   NSClipView* newClipView = [[CenteringClipView alloc] initWithFrame: clipViewFrame];
   [newClipView  setBackgroundColor: [NSColor windowBackgroundColor]];
   [scrollView setContentView: newClipView];
   [scrollView setDocumentView: docView];
   [newClipView release];
   [docView release];
   
   [scrollView setHasVerticalScroller: YES];
   [scrollView setHasHorizontalScroller: YES];
   [scrollView setDrawsBackground: YES];
}

- (void) myAddDocumentTools
{
   NSToolbar* toolbar = [[[NSToolbar alloc] 
      initWithIdentifier: @"PDFViewerDocument"] autorelease];

   tools = [[DocumentTools alloc] initWithWindowController: self target: self];
   [toolbar setDelegate: tools];
   [[self window] setToolbar: toolbar];
}

- (void) myCreateSinglePageView
{
   NSSize viewSize = [scrollView contentSize];
   NSRect frame = NSMakeRect(0, 0, viewSize.width, viewSize.height);
   singlePageView = [[SinglePageView alloc] initWithFrame: frame];
}

- (void) mySetInitialWindowSize
{
   NSRect screenFrame = [[NSScreen mainScreen] frame];

#ifndef GNUSTEP
   // Reserve a little space at the top such that the window
   // does not appear "glued" to the menu bar
   screenFrame.size.height = NSHeight(screenFrame) - 30;
#endif

   NSRect winFrame = [self myCalcPreferredFrameInFrame: screenFrame withPDFSize: [singlePageView preferredSize]];

   NSRect contentRect = [NSWindow contentRectForFrameRect: winFrame styleMask: [[self window] styleMask]];

   NSSize availableSize = [self myCalcPDFContentSize: contentRect.size add: NO];
   NSSize usedSize = [singlePageView zoomContentToFit: availableSize];
   // recalc frame with actually used size
   winFrame = [self myCalcPreferredFrameInFrame: screenFrame withPDFSize: usedSize];

   [[self window] setFrame: winFrame display: YES];
}

- (NSRect) myCalcPreferredFrameInFrame: (NSRect)maxFrame withPDFSize: (NSSize)aPDFSize
{
#ifdef GNUSTEP
   // Reserve a little extra space at the top of the screen. This is necessary
   // if GNUstep does not draw the window decorations but the window manager.
   // Otherwise, the window might appear with the titlebar off-screen
   maxFrame.size.height = NSHeight(maxFrame) - 40;
#endif

   NSSize newContentSize = [self myCalcPDFContentSize: aPDFSize add: YES];

   NSRect contentRect = [NSWindow contentRectForFrameRect: [[self window] frame] styleMask: [[self window] styleMask]];
   contentRect.size = newContentSize;

   NSRect newFrame = [NSWindow frameRectForContentRect: contentRect styleMask: [[self window] styleMask]];

   // constrain the computed frame inside the screen dimensions (aFrame)
   // (OSX works fine without, but I guess, with GNUstep, we're better of
   // taking care of this)

   //NSLog(@"NEW FRAME 1: %f @ %f - %f @ %f",
   //      NSMinX(newFrame), NSMinY(newFrame), NSMaxX(newFrame), NSMaxY(newFrame));

   // constrain height
   if (NSMinY(newFrame) < NSMinY(maxFrame))
      newFrame.origin.x = NSMinY(maxFrame);

   if (NSMaxY(newFrame) > NSHeight(maxFrame)) {
      newFrame.origin.y = NSHeight(maxFrame) - NSHeight(newFrame);
      if (NSMinY(newFrame) < NSMinY(maxFrame)) {
         newFrame.origin.y = NSMinY(maxFrame);
         newFrame.size.height = NSHeight(maxFrame);
      }
   }

   // constrain width
   if (NSMinX(newFrame) < NSMinX(maxFrame))
      newFrame.origin.y = NSMinX(maxFrame);

   if (NSMaxX(newFrame) > NSWidth(maxFrame)) {
      newFrame.origin.x = NSWidth(maxFrame) - NSWidth(newFrame);
      if (NSMinX(newFrame) < NSMinX(maxFrame)) {
         newFrame.origin.x = NSMinX(maxFrame);
         newFrame.size.width = NSWidth(maxFrame);
      }
   }

   // if the new frame has any anomalies, return the maximum frame
   // (otherwise, the window may dissapear from the screen)
   if ((NSWidth(newFrame) <= 0) || (NSHeight(newFrame) <= 0))
      return maxFrame;

   //NSLog(@"NEW FRAME 2: %f @ %f - %f @ %f",
   //      NSMinX(newFrame), NSMinY(newFrame), NSMaxX(newFrame), NSMaxY(newFrame));

   return newFrame;
}

/** Add or subtract the size of additional components in the window (tools, scroller)
    to or from a rectangle.  */
- (NSSize) myCalcPDFContentSize: (NSSize)aSize add: (BOOL)addToSize
{
   float factor = (addToSize ? 1 : -1);

   NSSize newSize = aSize;

   newSize.height += NSHeight([[scrollView horizontalScroller] frame]) * factor;
   newSize.width += NSWidth([[scrollView verticalScroller] frame]) * factor;

#ifdef GNUSTEP
   // add a little extra space, otherwise scrollbars appear
   // on GNUstep
   float additionalSpace = 2 * (addToSize ? 1 : -1);
   newSize.width += additionalSpace;
   newSize.height += additionalSpace;
#endif

   return newSize;
}

@end
