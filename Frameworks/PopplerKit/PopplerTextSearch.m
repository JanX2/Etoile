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

#import "PopplerTextSearch.h"
#import "PopplerPage.h"

@interface PopplerTextSearch (Private)
- (void) myProceedSearch;
- (void) mySearchPage: (PopplerPage*)page;
- (unsigned) myPageCount;
- (void) myNotifyWillStart;
- (void) myNotifyDidFoundHit: (PopplerTextHit*)hit;
- (void) myNotifyDidCompletePage: (PopplerPage*)page;
- (void) myNotifyDidFinish;
@end

@implementation PopplerTextSearch

- (id) initWithDocument: (PopplerDocument*)aDocument;
{
   NSAssert(aDocument, @"nil document");
   
   if (![super init])
      return nil;

   document = [aDocument retain];
   text = nil;
   running = NO;
   stopRequested = NO;
   currentPageIndex = 0;
   startPageIndex = 0;
   endPageIndex = 0;
   searchedPagesCount = 0;
   delegate = nil;
   hits = nil;

   return self;
}

- (void) dealloc
{
   [hits release];
   [document release];
   [text release];
   [super dealloc];
}

+ (PopplerTextSearch*) searchWithDocument: (PopplerDocument*)aDocument;
{
   return [[[self alloc] initWithDocument: aDocument] autorelease];
}

- (NSArray*) searchFor: (NSString*)aTextString
                  from: (unsigned)aStartPageIndex
                    to: (unsigned)anEndPageIndex;
{
   [self searchFor: aTextString from: aStartPageIndex to: anEndPageIndex delegate: nil];
   return [self hits];
}

- (NSArray*) searchFor: (NSString*)aTextString
                  from: (unsigned)aStartPageIndex;
{
   return [self searchFor: aTextString from: aStartPageIndex to: [document previousPageIndex: aStartPageIndex]];
}

- (void) searchFor: (NSString*)aTextString
              from: (unsigned)aStartPageIndex
                to: (unsigned)anEndPageIndex
          delegate: (id)aDelegate;
{
   if ([self running])
      [NSException raise: NSGenericException format: @"search already running"];

   if ((aStartPageIndex < 1) || (aStartPageIndex > [document countPages]))
      [NSException raise: NSInvalidArgumentException format: @"start page index out of range: %d", aStartPageIndex];

   if ((anEndPageIndex < 1) || (anEndPageIndex > [document countPages]))
      [NSException raise: NSInvalidArgumentException format: @"end page index out of range: %d", anEndPageIndex];
   
   [text release];
   text = [aTextString copy];

   startPageIndex = aStartPageIndex;
   endPageIndex = anEndPageIndex;
   currentPageIndex = aStartPageIndex;
   searchedPagesCount = 0;
   delegate = aDelegate;

   [hits release];
   hits = [[NSMutableArray alloc] init];

   [self myNotifyWillStart];
   [self myProceedSearch];
   [self myNotifyDidFinish];
}

- (void) searchFor: (NSString*)aTextString
              from: (unsigned)aStartPageIndex
          delegate: (id)aDelegate;
{
   [self searchFor: aTextString from: aStartPageIndex to: [document previousPageIndex: aStartPageIndex] delegate: aDelegate];
}

- (NSArray*) hits
{
   return [NSArray arrayWithArray: hits];
}

- (void) stop;
{
   stopRequested = YES;
}

- (void) proceed;
{
   [self myProceedSearch];
}

- (BOOL) stopped;
{
   return ![self running];
}

- (BOOL) running;
{
   return running;
}

@end

/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation PopplerTextSearch (Private)

- (void) myProceedSearch;
{
   NSAssert([self stopped], @"cannot proceed a running search");

   running = YES;
   stopRequested = NO;

   while (searchedPagesCount < [self myPageCount]) {
      PopplerPage* page = [document page: currentPageIndex];
      [self mySearchPage: page];
      currentPageIndex = [document nextPageIndex: currentPageIndex];
      searchedPagesCount++;
   }
   
   running = NO;
}

- (void) mySearchPage: (PopplerPage*)page;
{
   NSAssert(page, @"nil page");
   
   if (stopRequested)
      return;
   
   NSEnumerator* e = [[page findText: text] objectEnumerator];
   PopplerTextHit* hit;
   while ((hit = [e nextObject])) {
      if (stopRequested)
         return;
      [hits addObject: hit];
      [self myNotifyDidFoundHit: hit];
   }

   [self myNotifyDidCompletePage: page];
}

- (unsigned) myPageCount;
{
   if (endPageIndex >= startPageIndex)
      return (endPageIndex - startPageIndex) + 1;
   
   unsigned pagesToEnd = [document countPages] - startPageIndex + 1;
   return pagesToEnd + endPageIndex;
}

- (void) myNotifyWillStart;
{
   if (delegate && [delegate respondsToSelector: @selector(searchWillStart:)])
      [delegate searchWillStart: self];
}

- (void) myNotifyDidFoundHit: (PopplerTextHit*)hit
{
   if (delegate && [delegate respondsToSelector: @selector(search:didFoundHit:)])
      [delegate search: self didFoundHit: hit];
}

- (void) myNotifyDidCompletePage: (PopplerPage*)page;
{
   if (delegate && [delegate respondsToSelector: @selector(search:didCompletePage:)])
      [delegate search: self didCompletePage: page];
}

- (void) myNotifyDidFinish;
{
   if (delegate && [delegate respondsToSelector: @selector(searchDidFinish:)])
      [delegate searchDidFinish: self];
}

@end

