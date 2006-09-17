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

#import "Document.h"
#import "Controller.h"
#import "Preferences.h"
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSNotification.h>

NSString* kDocumentPageChangedNotification = @"DocumentPageChangedNotification";
NSString* kDocumentSelectionChangedNotification = @"DocumentSelectionChangedNotification";
NSString* kUserInfoKeyPageRect = @"KeyPageRect";

@interface Document (Private)
- (void) _createRenderer;
@end

@implementation Document

- (id) init
{
   self = [super init];
   if (self)
   {
      pdfdoc = nil;
      page = nil;
      renderer = nil;
      selections = [[NSMutableDictionary alloc] init];
   }

   return self;
}

- (void) dealloc
{
   NSLog(@"dealloc Document");
   [selections release];
   [pdfdoc release];
   [(NSObject*)renderer release];
   [super dealloc];
}

- (NSString*) windowNibName 
{
   return @"Document";
}

- (void) makeWindowControllers
{
   Controller* ctrl = [[Controller alloc] initWithWindowNibName: [self windowNibName]];
   [ctrl autorelease];
   [self addWindowController: ctrl];
}

- (NSData*) dataRepresentationOfType: (NSString*)aType
{
   return nil;
}

- (BOOL) readFromFile: (NSString*)aFileName ofType: (NSString*)aType
{
   BOOL success = YES;
   
   NS_DURING
      pdfdoc = [[PopplerDocument alloc] initWithPath: aFileName];
      [self setPageByIndex: 1];
      [self _createRenderer];
   NS_HANDLER
      success = NO;
      pdfdoc = nil;
   NS_ENDHANDLER

   return success;
}

- (PopplerDocument*) pdfDocument
{
   return pdfdoc;
}

- (int) countPages
{
   return [[self pdfDocument] countPages];
}

- (void) setPageByIndex: (int)aPageIndex
{
   [self setPageByIndex: aPageIndex requestVisibleRect: NSZeroRect];
}

- (void) setPageByIndex: (int)aPageIndex requestVisibleRect: (NSRect)aRect;
{
   NSAssert([self pdfDocument], @"document contains no data");
   
   page = [[self pdfDocument] page: aPageIndex];
   
   NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
   if (!NSEqualRects(aRect, NSZeroRect))
      [userInfo setObject: [NSValue valueWithRect: aRect] forKey: kUserInfoKeyPageRect];

   [[NSNotificationCenter defaultCenter] postNotificationName: kDocumentPageChangedNotification object: self userInfo: userInfo];
}

- (int) pageIndex
{
   NSAssert([self pdfDocument], @"document contains no data");
   return [page index];
}

- (BOOL) nextPage
{
   if ([self pageIndex] >= [self countPages])
   {
      return NO;
   }

   [self setPageByIndex: [self pageIndex] + 1];
   return YES;
}

- (BOOL) previousPage
{
   if ([self pageIndex] <= 1)
   {
      return NO;
   }

   [self setPageByIndex: [self pageIndex] - 1];
   return YES;
}

- (PopplerPage*) page
{
   return page;
}

- (NSSize) pageSize
{
   NSAssert([self page] > 0, @"no page");
   return [[self page] size];
}

- (void) addSelection: (DocumentSelection*)selection;
{
   NSAssert(selection, @"nil selection");
   
   NSNumber* pageKey = [NSNumber numberWithInt: [selection pageIndex]];
   NSMutableArray* pageSelections = [selections objectForKey: pageKey];
   if (!pageSelections) {
      pageSelections = [NSMutableArray array];
      [selections setObject: pageSelections forKey: pageKey];
   }
   [pageSelections addObject: selection];
   
   [[NSNotificationCenter defaultCenter] 
      postNotificationName: kDocumentSelectionChangedNotification
                    object: self];
}

- (void) clearSelections;
{
   [selections removeAllObjects];

   [[NSNotificationCenter defaultCenter]
      postNotificationName: kDocumentSelectionChangedNotification
                    object: self];
}

- (void) jumpToSelection: (DocumentSelection*)selection;
{
   [self setPageByIndex: [selection pageIndex] requestVisibleRect: [selection region]];
}

- (PopplerTextSearch*) newSearch;
{
   return [PopplerTextSearch searchWithDocument: [self pdfDocument]];
}

- (void) drawPageAtPoint: (NSPoint)aPoint zoom: (ZoomFactor*)zoom
{
   NSAssert(renderer, @"no renderer");
   NSAssert([self pdfDocument], @"document contains no data");
   
   [renderer drawPage: [self page]
              atPoint: aPoint
                scale: [zoom asScale]];

   NSArray* pageSelections = [selections objectForKey: [NSNumber numberWithInt: [self pageIndex]]];
   
   if (!pageSelections)
      return;
   
   NSEnumerator* selectionEnum = [pageSelections objectEnumerator];
   DocumentSelection* selection;
   while ((selection = [selectionEnum nextObject]))
      [selection drawSelectionWithZoom: zoom];
}

@end

/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation Document (Private)

- (void) _createRenderer
{
   id<PopplerBufferedRenderer> bufferedRenderer;

   if ([[Preferences sharedPrefs] useCairo] && [PopplerCairoImageRenderer isSupported])
   {
      NSLog(@"use cairo renderering");
      bufferedRenderer =
         [[PopplerCairoImageRenderer alloc] initWithDocument: [self pdfDocument]];
   }
   else
   {
      NSLog(@"use generic splash rendering");
      bufferedRenderer =
         [[PopplerSplashRenderer alloc] initWithDocument: [self pdfDocument]];
   }

   NSAssert(bufferedRenderer, @"no buffered renderer created");

   unsigned long cacheSize = [[Preferences sharedPrefs] pageCacheSize];
   id<PopplerBufferedRenderer> baseRenderer = nil;
   if (cacheSize > 0)
   {
      baseRenderer = [[PopplerCachingRenderer alloc] initWithRenderer: bufferedRenderer];
      [(PopplerCachingRenderer*)baseRenderer setCacheSize: cacheSize];
      [(NSObject*)bufferedRenderer release];
   }
   else
   {
      baseRenderer = bufferedRenderer;
   }
   
   renderer = [[PopplerDirectBufferedRenderer alloc] initWithRenderer: baseRenderer];
   
   [(NSObject*)baseRenderer release];
}

@end

