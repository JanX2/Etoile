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
#import <PopplerKit/PopplerDocument.h>
#import <PopplerKit/PopplerTextHit.h>

/**
 * I help you performing a textual search through the pages
 * of a document.
 */
@interface PopplerTextSearch : NSObject {
   PopplerDocument* document;
   NSString* text;
   NSMutableArray* hits;
   id delegate;
   BOOL running;
   BOOL stopRequested;
   unsigned currentPageIndex;
   unsigned startPageIndex;
   unsigned endPageIndex;
   unsigned searchedPagesCount;
}

- (id) initWithDocument: (PopplerDocument*)aDocument;
+ (PopplerTextSearch*) searchWithDocument: (PopplerDocument*)aDocument;

- (NSArray*) searchFor: (NSString*)aTextStrig
                  from: (unsigned)aStartPageIndex
                    to: (unsigned)anEndPageIndex;
                    
- (NSArray*) searchFor: (NSString*)aTextString
                  from: (unsigned)aStartPageIndex;
                  
- (void) searchFor: (NSString*)aTextString
              from: (unsigned)aStartPageIndex
                to: (unsigned)anEndPageIndex
          delegate: (id)aDelegate;
          
- (void) searchFor: (NSString*)aTextString
              from: (unsigned)aStartPageIndex
          delegate: (id)aDelegate;

- (NSArray*) hits;

- (void) stop;
- (void) proceed;

- (BOOL) running;
- (BOOL) stopped;

@end

/**
 * Informal protocol for delegate objects of a PopplerTextSearch.
 */
@interface NSObject (PopplerTextSearchDelegate)
- (void) searchWillStart: (PopplerTextSearch*)search;
- (void) search: (PopplerTextSearch*)search didFoundHit: (PopplerTextHit*)hit;
- (void) search: (PopplerTextSearch*)search didCompletePage: (PopplerPage*)page;
- (void) searchDidFinish: (PopplerTextSearch*)search;
@end

