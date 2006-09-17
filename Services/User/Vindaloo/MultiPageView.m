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

#import "MultiPageView.h"
#import <PDFKit/PDFImageRep.h>
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSNotification.h>

/**
* Non-Public methods.
 */
@interface MultiPageView (Private)
- (void) _updateFrame;
- (float) _preflightLayout;
- (void) _drawPagesInRect: (NSRect)aRect;
- (float) _findMaxRowHeight: (int)firstPage;
- (void) _rebuildPages;
- (NSSize) _scaledSizeForPage: (int)aPage;
- (void) _pdfPageReadyNotification: (NSNotification*)aNotification;
@end


@implementation MultiPageView

- (id) initWithFrame: (NSRect)aFrame
         scaleFactor: (unsigned)aScaleFactor
{
   self = [super initWithFrame: aFrame];
   if (self)
   {
      pdfdoc = nil;
      background = nil;
      pages = nil;
      [self setVerticalSpace: 10.0];
      [self setHorizontalSpace: 10.0];
      [self setScaleFactor: aScaleFactor];
      [self setBackground: [NSColor whiteColor]];
   }
   return self;
}

- (void) dealloc
{
   [self setDocument: nil];
   [self setBackground: nil];
   [super dealloc];
}

- (void) setDocument: (PDFDocument*)aDocument
{
   [pdfdoc release];
   pdfdoc = [aDocument retain];
   [self _rebuildPages];
   [self _updateFrame];
}

- (PDFDocument*) document
{
   return pdfdoc;
}

- (void) setScaleFactor: (unsigned)aScaleFactor
{
   NSAssert(aScaleFactor > 0, @"zero or negative scale factor");
   
   if (scaleFactor != aScaleFactor)
   {
      scaleFactor = aScaleFactor;
      [self _updateFrame];
   }
}

- (unsigned) scaleFactor
{
   return scaleFactor;
}

- (void) setVerticalSpace: (float)aSpace
{
   NSAssert(aSpace >= 0, @"negative space");
   
   if (vspace != aSpace)
   {
      vspace = aSpace;
      [self _updateFrame];
   }
}

- (float) verticalSpace
{
   return vspace;
}

- (void) setHorizontalSpace: (float)aSpace
{
   NSAssert(aSpace >= 0, @"negative space");

   if (hspace != aSpace)
   {
      hspace = aSpace;
      [self _updateFrame];
   }
}

- (float) horizontalSpace
{
   return hspace;
}

- (void) setBackground: (NSColor*)aColor
{
   [background release];
   background = [aColor retain];
   [self setNeedsDisplay: YES];
}

- (NSColor*) background
{
   return background;
}

- (BOOL) isFlipped
{
   return NO;
}

- (BOOL) isOpaque
{
   return YES;
}

- (void) drawRect: (NSRect)aRect
{
   NSRect contentRect;

   contentRect = NSMakeRect(0,  0, [self frame].size.width, [self frame].size.height);
   
   [[self background] set];
   [NSBezierPath fillRect: contentRect];
   
   if (![self document])
   {
      return;
   }
   
   [self _drawPagesInRect: aRect];
}

@end

/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation MultiPageView (Private)

- (void) _updateFrame
{
   NSRect newFrame;
   float yMax;
   
   if (![self document])
   {
      return;
   }

   // pages may have different sizes, so we do a preflight
   // and see where the pages go
   yMax = [self _preflightLayout];
   // the rect is not considered in preflight mode 
   
   // update the frame rectangle with the new height
   newFrame = [self frame];
   newFrame.size.height = yMax + [self verticalSpace];
   [self setFrame: newFrame];
   
   [self setNeedsDisplay: YES];
}

- (float) _preflightLayout
{
   float xPos;
   float yPos;
   float rowHeight;
   int i;
   
   NSAssert([self document], @"no document");
   
   xPos = [self horizontalSpace];
   yPos = [self verticalSpace];
   rowHeight = 0;
   
   for (i = 1; i <= [[self document] countPages]; i++)
   {
      NSSize pSize = [self _scaledSizeForPage: i];
      
      if ((xPos + pSize.width + [self verticalSpace]) >= NSWidth([self frame]))
      {
         // next row
         xPos = [self horizontalSpace];
         yPos = yPos + rowHeight + [self verticalSpace];
         rowHeight = 0;
      }
      
      if (pSize.height > rowHeight)
      {
         rowHeight = pSize.height;
      }
      
      xPos = xPos + pSize.width + [self horizontalSpace];
   }
   
   // we need to add the space required for the last row
   yPos = yPos + rowHeight;
   
   return yPos;
}

- (void) _drawPagesInRect: (NSRect)aRect
{
   // the view has to be properly sized for this to work
   NSRect pageRect;
   PDFImageRep* imageRep;
   float xPos;
   float yPos;
   float rowHeight;
   int i;
   int pagesDrawn;
   
   if (![self document])
   {
      return;
   }
   
   [[NSColor blackColor] set];

   xPos = [self horizontalSpace];
   yPos = NSHeight([self frame]) - [self verticalSpace];
   rowHeight = [self _findMaxRowHeight: 1];
   pagesDrawn = 0;

   for (i = 1; i <= [[self document] countPages]; i++)
   {
      NSSize pSize = [self _scaledSizeForPage: i];
      
      if ((xPos + pSize.width + [self verticalSpace]) >= NSWidth([self frame]))
      {
         // next row
         xPos = [self horizontalSpace];
         yPos = yPos - rowHeight - [self verticalSpace];
         rowHeight = [self _findMaxRowHeight: i]; // TODO (i + 1)????
      }
      
      //TODO: get row height first and center pages vertically
      pageRect = NSMakeRect(xPos, yPos - pSize.height, pSize.width, pSize.height);
         
      // update image representation
      imageRep = [pages objectAtIndex: (i - 1)];
      [imageRep setResolutionBySize: pSize];
         
      // check if the page is in the rect
      if (NSIntersectsRect(aRect, pageRect))
      {
         [NSBezierPath strokeRect: pageRect];
         [imageRep drawInRect: pageRect];
         pagesDrawn++;
      }
      else
      {
         // release the data hold by the imageRep
         [imageRep passivate];
      }

      xPos = xPos + pSize.width + [self horizontalSpace];
   }
   
   NSLog(@"%d pages drawn", pagesDrawn);
}

- (float) _findMaxRowHeight: (int)firstPage
{
   int i;
   float xPos;
   float rowHeight;

   xPos = [self horizontalSpace];
   rowHeight = 0;

   for (i = firstPage; i <= [[self document] countPages]; i++)
   {
      NSSize pSize = [self _scaledSizeForPage: i];
      
      if (pSize.height > rowHeight)
      {
         rowHeight = pSize.height;
      }
      
      if ((xPos + pSize.width + [self verticalSpace]) >= NSWidth([self frame]))
      {
         // row completed
         break;
      }

      xPos = xPos + pSize.width + [self horizontalSpace];
   }
   
   return rowHeight;
}

- (void) _rebuildPages
{
   int i;
   PDFImageRep* imageRep;
   
   // passivate pages (cancel renderings in progress and free memory)
   for (i = 0; i < [pages count]; i++)
   {
      [[pages objectAtIndex: i] passivate];
   }
   [pages release];
   [[NSNotificationCenter defaultCenter] removeObserver: self];
   
   if (![self document])
   {
      pages = nil;
      return;
   }
   
   pages = [[NSMutableArray alloc] init];
   
   for (i = 1; i <= [[self document] countPages]; i++)
   {
      imageRep = [[PDFImageRep alloc] initWithDocument: [self document]
                                    renderInBackground: YES];
      [imageRep setPageNum: i];
      [pages addObject: imageRep];
      [imageRep release];
      [[NSNotificationCenter defaultCenter]
         addObserver: self
            selector: @selector(_pdfPageReadyNotification:)
                name: kPDFPageReadyNotification
              object: imageRep];
   }
}

- (NSSize) _scaledSizeForPage: (int)aPage
{
   float m;

   NSAssert([self document], @"_scaledSizeForPage called without document");
   
   m = (float)[self scaleFactor] / 100.0;
   return NSMakeSize([[self document] paperSize: aPage].width * m,
                     [[self document] paperSize: aPage].height * m);
}

- (void) _pdfPageReadyNotification: (NSNotification*)aNotification
{
   [self setNeedsDisplay: YES];
   // TODO: only if the page is visible
}

@end
