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

#import "PopplerPage.h"
#import "PopplerDocument.h"
#import "PopplerTextHit.h"
#import "NSObject+PopplerObject.h"
#import "NSString+PopplerKitAdditions.h"
#import "PopplerKitFunctions.h"

#include "bindings/poppler_page.h"
#include "bindings/poppler_text.h"

@interface PopplerPage (Private)
@end

@implementation PopplerPage

- (id) initWithDocument: (PopplerDocument*)aDocument index: (unsigned)anIndex
{
   NSAssert(aDocument, @"no document");
   NSAssert(anIndex > 0 && anIndex <= [aDocument countPages], @"invalid page index");
   
   if (![super init])
      return nil;
   
   index = anIndex;
   document = aDocument;
   poppler_page = poppler_page_create([aDocument poppler_object], anIndex);
   NSAssert(poppler_page, @"poppler_page_create returned NULL");

   return self;
}

- (void) dealloc
{
   poppler_page_destroy(poppler_page);
   [super dealloc];
}

- (unsigned) index
{
   return index;
}

- (NSSize) size
{
   double width;
   double height;
   
   switch ([self orientation])
   {
      case POPPLER_PAGE_ORIENTATION_PORTRAIT:
      case POPPLER_PAGE_ORIENTATION_UPSIDEDOWN: {
         width = poppler_page_get_width(poppler_page);
         height = poppler_page_get_height(poppler_page);
         break;
      }
      case POPPLER_PAGE_ORIENTATION_LANDSCAPE:
      case POPPLER_PAGE_ORIENTATION_SEASCAPE: {
         width = poppler_page_get_height(poppler_page);
         height = poppler_page_get_width(poppler_page);
         break;
      }
      default: {
         width = height = 0;
         NSAssert(NO, @"unreachable code");
      }
   }

   return NSMakeSize((float)width, (float)height);
}

- (int) rotate
{
   return poppler_page_get_rotate(poppler_page);
}

- (PopplerPageOrientation) orientation
{
   int rotate = poppler_page_get_rotate(poppler_page);
   NSAssert(rotate >= 0, @"got negative rotation factor"); 
   
   PopplerPageOrientation orientation = POPPLER_PAGE_ORIENTATION_UNSET;
   switch (rotate)
   {
      case 90:
         orientation = POPPLER_PAGE_ORIENTATION_LANDSCAPE; break;
      case 180:
         orientation = POPPLER_PAGE_ORIENTATION_UPSIDEDOWN; break;
      case 270:
         orientation = POPPLER_PAGE_ORIENTATION_SEASCAPE; break;
      default:
         orientation = POPPLER_PAGE_ORIENTATION_PORTRAIT;
   }

   return orientation;
}

- (NSArray*) findText: (NSString*)aTextString;
{
   NSMutableArray* hits = [NSMutableArray array];

   if (!aTextString || [aTextString length] == 0)
      return hits;
   
   void* textDevice = poppler_text_device_create(YES, NO, NO);
   
   poppler_text_display_page(textDevice, poppler_page, [[self document] poppler_object],
                             PopplerKitDPI().width, PopplerKitDPI().height, [self rotate],
                             YES);
   
   unsigned utf32Length = 0;
   unsigned int* utf32String = [aTextString getUTF32String: &utf32Length];

   double height = poppler_page_get_height(poppler_page);

   double xMin, yMin, xMax, yMax = 0;
   while(poppler_text_find(textDevice, utf32String, utf32Length,
                           NO, YES, // startAtTop, stopAtBottom
                           YES, NO, // startAtLast, stopAtLast
                           &xMin, &yMin, &xMax, &yMax)) {
      // coordinates as returned by poppler are upside down!
      NSRect hitArea = NSMakeRect(xMin, (height - yMax), (xMax - xMin), (yMax - yMin));
      PopplerTextHit* hit = [[PopplerTextHit alloc] initWithPage: self hitArea: hitArea context: nil];
      [hits addObject: hit];
      [hit release];
   }

   poppler_text_device_destroy(textDevice);
   NSZoneFree(NSDefaultMallocZone(), utf32String);
   
   return hits;
}

- (PopplerDocument*) document
{
   return document;
}

- (void*) poppler_object
{
   return poppler_page;
}

@end

/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation PopplerPage (Private)
@end
