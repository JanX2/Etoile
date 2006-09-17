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

#import "DocumentSelection.h"

@interface DocumentSelection (Private)
@end

@implementation DocumentSelection

- (id) initWithPageIndex: (int)aPageIndex region: (NSRect)aRegion color: (NSColor*)aColor;
{
   if (![super init])
      return nil;

   pageIndex = aPageIndex;
   region = aRegion;
   color = [aColor retain];

   return self;
}

+ (DocumentSelection*) selectionWithPageIndex: (int)aPageIndex
                                       region: (NSRect)aRegion
                                        color: (NSColor*)aColor;
{
   return [[[self alloc] initWithPageIndex: aPageIndex region: aRegion color: aColor] autorelease];
}

+ (DocumentSelection*) textHitSelectionWithPageIndex: (int)aPageIndex region: (NSRect)aRegion;
{
   return [self selectionWithPageIndex: aPageIndex region: aRegion color: [self textHitSpotColor]];
}

- (void) dealloc
{
   [color release];
   [super dealloc];
}

- (NSColor*) color;
{
   return color;
}

- (NSRect) region;
{
   return region;
}

- (int) pageIndex;
{
   return pageIndex;
}

+ (NSColor*) textHitSpotColor;
{
   return [[NSColor yellowColor] colorWithAlphaComponent: 0.5];
}

- (void) drawSelectionWithZoom: (ZoomFactor*)zoom;
{
   [[self color] set];
   [NSBezierPath fillRect: [zoom translateRect: [self region]]];
}

@end

/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation DocumentSelection (Private)
@end

