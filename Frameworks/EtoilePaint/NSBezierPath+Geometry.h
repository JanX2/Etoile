///**********************************************************************************************************************************
///  NSBezierPath-Geometry.h
///  DrawKit ©2005-2008 Apptree.net
///
///  Created by graham on 22/10/2006.
///
///	 This software is released subject to licensing conditions as detailed in DRAWKIT-LICENSING.TXT, which must accompany this source file. 
///
///**********************************************************************************************************************************

#import <Cocoa/Cocoa.h>


@interface NSBezierPath (Geometry)

// simple transformations

- (NSBezierPath*)		scaledPath:(float) scale;
- (NSBezierPath*)		scaledPath:(float) scale aboutPoint:(NSPoint) cp;
- (NSBezierPath*)		rotatedPath:(float) angle;
- (NSBezierPath*)		rotatedPath:(float) angle aboutPoint:(NSPoint) cp;
- (NSBezierPath*)		insetPathBy:(float) amount;
- (NSBezierPath*)		horizontallyFlippedPathAboutPoint:(NSPoint) cp;
- (NSBezierPath*)		verticallyFlippedPathAboutPoint:(NSPoint) cp;
- (NSBezierPath*)		horizontallyFlippedPath;
- (NSBezierPath*)		verticallyFlippedPath;

- (NSPoint)				centreOfBounds;
- (float)				minimumCornerAngle;

// iterating over a path using a iteration delegate:

- (NSBezierPath*)		bezierPathByIteratingWithDelegate:(id) delegate contextInfo:(void*) contextInfo;

- (NSBezierPath*)		paralleloidPathWithOffset:(float) delta;
- (NSBezierPath*)		paralleloidPathWithOffset2:(float) delta;
- (NSBezierPath*)		paralleloidPathWithOffset22:(float) delta;
- (NSBezierPath*)		offsetPathWithStartingOffset:(float) delta1 endingOffset:(float) delta2;
- (NSBezierPath*)		offsetPathWithStartingOffset2:(float) delta1 endingOffset:(float) delta2;

// interpolating flattened paths:

- (NSBezierPath*)		bezierPathByInterpolatingPath:(float) amount;

// calculating a fillet

- (NSBezierPath*)		filletPathForVertex:(NSPoint[]) vp filletSize:(float) fs;

// roughening and randomising paths

- (NSBezierPath*)		bezierPathByRandomisingPoints:(float) maxAmount;
#if 0
- (NSBezierPath*)		bezierPathWithRoughenedStrokeOutline:(float) amount;
#endif
- (NSBezierPath*)		bezierPathWithFragmentedLineSegments:(float) flatness;

// zig-zags and waves

- (NSBezierPath*)		bezierPathWithZig:(float) zig zag:(float) zag;
- (NSBezierPath*)		bezierPathWithWavelength:(float) lambda amplitude:(float) amp spread:(float) spread;

// getting the outline of a stroked path:
#if 0
- (NSBezierPath*)		strokedPath;
- (NSBezierPath*)		strokedPathWithStrokeWidth:(float) width;
#endif
// breaking a path apart:

- (NSArray*)			subPaths;
- (int)					countSubPaths;

// converting to and from Core Graphics paths

#if 0
- (CGPathRef)			newQuartzPath;
- (CGMutablePathRef)	newMutableQuartzPath;
- (CGContextRef)		setQuartzPath;
- (void)				setQuartzPathInContext:(CGContextRef) context isNewPath:(BOOL) np;

+ (NSBezierPath*)		bezierPathWithCGPath:(CGPathRef) path;
+ (NSBezierPath*)		bezierPathWithPathFromContext:(CGContextRef) context;
#endif
- (NSPoint)				pointOnPathAtLength:(float) length slope:(float*) slope;
- (float)				slopeStartingPath;
- (float)				distanceFromStartOfPathAtPoint:(NSPoint) p tolerance:(float) tol;

- (int)					pointWithinPathRegion:(NSPoint) p;


// clipping utilities:
#if 0
- (void)				addInverseClip;
#endif
// path trimming

- (float)				lengthOfElement:(int) i;
- (float)				lengthOfPathFromElement:(int) startElement toElement:(int) endElement;

- (NSPoint)				firstPoint;
- (NSPoint)				lastPoint;

// trimming utilities - modified source originally from A J Houghton, see copyright notice below

- (NSBezierPath*)		bezierPathByTrimmingToLength:(float) trimLength;
- (NSBezierPath*)		bezierPathByTrimmingToLength:(float) trimLength withMaximumError:(float) maxError;

- (NSBezierPath*)		bezierPathByTrimmingFromLength:(float) trimLength;
- (NSBezierPath*)		bezierPathByTrimmingFromLength:(float) trimLength withMaximumError:(float) maxError;

- (NSBezierPath*)		bezierPathByTrimmingFromBothEnds:(float) trimLength;
- (NSBezierPath*)		bezierPathByTrimmingFromBothEnds:(float) trimLength withMaximumError:(float) maxError;

- (NSBezierPath*)		bezierPathByTrimmingFromCentre:(float) trimLength;
- (NSBezierPath*)		bezierPathByTrimmingFromCentre:(float) trimLength withMaximumError:(float) maxError;

- (NSBezierPath*)		bezierPathByTrimmingFromLength:(float) startLength toLength:(float) newLength;
- (NSBezierPath*)		bezierPathByTrimmingFromLength:(float) startLength toLength:(float) newLength withMaximumError:(float) maxError;

- (NSBezierPath*)		bezierPathWithArrowHeadForStartOfLength:(float) length angle:(float) angle closingPath:(BOOL) closeit;
- (NSBezierPath*)		bezierPathWithArrowHeadForEndOfLength:(float)length angle:(float) angle closingPath:(BOOL) closeit;

- (void)				appendBezierPathRemovingInitialMoveToPoint:(NSBezierPath*) path;

- (float)				length;
- (float)				lengthWithMaximumError:(float) maxError;

@end



// informal protocol for iterating over the elements in a bezier path using bezierPathByIteratingWithDelegate:contextInfo:

@interface NSObject (BezierElementIterationDelegate)

- (void)				path:(NSBezierPath*) path			// the new path that the delegate can build or modify from the information given
						elementIndex:(int) element			// the element index 
						type:(NSBezierPathElement) type		// the element type
						points:(NSPoint*) p					// list of associated points 0 = next point, 1 = cp1, 2 = cp2 (for curves), 3 = last point on subpath
						subPathIndex:(int) spi				// which subpath this is
						subPathClosed:(BOOL) spClosed		// is the subpath closed?
						contextInfo:(void*) contextInfo;	// the context info


@end

// undocumented Core Graphics:
#if 0
extern CGPathRef	CGContextCopyPath( CGContextRef context );
#endif

/*
 * Bezier path utility category (trimming)
 *
 * (c) 2004 Alastair J. Houghton
 * All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   1. Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 *
 *   2. Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 *
 *   3. The name of the author of this software may not be used to endorse
 *      or promote products derived from the software without specific prior
 *      written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER "AS IS" AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT OWNER BE LIABLE FOR ANY DIRECT, INDIRECT,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */



