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

#import "PopplerTextHit.h"
#import "PopplerPage.h"

@interface PopplerTextHit (Private)
@end

@implementation PopplerTextHit

- (id) initWithPage: (PopplerPage*)aPage
            hitArea: (NSRect)aRectangle
            context: (NSString*)aTextString;
{
   NSAssert(aPage, @"nil page");
   
   if (![super init])
      return nil;

   page = [aPage retain];
   hitArea = aRectangle;
   context = [aTextString copy];
   
   return self;
}

- (void) dealloc
{
   [page release];
   [context release];
   [super dealloc];
}

- (PopplerPage*) page;
{
   return page;
}

- (NSRect) hitArea;
{
   return hitArea;
}

- (NSString*) context;
{
   return context;
}

- (NSString*) description
{
   return [NSString stringWithFormat: @"hit at page %d, %f @ %f  %f x %f",
      [[self page] index], NSMinX([self hitArea]), NSMinY([self hitArea]),
      NSWidth([self hitArea]), NSHeight([self hitArea])];
}

@end

/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation PopplerTextHit (Private)
@end

