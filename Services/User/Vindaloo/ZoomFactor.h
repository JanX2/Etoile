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

/**
 * Maintains the ZoomFactor for views. The factor is given
 * in percent.
 */
@interface ZoomFactor : NSObject
{
   float value;
}

/** Designated initializer.  */
- (id) initWithValue: (float)aValue;
/** Init with 100%  */
- (id) init;

+ (ZoomFactor*) factorWithValue: (float)aValue;

- (float) value;

- (float) asScale;

- (float) translate: (float)aValue;
- (NSSize) translateSize: (NSSize)aSize;
- (NSRect) translateRect: (NSRect)aRect;

- (NSRect) normalizeRect: (NSRect)aRect;

@end


/**
 * Maintains a range of ZoomFactors.
 */
@interface ZoomFactorRange : NSObject
{
   ZoomFactor*  actual;
   id           delegate;
   NSArray*     factors;
}

/** Designated initializer.  */
- (id) initWithFactors: (NSArray*)aFactors actualFactor: (ZoomFactor*)aFactor;
/** Initialize with an actual factor of 100%.  */
- (id) initWithFactors: (NSArray*)aFactors; 

- (ZoomFactor*) factor;
- (void) setFactor: (ZoomFactor*)aFactor;

- (void) setDelegate: (id)aDelegate;

- (BOOL) isMin;
- (BOOL) isMax;

- (void) increment;
- (void) decrement;

- (ZoomFactor*) minFactor;
- (ZoomFactor*) maxFactor;

@end


/**
 * Informal protocol for ZoomFactorRange delegate objects.
 */
@interface NSObject (ZoomFactorRangeDelegate)
- (void) zoomFactorChanged: (ZoomFactorRange*)aRange
             withOldFactor: (ZoomFactor*)anOldFactor;
@end

