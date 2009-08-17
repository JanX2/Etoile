///**********************************************************************************************************************************
///  NSBezierPath-Editing.h
///  DrawKit �2005-2008 Apptree.net
///
///  Created by graham on 08/10/2006.
///
///	 This software is released subject to licensing conditions as detailed in DRAWKIT-LICENSING.TXT, which must accompany this source file. 
///
///**********************************************************************************************************************************

#import <Cocoa/Cocoa.h>


@interface NSBezierPath (DKEditing)

+ (void)				setConstraintAngle:(float) radians;
+ (NSPoint)				colinearPointForPoint:(NSPoint) p centrePoint:(NSPoint) q;
+ (NSPoint)				colinearPointForPoint:(NSPoint) p centrePoint:(NSPoint) q radius:(float) r;
+ (int)					point:(NSPoint) p inNSPointArray:(NSPoint*) array count:(int) count tolerance:(float) t;
+ (void)				colineariseVertex:(NSPoint[3]) inPoints cpA:(NSPoint*) outCPA cpB:(NSPoint*) outCPB;

- (NSBezierPath*)		bezierPathByRemovingTrailingElements:(int) numToRemove;
- (NSBezierPath*)		bezierPathByStrippingRedundantElements;

- (void)				getPathMoveToCount:(int*) mtc lineToCount:(int*) ltc curveToCount:(int*) ctc closePathCount:(int*) cpc;

- (BOOL)				isPathClosed;
- (unsigned)			checksum;

- (BOOL)				subpathContainingElementIsClosed:(int) element;
- (int)					subpathStartingElementForElement:(int) element;
- (int)					subpathEndingElementForElement:(int) element;

- (NSBezierPathElement)	elementTypeForPartcode:(int) pc;
- (BOOL)				isOnPathPartcode:(int) pc;

- (void)				setControlPoint:(NSPoint) p forPartcode:(int) pc;
- (NSPoint)				controlPointForPartcode:(int) pc;

- (int)					partcodeHitByPoint:(NSPoint) p tolerance:(float) t;
- (int)					partcodeHitByPoint:(NSPoint) p tolerance:(float) t startingFromElement:(int) startElement;
- (int)					partcodeForLastPoint;

- (void)				moveControlPointPartcode:(int) pc toPoint:(NSPoint) p colinear:(BOOL) colin coradial:(BOOL) corad constrainAngle:(BOOL) acon;

// adding and deleting points from a path:
// note that all of these methods return a new path since NSBezierPath doesn't support deletion/insertion except by reconstructing a path.

- (NSBezierPath*)		deleteControlPointForPartcode:(int) pc;
- (NSBezierPath*)		insertControlPointAtPoint:(NSPoint) p tolerance:(float) tol type:(int) controlPointType;

- (NSPoint)				nearestPointToPoint:(NSPoint) p tolerance:(float) tol;

// geometry utilities:

- (float)				tangentAtStartOfSubpath:(int) elementIndex;
- (float)				tangentAtEndOfSubpath:(int) elementIndex;

- (int)					elementHitByPoint:(NSPoint) p tolerance:(float) tol tValue:(float*) t;
- (int)					elementHitByPoint:(NSPoint) p tolerance:(float) tol tValue:(float*) t nearestPoint:(NSPoint*) npp;
- (int)					elementBoundsContainsPoint:(NSPoint) p tolerance:(float) tol;

// element bounding boxes - can reduce need to draw entire path when only a part is edited

- (NSRect)				boundingBoxForElement:(int) elementIndex;
- (void)				drawElementsBoundingBoxes;
- (NSSet*)				boundingBoxesForPartcode:(int) pc;
- (NSSet*)				allBoundingBoxes;


@end





/*

This category provides some basic methods for supporting interactive editing of a NSBezierPath object. This can be more tricky
than it looks because control points are often not edited in isolation - they often crosslink to other control points (such as
when two curveto segments are joined and a colinear handle is needed).

These methods allow you to refer to any individual control point in the object using a unique partcode. These methods will
hit detect all control points, giving the partcode, and then get and set that point.

The moveControlPointPartcode:toPoint:colinear: is a high-level call that will handle most editing tasks in a simple to use way. It
optionally maintains colinearity across curve joins, and knows how to maintain closed loops properly.

*/

