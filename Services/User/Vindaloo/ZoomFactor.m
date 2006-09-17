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

#import "ZoomFactor.h"


@implementation ZoomFactor

- (id) initWithValue: (float)aValue
{
   if (aValue <= 0.0)
   {
      [NSException raise: NSInvalidArgumentException
                  format: @"negative zoom factor %f", aValue];
   }

   self = [super init];
   if (self)
   {
      value = aValue;
   }
   return self;
}

- (id) init
{
   return [self initWithValue: 100.0];
}

+ (ZoomFactor*) factorWithValue: (float)aValue
{
   return [[[ZoomFactor alloc] initWithValue: aValue] autorelease];
}

- (float) value
{
   return value;
}

- (NSComparisonResult) compare: (ZoomFactor*)aFactor
{
   if (!aFactor)
   {
      return NSOrderedDescending;
   }
   
   if ([self value] < [aFactor value])
   {
      return NSOrderedAscending;
   }
   else if ([self value] > [aFactor value])
   {
      return NSOrderedDescending;
   }
   
   return NSOrderedSame;
}

- (float) asScale
{
   return [self value] / 100;
}

- (float) translate: (float)aValue
{
   return aValue * [self asScale];
}

- (NSSize) translateSize: (NSSize)aSize
{
   return NSMakeSize([self translate: aSize.width],
                     [self translate: aSize.height]);
}

- (NSRect) translateRect: (NSRect)aRect
{
   return NSMakeRect([self translate: NSMinX(aRect)],
                     [self translate: NSMinY(aRect)],
                     [self translate: NSWidth(aRect)],
                     [self translate: NSHeight(aRect)]);
}

- (NSRect) normalizeRect: (NSRect)aRect
{
   return NSMakeRect(NSMinX(aRect) / [self asScale],
                     NSMinY(aRect) / [self asScale],
                     NSWidth(aRect) / [self asScale],
                     NSHeight(aRect) / [self asScale]);
}

@end

/* ----------------------------------------------------- */
/*  Class ZoomFactorRange                                */
/* ----------------------------------------------------- */

/**
 * Non-Public methods.
 */
@interface ZoomFactorRange (Private)
- (unsigned) _indexForFactor: (ZoomFactor*)aFactor;
@end


@implementation ZoomFactorRange

- (id) initWithFactors: (NSArray*)aFactors actualFactor: (ZoomFactor*)aFactor
{
   NSAssert(aFactors && ([aFactors count] > 0), @"no zoom factors");

   self = [super init];
   if (self)
   {
      delegate = nil;
      actual = nil;
      factors = [[aFactors sortedArrayUsingSelector: @selector(compare:)] retain];
      [self setFactor: aFactor];
   }
   
   return self;
}

- (id) initWithFactors: (NSArray*)aFactors
{
   return [self initWithFactors: aFactors
                   actualFactor: [ZoomFactor factorWithValue: 100.0]];
}

- (void) dealloc
{
   [actual release];
   [factors release];
   [super dealloc];
}

- (void) setDelegate: (id)aDelegate
{
   delegate = aDelegate;
}

- (void) setFactor: (ZoomFactor*)aFactor
{
   NSAssert(aFactor, @"nil factor");

   ZoomFactor* old = [actual retain];
   [actual release];
   
   // align factor to upper/lower bound
   if ([aFactor value] < [[self minFactor] value])
   {
      actual = [[self minFactor] retain];
   }
   else if ([aFactor value] > [[self maxFactor] value])
   {
      actual = [[self maxFactor] retain];
   }
   else
   {
      actual = [aFactor retain];
   }

   [delegate zoomFactorChanged: self withOldFactor: old];
   [old release];
}

- (ZoomFactor*) factor
{
   return actual;
}

- (BOOL) isMin
{
   return [[self factor] value] <= [[self minFactor] value];
}

- (BOOL) isMax
{
   return [[self factor] value] >= [[self maxFactor] value];
}

- (void) increment
{
   unsigned factorIdx = [self _indexForFactor: [self factor]];
   unsigned maxIdx = [factors count] - 1;
   unsigned nextIdx = (factorIdx == maxIdx ? maxIdx : factorIdx + 1);
   [self setFactor: [factors objectAtIndex: nextIdx]];
}

- (void) decrement
{
   unsigned factorIdx = [self _indexForFactor: [self factor]];
   unsigned nextIdx = (factorIdx == 0 ? 0 : factorIdx - 1);
   [self setFactor: [factors objectAtIndex: nextIdx]];
}

- (ZoomFactor*) minFactor
{
   return [factors objectAtIndex: 0];
}

- (ZoomFactor*) maxFactor
{
   unsigned last = [factors count] - 1;
   return [factors objectAtIndex: last];
}

@end


/* ----------------------------------------------------- */
/*  Category Private of ZoomFactorRange                  */
/* ----------------------------------------------------- */

@implementation ZoomFactorRange (Private)

- (unsigned) _indexForFactor: (ZoomFactor*)aFactor
{
   // find the factor in factors with the lowest distance to
   // aFactor and return it's index (factors is sorted in
   // ascending order!)
   
   // boundaries
   if ([aFactor value] <= [[self minFactor] value])
   {
      return 0;
   }
   else if ([aFactor value] >= [[self maxFactor] value])
   {
      return [factors count] - 1;
   }

   // find the indices of two factors s.t. 
   // factors[iLower] <= aFactor <= factors[iUpper]
   unsigned iLower = 0;
   unsigned iUpper = 0;
   unsigned i;
   for (i = 0; i < ([factors count] - 1); i++)
   {
      // factors is sorted in ascending order, so we can
      // simply increment i as long as factors[i] > aFactor
      if ([aFactor value] <= [(ZoomFactor*)[factors objectAtIndex: i] value])
      {
         iLower = i - 1;
         iUpper = i;
         break;
      }
   }
   
   NSAssert(i < ([factors count] - 1), @"_indexForFactor: should not happen");
   
   // from iLower, iUpper select the index that points to
   // the factor with the lowest (absolute) distance to aFactor
   float d1 = [aFactor value] - [(ZoomFactor*)[factors objectAtIndex: iLower] value];
   float d2 = [(ZoomFactor*)[factors objectAtIndex: iUpper] value] - [aFactor value];

   return (d1 <= d2 ? iLower : iUpper);
}

@end
