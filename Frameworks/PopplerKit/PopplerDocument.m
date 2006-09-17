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

#import "PopplerDocument.h"
#import "PopplerPage.h"
#import "PopplerFontManager.h"
#import "PopplerKitFunctions.h"
#import "CountingRef.h"
#import <Foundation/NSException.h>

#include "bindings/poppler_document.h"


NSString* PopplerException = @"PopplerException";


@interface PopplerDocumentRefDelegate : NSObject
+ (PopplerDocumentRefDelegate*) delegate;
@end


@interface PopplerDocument (Private)
- (NSArray*) _loadPages: (void*)aDocument;
@end


@implementation PopplerDocument

+ (void) initialize
{
   static BOOL done = NO;
   if (!done)
   {
      NSAssert(PopplerKitInit(), @"PopplerKitInit failed");
      done = YES;
   }
}

- (id) initWithPath: (NSString*)aPath
{
   if (!aPath)
   {
      [NSException raise: NSInvalidArgumentException format: @"nil path"];
   }

   self = [super init];
   if (self)
   {
      poppler_doc = nil;
      
      void* poppler_doc_ptr = poppler_document_create_with_path([aPath cString]);
      NSAssert(poppler_doc_ptr, @"poppler_document_create_with_path returned NULL");
      
      // is the dokument ok?
      if (!poppler_document_is_ok(poppler_doc_ptr))
      {
         int err = poppler_document_get_err_code(poppler_doc_ptr);
         poppler_document_destroy(poppler_doc_ptr);
         [self dealloc];
         [NSException raise: PopplerException
                     format: @"error opening document (err=%d)", err];
      }
      
      poppler_doc = [[CountingRef alloc] initWithPtr: poppler_doc_ptr
                                            delegate: [PopplerDocumentRefDelegate delegate]];

      pages = [[NSArray alloc] initWithArray: [self _loadPages: poppler_doc_ptr]];
   }

   return self;
}

- (void) dealloc
{
   [pages release];
   [(NSObject*)poppler_doc release];
   [super dealloc];
}


+ (PopplerDocument*) documentWithPath: (NSString*)aPath
{
   return [[[self alloc] initWithPath: aPath] autorelease];
}

- (unsigned) countPages
{
   return poppler_document_count_pages([poppler_doc ptr]);
}

- (PopplerPage*) page: (unsigned)index;
{
   if ((index <= 0) || (index > [self countPages]))
      [NSException raise: NSInvalidArgumentException
                  format: @"page index %d is out of range", index];

   return [pages objectAtIndex: index - 1];
}

- (unsigned) nextPageIndex: (unsigned)index;
{
   if (index == [self countPages])
      return 1;
   
   return index + 1;
}

- (unsigned) previousPageIndex: (unsigned)index;
{
   if (index == 1)
      return [self countPages];
   
   return index - 1;
}

- (void*) poppler_object
{
   return [poppler_doc ptr];
}

@end


/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation PopplerDocument (Private)

- (NSArray*) _loadPages: (void*)aDocument
{
   NSMutableArray* result = [NSMutableArray arrayWithCapacity: [self countPages]];
   
   int i;
   for (i = 1; i <= [self countPages]; i++)
   {
      PopplerPage* page = [[PopplerPage alloc] initWithDocument: self index: i];
      NSAssert(page, @"page creation failed");
      [result addObject: page];
      [page release];
   }
   
   return result;
}

@end

/* ----------------------------------------------------- */
/*  Class PopplerDocumentRefDelegate                     */
/* ----------------------------------------------------- */

@implementation PopplerDocumentRefDelegate

+ (PopplerDocumentRefDelegate*) delegate
{
   return [[[self alloc] init] autorelease];
}

- (void) freePtrForReference: (CountingRef*)aReference
{
   if (![aReference isNULL])
   {
      poppler_document_destroy([aReference ptr]);
   }
}

@end
