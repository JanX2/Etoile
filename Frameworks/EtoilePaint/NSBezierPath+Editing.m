///**********************************************************************************************************************************
///  NSBezierPath-Editing.m
///  DrawKit ©2005-2008 Apptree.net
///
///  Created by graham on 08/10/2006.
///
///	 This software is released subject to licensing conditions as detailed in DRAWKIT-LICENSING.TXT, which must accompany this source file. 
///
///**********************************************************************************************************************************

#import "NSBezierPath+Editing.h"

#import "NSBezierPath+Geometry.h"
#import "DKGeometryUtilities.h"
#import "DKDrawKitMacros.h"

#include <math.h>

static float sAngleConstraint = 0.261799387799;	// 15¡


// simple partcode cracking utils:

static inline int		arrayIndexForPartcode( const int pc );
static inline int		elementIndexForPartcode( const int pc );
static inline int              partcodeForElement( const int element );
static inline int              partcodeForElementControlPoint( const int element, const int controlPointIndex );


@implementation NSBezierPath (DKEditing)

+ (void)				setConstraintAngle:(float) radians
{
	sAngleConstraint = radians;
}


+ (NSPoint)		colinearPointForPoint:(NSPoint) p centrePoint:(NSPoint) q
{
	// returns the point opposite p from q in a straight line. The point p has the same radius as p-q.

	float dx, dy;
	
	dx = p.x - q.x;
	dy = p.y - q.y;
	
	return NSMakePoint( q.x - dx, q.y - dy );
}


+ (NSPoint)		colinearPointForPoint:(NSPoint) p centrePoint:(NSPoint) q radius:(float) r
{
	// returns the point opposite p from q at radius r in a straight line.
	
	float	a = atan2f( p.y - q.y, p.x - q.x ) + pi;
	return NSMakePoint( q.x + ( r * cosf( a )), q.y + ( r * sinf( a )));
}


+ (int)			point:(NSPoint) p inNSPointArray:(NSPoint*) array count:(int) count tolerance:(float) t
{
	// test the point <p> against a list of points <array>,<count> using the tolerance <t>. Returns the index of
	// the point in the array "hit" by p, or NSNotFound if not hit.
	
	int		i;
	NSRect	r;
	
	r.size = NSMakeSize( t, t );
	
	for( i = 0; i < count; ++i )
	{
		r.origin = array[i];
		r.origin.x -= ( 0.5f * t );
		r.origin.y -= ( 0.5f * t );
		
		if ( NSPointInRect( p, r ))
			return i;
	}

	return NSNotFound;
}


+ (void)				colineariseVertex:(NSPoint[3]) inPoints cpA:(NSPoint*) outCPA cpB:(NSPoint*) outCPB
{
	// given three points passed in as an array, this modifies the two outer points to lie in a straight line through the middle
	// point. The resulting slope of this line is normal to the bisection of the angle formed by the original points. The radius
	// of the points relative to the centre remains the same
	
	float r1 = hypotf( inPoints[0].x - inPoints[1].x, inPoints[0].y - inPoints[1].y );
	float r2 = hypotf( inPoints[2].x - inPoints[1].x, inPoints[2].y - inPoints[1].y );

	// find angle ABC and bisect it

	float angle = ( Slope( inPoints[1], inPoints[2] ) + Slope( inPoints[0], inPoints[1] )) / 2.0f;
	
	if ( outCPA )
	{
		outCPA->x = inPoints[1].x + r1 * cosf( angle + pi );
		outCPA->y = inPoints[1].y + r1 * sinf( angle + pi );
	}
	
	if( outCPB )
	{
		outCPB->x = inPoints[1].x - r2 * cosf( angle + pi );
		outCPB->y = inPoints[1].y - r2 * sinf( angle + pi );
	}
}


- (NSBezierPath*)		bezierPathByRemovingTrailingElements:(int) numToRemove
{
	// returns a copy with the last <n> elements removed.

	NSBezierPath* newPath = [self copy];
	
	if( ![self isEmpty])
	{
		int						i, count = [self elementCount];
		NSPoint					ap[3];
		NSBezierPathElement		kind;
		
		[newPath removeAllPoints];
		
		for( i = 0; i < ( count - numToRemove ); ++i )
		{
			kind = [self elementAtIndex:i associatedPoints:ap];
			
			switch( kind )
			{
				default:
				case NSMoveToBezierPathElement:
					[newPath moveToPoint:ap[0]];
					break;
					
				case NSLineToBezierPathElement:
					[newPath lineToPoint:ap[0]];
					break;
					
				case NSCurveToBezierPathElement:
					[newPath curveToPoint:ap[2] controlPoint1:ap[0] controlPoint2:ap[1]];
					break;
					
				case NSClosePathBezierPathElement:
					[newPath closePath];
					break;
			}
		}
	}
	
	return [newPath autorelease];
}


- (NSBezierPath*)		bezierPathByStrippingRedundantElements
{
	// returns a new path which is a copy of the receiver but with all redundant elements stripped out. A redundant element is
	// one that doesn't contribute to the shape's appearance - zero-length lines or curves, and isolated trailing movetos. By
	// stripping these elements, editing a path becomes much easier because all the special cases for the redundant elements can be
	// simply avoided.
	
	NSBezierPath* newPath = [self copy];
	
	if( ![self isEmpty])
	{
		int						i, count = [self elementCount];
		NSPoint					ap[3];
		NSPoint					pp;
		NSBezierPathElement		kind;
		
		pp = NSMakePoint( -1, -1 );
		
		[newPath removeAllPoints];
		
		for( i = 0; i < count; ++i )
		{
			kind = [self elementAtIndex:i associatedPoints:ap];
			
			switch( kind )
			{
				default:
				case NSMoveToBezierPathElement:
					// redundant if this is the last element
					
					if ( i < ( count - 1 ))
						[newPath moveToPoint:ap[0]];
					pp = ap[0];
					break;
					
				case NSLineToBezierPathElement:
					// redundant if its length is zero
					
					if ( !NSEqualPoints( ap[0], pp ))
						[newPath lineToPoint:ap[0]];
						
					pp = ap[0];
					break;
					
				case NSCurveToBezierPathElement:
					// redundant if its endpoint and control points are the same as the previous point
					
					if ( !( NSEqualPoints( pp, ap[0]) && NSEqualPoints( pp, ap[1]) && NSEqualPoints( pp, ap[2])))
						[newPath curveToPoint:ap[2] controlPoint1:ap[0] controlPoint2:ap[1]];
					
					pp = ap[2];
					break;
					
				case NSClosePathBezierPathElement:
					[newPath closePath];
					break;
			}
		}
	}
	
//	LogEvent_(kReactiveEvent,  @"original path = %@", self );
//	LogEvent_(kReactiveEvent,  @"stripped path = %@", newPath );
	
	return [newPath autorelease];
}


///*********************************************************************************************************************
///
/// method:			getPathMoveToCount:lineToCount:curveToCount:closePathCount:
/// scope:			instance method
/// extends:		NSBezierPath
/// description:	counts the number of elements of each type in the path
/// 
/// parameters:		<mtc, ltc, ctc, cpc> pointers to integers that receive the counts for each element type
/// result:			none
///
/// notes:			pass NULL for any values you are not interested in
///
///********************************************************************************************************************

- (void)				getPathMoveToCount:(int*) mtc lineToCount:(int*) ltc curveToCount:(int*) ctc closePathCount:(int*) cpc
{
	int i, ec = [self elementCount];
	int m, l, c, p;
	
	NSBezierPathElement	elem;
	
	m = l = c = p = 0;
	
	for( i = 0; i < ec; ++i )
	{
		elem = [self elementAtIndex:i];
		
		switch( elem )
		{
			case NSMoveToBezierPathElement:
				++m;
				break;
				
			case NSLineToBezierPathElement:
				++l;
				break;
				
			case NSCurveToBezierPathElement:
				++c;
				break;
				
			case NSClosePathBezierPathElement:
				++p;
				break;
				
			default:
				break;
		}
	}
	
	if( mtc )
		*mtc = m;
	
	if( ltc )
		*ltc = l;
	
	if( ctc )
		*ctc = c;
	
	if( cpc )
		*cpc = p;
}


- (BOOL)				isPathClosed
{
	return [self subpathContainingElementIsClosed:0];
}


- (unsigned)			checksum
{
	// returns a value that may be considered unique for this path. Comparing a path's checksum with a previous value can be used to determine whether the path has changed.
	// Do not rely on the actual value returned, only whether it's the same as a previous value or another path. Do not archive or persist this value. Note that two paths
	// with identical contents will return the same value, which might be a useful trait.
	
	unsigned			cs = 157145267; // start with arbitrary number
	unsigned			ec = (unsigned)[self elementCount];
	NSPoint				p[3];
	int					i;
	NSBezierPathElement	element;
	
	// munge with element count
	
	cs ^= ( ec << 5 );
	
	if( ![self isEmpty])
	{
		// munge all the internal points together
		
		for( i = 0; i < [self elementCount]; ++i )
		{
			p[1] = p[2] = NSZeroPoint;
			element = [self elementAtIndex:i associatedPoints:p];
			ec = ((unsigned) element << 10 ) ^ lround( p[0].x ) ^ lround( p[1].x ) ^ lround( p[2].x ) ^ lround( p[0].y ) ^ lround( p[1].y ) ^ lround( p[2].y );
			cs ^= ec;
		}
	}
	
	return cs;
}


- (BOOL)				subpathContainingElementIsClosed:(int) element
{
	// determines if the subpath containing the element is a closed loop. It returns YES under the following conditions:
	// a. there is a closepath command at or higher than element, OR
	// b. the endpoint of the last element is at the same location as the previous moveto.
	
	// a - look ahead for a closepath
	
	int					i, ee, ec = [self elementCount];
	NSBezierPathElement	et;

	for( i = element; i < ec; ++i )
	{
		et = [self elementAtIndex:i];
		
		if ( et == NSClosePathBezierPathElement )
			return YES;
	}
	
	// b - look for start and end being the same

	NSPoint		p[3];
	NSPoint		endPoint;
	
	ee = [self subpathEndingElementForElement:element];
	et = [self elementAtIndex:ee associatedPoints:p];

	if ( et == NSCurveToBezierPathElement )
		endPoint = p[2];
	else
		endPoint = p[0];
		
	i = [self subpathStartingElementForElement:element];
		
	if ( i != -1 )
	{
		et = [self elementAtIndex:i associatedPoints:p];
		return NSEqualPoints( p[0], endPoint );
	}

	return NO;
}


- (int)					subpathStartingElementForElement:(int) element
{
	// finds the starting element for the subpath containing <element> This will always be a moveto element.
	
	NSBezierPathElement	et;
	int					i;
	
	for( i = element; i >= 0; --i )
	{
		et = [self elementAtIndex:i];
	
		if ( et == NSMoveToBezierPathElement )
			return i;
	}
	
	return -1;
}


- (int)					subpathEndingElementForElement:(int) element
{
	// finds the ending element for the subpath containing <element> This may be any type except a moveto.
	
	NSBezierPathElement	et;
	int					i, ec = [self elementCount];
	
	et = [self elementAtIndex:element];
	
	if ( et == NSMoveToBezierPathElement )
		++element;
	
	for( i = element; i < ec; ++i )
	{
		et = [self elementAtIndex:i];
	
		if ( et == NSMoveToBezierPathElement )
			return i - 1;
	}
	
	return ec - 1;
}



/*
 a "partcode" is simply a unique identifier for one control point in the path. An element may have up to three partcodes
 if it is a curveto element, just one if it is any of the others. A path editor works using partcodes rather than element
 indexes because that is what it is manipulating - individual control points.
 
 partcodes are a very simple hash of the element index and the array index for the associated points. However, don't rely
 on its format - use the utility methods here to translate back and forth between partcodes and element/array indexes.
 
 partcodes are 1-based, so that a partcode of 0 can be used to mean "no hit" when hit testing.
 
*/

- (NSBezierPathElement)	elementTypeForPartcode:(int) pc
{
	// returns the element type given a partcode
	
	return [self elementAtIndex:elementIndexForPartcode( pc )];
}


- (BOOL)				isOnPathPartcode:(int) pc
{
	// returns YES if the given partcode is NOT a bezier control point, but is a bezier or line segment end point.
	
	if ( pc > 3 )
	{
		NSBezierPathElement element = [self elementTypeForPartcode:pc];
		
		if ( element == NSCurveToBezierPathElement )
		{
			int indx = arrayIndexForPartcode( pc );
			return ( indx == 2 );
		}
		return YES;
	}
	
	return NO;
}



- (void)				setControlPoint:(NSPoint) p forPartcode:(int) pc
{
	NSPoint				ap[3];
	int					elem = elementIndexForPartcode( pc );
	NSBezierPathElement et;
	
	et = [self elementAtIndex:elem associatedPoints:ap];
	ap[arrayIndexForPartcode( pc )] = p;
	
	[self setAssociatedPoints:ap atIndex:elem]; 
}


- (NSPoint)				controlPointForPartcode:(int) pc
{
	// given a partcode, this returns the current position of the associated control point
	
	NSPoint				ap[3];
	int					elem = elementIndexForPartcode( pc );
	NSBezierPathElement et;
	
	et = [self elementAtIndex:elem associatedPoints:ap];
	
	return ap[ arrayIndexForPartcode( pc )];
}


- (int)					partcodeHitByPoint:(NSPoint) p tolerance:(float) t
{
	return [self partcodeHitByPoint:p tolerance:t startingFromElement:0];
}


- (int)					partcodeHitByPoint:(NSPoint) p tolerance:(float) t startingFromElement:(int) startElement
{
	// given a point <p>, this detects whether any of the control points in the path were hit. A hit has to
	// be within <t> of the point's position. Returns the partcode of the point hit, or 0 if not hit.
		
	float	thalf = 0.5f * t;
	NSRect	bb = [self controlPointBounds];
	
	// if point not in control point bounds, trivially discard it
	
	if ( ! NSPointInRect( p, NSInsetRect( bb, -thalf, -thalf )))
		return 0;
		
	// scan through looking for hits in any control point. The test order here looks for curve control points
	// in preference to on-path points so that if they lie at the same point, the cp is detected. This makes it
	// possible for the user to drag a cp away from an underlying on-path point.
	
	NSBezierPathElement et, pet;
	NSPoint				ap[3], lp[3];
	
	int pc, i, ec = [self elementCount];
	
	for( i = startElement + 1; i < ec; ++i )
	{
		pet = [self elementAtIndex:i-1 associatedPoints:lp];
		et = [self elementAtIndex:i associatedPoints:ap];
		
		if ( et == NSCurveToBezierPathElement )
		{
			// test 2 control points, 3 for last segment
			
			pc = [NSBezierPath point:p inNSPointArray:ap count:(i == ( ec-1 ))? 3 : 2 tolerance:t];
			
			if ( pc != NSNotFound )
				return partcodeForElementControlPoint( i, pc );
				
			// next test on-path point of previous segment:
			
			if ( pet == NSCurveToBezierPathElement )
			{
				pc = [NSBezierPath point:p inNSPointArray:&lp[2] count:1 tolerance:t];
				if ( pc != NSNotFound )
					pc = 2;
			}
			else
				pc = [NSBezierPath point:p inNSPointArray:lp count:1 tolerance:t];

			if ( pc != NSNotFound )
				return partcodeForElementControlPoint( i-1, pc );
				
			// also test last segment if necessary
			
			if ( i == ec - 1 )
			{
				pc = [NSBezierPath point:p inNSPointArray:ap count:3 tolerance:t];
			
				if ( pc != NSNotFound )
					return partcodeForElementControlPoint( i, pc );
			}
		}
		else
		{
			// one point to test, which is the end point of the previous segment
			
			if ( pet == NSCurveToBezierPathElement )
			{
				pc = [NSBezierPath point:p inNSPointArray:&lp[2] count:1 tolerance:t];
				if ( pc != NSNotFound )
					pc = 2;
			}
			else
				pc = [NSBezierPath point:p inNSPointArray:lp count:1 tolerance:t];
			
			if ( pc != NSNotFound )
				return partcodeForElementControlPoint( i-1, pc );

			// also test last segment if necessary
			
			if ( i == ec - 1 )
			{
				pc = [NSBezierPath point:p inNSPointArray:ap count:1 tolerance:t];
			
				if ( pc != NSNotFound )
					return partcodeForElementControlPoint( i, pc );
			}
		}
	}
	
	return 0;
}


- (int)					partcodeForLastPoint
{
	int m = [self elementCount] - 1;
	NSBezierPathElement element = [self elementAtIndex:m];
	
	if( element == NSCurveToBezierPathElement )
		return partcodeForElementControlPoint( m, 2 );
	else
		return partcodeForElementControlPoint( m, 0 );
}


- (void)				moveControlPointPartcode:(int) pc toPoint:(NSPoint) p colinear:(BOOL) colin coradial:(BOOL) corad constrainAngle:(BOOL) acon
{
	// high-level method for editing paths. This optionally maintains colinearity of control points across curve segment joins, and
	// deals with maintaining closed loops and dealing with the dangling moveto that closePath inserts.
	
	// the flags <colin> and <corad> affect the way related points for a curve segment are moved into alignment with this one:
	
	// colin NO				- this point is moved entirely independently
	// colin YES, corad NO	- opposite point stays in linear alignment with this point, but radius remains the same
	// colin YES, corad YES	- opposite point adjusted to be both colinear and coradial
	
	// if <acon> is YES and the point being moved is a curve control point, the angle relative to the on-path point is constrained using the
	// set constraint interval for the class
						
	NSBezierPathElement et =			[self elementTypeForPartcode:pc];
	int					ec =			[self elementCount];
	int					element =		elementIndexForPartcode( pc );
	BOOL				closedLoop =	[self subpathContainingElementIsClosed:element];
	NSPoint				old =			[self controlPointForPartcode:pc];
	
	float				dx, dy;
	NSBezierPathElement previous = NSMoveToBezierPathElement;
	NSBezierPathElement following = NSMoveToBezierPathElement;
	NSPoint				opp, centre;
	int					prev, next;
	static int			depth = 0;
	
	++depth;
	
	dx = p.x - old.x;
	dy = p.y - old.y;
	
	prev = MAX( 0, element - 1);
	next = element + 1;
	
	if ( element < ( ec - 1 ))
		following = [self elementAtIndex:next];
		
	if ( element > 0 )
		previous = [self elementAtIndex:prev];
	
	if ( et == NSCurveToBezierPathElement )
	{
		// this is a curve element. This means we could be affecting points in the previous OR the following elements,
		// but not both.
		
		int cp = arrayIndexForPartcode( pc );	// index of control point of curve, 0 1 or 2
		
		if ( acon && cp != 2 )
		{
			// constrain point p to angular multiples of 15¡ (or whatever is set)
			
			if ( cp == 0 )
			{
				if ( previous == NSCurveToBezierPathElement )
					centre = [self controlPointForPartcode:partcodeForElementControlPoint( prev, 2 )];
				else
					centre = [self controlPointForPartcode:partcodeForElement( prev )];
			}
			else
				centre = [self controlPointForPartcode:partcodeForElementControlPoint( element, 2 )];
				
			float pa = atan2f( p.y - centre.y, p.x - centre.x );
			float pd = hypotf( p.x - centre.x, p.y - centre.y );
			float rem = fmodf( pa, sAngleConstraint );
				
			if ( rem > sAngleConstraint / 2.0 )
				pa += ( sAngleConstraint - rem );
			else
				pa -= rem;
			
			p.x = centre.x + ( pd * cosf( pa ));
			p.y = centre.y + ( pd * sinf( pa ));
		}
		
		switch( cp )
		{
			case 0:		// control point 1
				if ( colin )
				{
					if ( previous == NSCurveToBezierPathElement )
					{
						int prevPc = partcodeForElementControlPoint( prev, 1 );
						
						centre = [self controlPointForPartcode:partcodeForElementControlPoint( prev, 2 )];
						
						if ( corad )
							opp = [NSBezierPath colinearPointForPoint:p centrePoint:centre];
						else
						{
							NSPoint curOpp = [self controlPointForPartcode:prevPc];
							float rad = hypotf( curOpp.x - centre.x, curOpp.y - centre.y );
						
							opp = [NSBezierPath colinearPointForPoint:p centrePoint:centre radius:rad];
						}
						
						[self setControlPoint:opp forPartcode:prevPc];
					}
					else if ( closedLoop && ( previous == NSMoveToBezierPathElement ))
					{
						// the point being moved is cp2 of the last element in the loop, if it's a curve
						
						int le = [self subpathEndingElementForElement:element];
						previous = [self elementAtIndex:le];
						
						if ( previous == NSCurveToBezierPathElement )
						{
							centre = [self controlPointForPartcode:partcodeForElement( prev )];
							int prevPc = partcodeForElementControlPoint( le, 1 );
							
							if ( corad )
								opp = [NSBezierPath colinearPointForPoint:p centrePoint:centre];
							else
							{
								NSPoint curOpp = [self controlPointForPartcode:prevPc];
								float rad = hypotf( curOpp.x - centre.x, curOpp.y - centre.y );
						
								opp = [NSBezierPath colinearPointForPoint:p centrePoint:centre radius:rad];
							}
							
							[self setControlPoint:opp forPartcode:prevPc];
						}
					}
				}
				break;
				
			case 1:		// control point 2
				if ( colin )
				{
					if (( element < ( ec - 1 )) && ( following == NSCurveToBezierPathElement ))
					{
						centre = [self controlPointForPartcode:partcodeForElementControlPoint( element, 2 )];
						
						if ( corad )
							opp = [NSBezierPath colinearPointForPoint:p centrePoint:centre];
						else
						{
							NSPoint curOpp = [self controlPointForPartcode:partcodeForElement( next )];
							float rad = hypotf( curOpp.x - centre.x, curOpp.y - centre.y );
						
							opp = [NSBezierPath colinearPointForPoint:p centrePoint:centre radius:rad];
						}
						
						[self setControlPoint:opp forPartcode:partcodeForElement( next )];
					}
					else if ( closedLoop && ( element == [self subpathEndingElementForElement:element]))
					{
						// cross-couple to second element control point if it's a curve
						
						int e2 = [self subpathStartingElementForElement:element] + 1;
						
						following = [self elementAtIndex:e2];
						if ( following == NSCurveToBezierPathElement )
						{
							centre = [self controlPointForPartcode:partcodeForElementControlPoint( element, 2 )];
							
							if ( corad )
								opp = [NSBezierPath colinearPointForPoint:p centrePoint:centre];
							else
							{
								NSPoint curOpp = [self controlPointForPartcode:partcodeForElement( e2 )];
								float rad = hypotf( curOpp.x - centre.x, curOpp.y - centre.y );
						
								opp = [NSBezierPath colinearPointForPoint:p centrePoint:centre radius:rad];
							}
							
							[self setControlPoint:opp forPartcode:partcodeForElement( e2 )];
						}
					}
				}
				break;
				
			case 2:		// end point - moves all three linked points by delta. This doesn't force the points to become colinear
			{
				if (( element < ( ec - 1 )) && ( following == NSCurveToBezierPathElement ))
				{
					opp = [self controlPointForPartcode:partcodeForElement( next )];
					
					opp.x += dx;
					opp.y += dy;
					
					[self setControlPoint:opp forPartcode:partcodeForElement( next )];
				}
				opp = [self controlPointForPartcode:partcodeForElementControlPoint( element, 1 )];
				opp.x += dx;
				opp.y += dy;
				[self setControlPoint:opp forPartcode:partcodeForElementControlPoint( element, 1 )];
			}
			break;
			
			default:
				break;
		}
		
		[self setControlPoint:p forPartcode:pc];
	 }
	 else if ( et != NSClosePathBezierPathElement )
	 {
		// this is a single point element of some kind but not a closepath. If the element is followed by a
		// curve, offset its first control point by the delta as well.
		
		// if constraining angle, check slope with previous point
		
		if ( acon )
		{
			if ( previous == NSCurveToBezierPathElement )
				centre = [self controlPointForPartcode:partcodeForElementControlPoint( prev, 2 )];
			else
				centre = [self controlPointForPartcode:partcodeForElement( prev )];
		
			float pa = atan2f( p.y - centre.y, p.x - centre.x );
			float pd = hypotf( p.x - centre.x, p.y - centre.y );
			float rem = fmodf( pa, sAngleConstraint );
				
			if ( rem > sAngleConstraint / 2.0 )
				pa += ( sAngleConstraint - rem );
			else
				pa -= rem;
			
			p.x = centre.x + ( pd * cosf( pa ));
			p.y = centre.y + ( pd * sinf( pa ));
		}
	
		[self setControlPoint:p forPartcode:pc];
	
		if ( following == NSCurveToBezierPathElement )
		{
			int fpc = partcodeForElement( next );
			old = [self controlPointForPartcode:fpc];
	
			old.x += dx;
			old.y += dy;
		
			[self setControlPoint:old forPartcode:fpc];
		}
		
		// if a closed loop and this is the first element, adjust the subself ending point as well
				
		if ( depth == 1 && closedLoop && ( et == NSMoveToBezierPathElement ))
		{
			int ee = [self subpathEndingElementForElement:element];
		//	LogEvent_(kReactiveEvent, @"recursing to adjust element %d", ee );
			following = [self elementAtIndex:ee];
			
			if ( following == NSCurveToBezierPathElement )
				[self moveControlPointPartcode:partcodeForElementControlPoint( ee, 2 ) toPoint:p colinear:colin coradial:corad constrainAngle:acon];
			else
				[self moveControlPointPartcode:partcodeForElement( ee ) toPoint:p colinear:colin coradial:corad constrainAngle:acon];
		}
	}
	
	depth--;
}


- (NSBezierPath*)		deleteControlPointForPartcode:(int) pc
{
	int aidx = arrayIndexForPartcode( pc );
	int elem = elementIndexForPartcode( pc );
	NSBezierPathElement type = [self elementTypeForPartcode:pc];
	
	// if the partcode indicates an off-path point, ignore it - it only really makes sense to delete on-path points.
	
	if ( elem < 0 || ( type == NSCurveToBezierPathElement && aidx != 2 ))
		return self;
	else
	{
		int						i, j, m = [self elementCount];
		NSPoint					ap[3], lp[3];
		BOOL					deletedFirstPoint = NO;
		NSBezierPathElement		lm;
		NSBezierPath*			newPath = [NSBezierPath bezierPath];
		
		for( i = 0; i < m; ++i )
		{
			lm = [self elementAtIndex:i associatedPoints:ap];
		
			if( i == elem )
			{
				// this is the one being deleted, so only need to check if it's the first point (moveto)
				
				if( i == 0 )
					deletedFirstPoint = YES;
			}
			else
			{
				if ( deletedFirstPoint && i == 1 )
				{
					if ( lm == NSCurveToBezierPathElement )
						[newPath moveToPoint:ap[2]];
					else
						[newPath moveToPoint:ap[0]];
				}
				else
				{
					switch( lm )
					{
						case NSCurveToBezierPathElement:
							if ( i == ( elem + 1 ))
								[newPath curveToPoint:ap[2] controlPoint1:lp[0] controlPoint2:ap[1]];
							else
								[newPath curveToPoint:ap[2] controlPoint1:ap[0] controlPoint2:ap[1]];
							break;
							
						case NSMoveToBezierPathElement:
							[newPath moveToPoint:ap[0]];
							break;
							
						case NSLineToBezierPathElement:
							[newPath lineToPoint:ap[0]];
							break;
							
						case NSClosePathBezierPathElement:
							[newPath closePath];
							break;
							
						default:
							break;
					}
				}
			}
			
			// keep track of the last point
			
			for( j = 0; j < 3; ++j )
				lp[j] = ap[j];
		}
		
		return newPath;
	}
}

// controlPointType is a value 0, 1 or 2 thus:
// 0 = insert whatever is appropriate for the element type hit
// 1 = insert a line segment even if a curve is hit
// 2 = insert a curve segment even if a line is hit
// 3 = insert opposite kind of element from whatever was hit
// see also: DKDrawablePath which calls this

- (NSBezierPath*)		insertControlPointAtPoint:(NSPoint) p tolerance:(float) tol type:(int) controlPointType
{
	float				t;
	int					i, j, m, inselem = [self elementHitByPoint:p tolerance:tol tValue:&t];
	NSPoint				ap[4], lp[4];	// leave room for four points to define bezier segment
	NSBezierPathElement	pe, pre;
	NSBezierPath*		newPath = nil;
	
	if ( inselem > 0 )
	{
		//NSLog( @"point %@ is close to line, element = %d, t = %f", NSStringFromPoint( p ), inselem, t );
		
		// got a valid insertion point, so copy the path to a new path, inserting a new point
		// at the given element, splitting the existing element at that point to do so.
		
		newPath = [NSBezierPath bezierPath];
		m = [self elementCount];
		
		for( i = 0; i < m; ++i )
		{
			pe = [self elementAtIndex:i associatedPoints:&ap[1]];
			
			if ( i == inselem )
			{
				pre = [self elementAtIndex:i - 1];
				
				if ( pre == NSCurveToBezierPathElement )
					ap[0] = lp[3];
				else
					ap[0] = lp[1];

				if ( pe == NSCurveToBezierPathElement )
				{
					// bezier segment - split at t and append both curves
					
					NSPoint b1[4], b2[4];
					
					subdivideBezierAtT( ap, b1, b2, t );
					
					if ( controlPointType == 1 || controlPointType == 3 )
					{
						// inset a line segment even though we are splitting a curve segment. In this case
						// the curvature of the line leading to the inserted point obviously cannot be preserved.
						
						[newPath lineToPoint:b1[3]];
						[newPath curveToPoint:b2[3] controlPoint1:b2[1] controlPoint2:b2[2]];
					}
					else
					{
						[newPath curveToPoint:b1[3] controlPoint1:b1[1] controlPoint2:b1[2]];
						[newPath curveToPoint:b2[3] controlPoint1:b2[1] controlPoint2:b2[2]];
					}
				}
				else
				{
					// straight line - split at t and append the two pieces.
				
					NSPoint ip = Interpolate( ap[1], ap[0], t );
					
					if ( controlPointType == 2 || controlPointType == 3 )
					{
						// insert a pair of curve segments even though we are splitting a line segment -
						// initial control points are set so that the path doesn't change but not coincident with on-path points.
						
						NSPoint cpa, cpb, cpc, cpd;
						
						cpa = Interpolate( ip, ap[0], 0.75 );
						cpb = Interpolate( ip, ap[0], 0.25 );
						cpc = Interpolate( ap[1], ip, 0.75 );
						cpd = Interpolate( ap[1], ip, 0.25 );
						
						[newPath curveToPoint:ip controlPoint1:cpa controlPoint2:cpb];
						[newPath curveToPoint:ap[1] controlPoint1:cpc controlPoint2:cpd];
					}
					else
					{
						[newPath lineToPoint:ip];
						[newPath lineToPoint:ap[1]];
					}
				}
			}
			else
			{
				switch ( pe )
				{
					case NSCurveToBezierPathElement:
						[newPath curveToPoint:ap[3] controlPoint1:ap[1] controlPoint2:ap[2]];
						break;
						
					case NSMoveToBezierPathElement:
						[newPath moveToPoint:ap[1]];
						break;
						
					case NSLineToBezierPathElement:
						[newPath lineToPoint:ap[1]];
						break;
						
					case NSClosePathBezierPathElement:
						[newPath closePath];
						break;
						
					default:
						break;
				}
			}
			
			for( j = 0; j < 4; ++j )
				lp[j] = ap[j];
		}
	}
	//else
	//	NSLog( @"point %@ missed, element = %d", NSStringFromPoint( p ), inselem );
	
	return newPath;
}


- (NSPoint)				nearestPointToPoint:(NSPoint) p tolerance:(float) tol
{
	// given a point, this determines whether it's within <tol> distance of the path. If so, the nearest point on the path is returned,
	// otherwise the original point is returned.
	
	NSPoint	np;
	float	t;
	int		elem = [self elementHitByPoint:p tolerance:tol tValue:&t nearestPoint:&np];
	
	if ( elem < 1 )
		return p;
	else
		return np;
}


- (float)				tangentAtStartOfSubpath:(int) elementIndex
{
	// given an element index, this finds the start of the subpath and returns the tangent of the endpoint. The tangent can be used to align elements on the path such as
	// arrow heads. For a curve segment, the tangent is the angle of the line drawn from cp0 to cp1. For a line segment, the tangent is the angle of the line segment.

	int						se;
	NSPoint					ap[3];
	NSPoint					bp[3];
	
	se = [self subpathStartingElementForElement:elementIndex];
	
	[self elementAtIndex:se associatedPoints:ap];
	[self elementAtIndex:se + 1 associatedPoints:bp];
	
	return atan2f( bp[0].y - ap[0].y, bp[0].x - ap[0].x ) + pi;
}


- (float)				tangentAtEndOfSubpath:(int) elementIndex
{
	// given an element index, this finds the end of the subpath and returns the tangent of the endpoint. The tangent can be used to align elements on the path such as
	// arrow heads. For a curve segment, the tangent is the angle of the line drawn from cp2 to cp3. For a line segment, the tangent is the angle of the line segment.
	
	int						ee;
	NSPoint					ap[3];
	NSPoint					bp[3];
	NSBezierPathElement		et, pt;
	
	ee = [self subpathEndingElementForElement:elementIndex];
	et = [self elementAtIndex:ee associatedPoints:ap];
	
	// if last element is a curveto, we have all the information we need to compute the tangent
	
	if ( et == NSCurveToBezierPathElement )
		return atan2f( ap[2].y - ap[1].y, ap[2].x - ap[1].x );
	else
	{
		// ending element is a lineto or other single point, so we need to find the last point of the previous element
		
		pt = [self elementAtIndex:ee - 1 associatedPoints:bp];
		
		// if it s a curveto, its end point is bp[2], otherwise it's bp[0]
		
		if ( pt == NSCurveToBezierPathElement )
			return atan2f( ap[0].y - bp[2].y, ap[0].x - bp[2].x );
		else
			return atan2f( ap[0].y - bp[0].y, ap[0].x - bp[0].x );
	}
}


- (int)					elementHitByPoint:(NSPoint) p tolerance:(float) tol tValue:(float*) t
{
	return [self elementHitByPoint:p tolerance:tol tValue:t nearestPoint:NULL];
}


- (int)					elementHitByPoint:(NSPoint) p tolerance:(float) tol tValue:(float*) t nearestPoint:(NSPoint*) npp
{
	// determines which element is hit by the point, and where. This first rejects any point outside the overall bounds of the
	// path, then tests which elements bounds enclose the point. Then it really gets down to business and calculates the
	// actually position along the path. For line segments, the t value returned is the linear proportion of the length from
	// 0..1, for curves it is the bezier t parameter value. <tol> is used to determine how accurate the computation needs to be
	// to count as a hit.
	
	NSRect bb = NSInsetRect([self bounds], -tol, -tol );
	
	if ( NSPointInRect( p, bb ))
	{
		int elem = [self elementBoundsContainsPoint:p tolerance:tol];
		
		//NSLog(@"point %@ (tol = %f) in element bbox, elem = %d", NSStringFromPoint( p ), tol, elem );
		
		if ( elem > 0 )
		{
			// point is with the bbox of the segment <elem>. If elem == 0, error
			
			NSPoint				np = NSZeroPoint;
			NSPoint				ap[3], lp[3];
			NSBezierPathElement etype = [self elementAtIndex:elem associatedPoints:ap];
			NSBezierPathElement pretype = [self elementAtIndex:elem - 1 associatedPoints:lp];
			double				tt = 0.0;
			
			// only care about the end point - put it in lp[0] where it is consistent for all types
			
			if ( pretype == NSCurveToBezierPathElement )
				lp[0] = lp[2];
		
			if ( etype == NSCurveToBezierPathElement )
			{
				// curve
				
				NSPoint bez[4];
				
				bez[0] = lp[0];
				bez[1] = ap[0];
				bez[2] = ap[1];
				bez[3] = ap[2];
				
				np = NearestPointOnCurve( p, bez, &tt );
			}
			else if ( etype != NSMoveToBezierPathElement )
			{
				if ( etype == NSClosePathBezierPathElement )
				{
					// get point for start of this subpath
					
					int ss = [self subpathStartingElementForElement:elem];
					[self elementAtIndex:ss associatedPoints:ap];
				}
				
				// line or close
				
				np = NearestPointOnLine( p, lp[0], ap[0] );
				tt = RelPoint( np, lp[0], ap[0] );
			}	
			
			// check to see if the nearest point is within tolerance:
			
			float d = hypotf(( np.x - p.x ), ( np.y - p.y ));
			
			//NSLog(@"point is %f from segment line: {%1.2f,%1.2f}..{%1.2f,%1.2f}", d, ap[0].x, ap[0].y, lp[0].x, lp[0].y );

			if ( d <= tol )
			{
				if( t )
					*t = tt;
					
				if ( npp )
					*npp = np;
						
				return elem;
			}
		}
	}
	
	return -1;	// out of tolerance, or not found
}


- (int)					elementBoundsContainsPoint:(NSPoint) p tolerance:(float) tol
{
	// for each element of a bezier path, this tests the point against the bounding box of the element, returning the
	// element index of the one containing the point. If none do, it returns -1. This gives you a quick way to home in
	// on the specific element to work on for further resolving the point. Note - assumes you've already tested the overall
	// bounds and got a YES result (this works either way, but if that returns NO, there's no point doing this).
	
	int		i, m = [self elementCount];
	NSRect	bb;
	
	// initially ignore <tol>, this allows us to find the right element when the point is close to another segment
	
	for( i = 1; i < m; ++i )
	{
		bb = [self boundingBoxForElement:i];
		
		if ( NSPointInRect( p, bb ))
			return i;
	}
	
	// if not found, widen the search to include <tol>. This allows us to find the nearest element even if the point is outside the
	// bbox. This is performed as a second step because otherwise the overlapping bboxes can give false results.

	for( i = 1; i < m; ++i )
	{
		bb = NSInsetRect([self boundingBoxForElement:i], -tol, -tol);
		
		if ( NSPointInRect( p, bb ))
			return i;
	}
	
	// OK, we give up
	
	return -1;
}


- (NSRect)				boundingBoxForElement:(int) elementIndex
{
	// given the element index, this returns the element's bounding rect.
	
	NSRect				bb = NSZeroRect;
	NSPoint				ap[4], pp[3];
	float				minx, miny, maxx, maxy;
	int					j;
	
	NSBezierPathElement pm = 0;
	NSBezierPathElement	lm = [self elementAtIndex:elementIndex associatedPoints:ap];
	
	if ( lm == NSMoveToBezierPathElement )
		return NSZeroRect;
	
	pm = [self elementAtIndex:elementIndex - 1 associatedPoints:pp];

	if ( lm == NSCurveToBezierPathElement )
	{
		// curves are bounded by their control points - in fact the curve may be considerably
		// smaller than that, but it's much faster to calculate the cp bounds
		
		if ( pm == NSCurveToBezierPathElement )
			ap[3] = pp[2];
		else
			ap[3] = pp[0];
		
		minx = miny = HUGE_VAL;
		maxx = maxy = -HUGE_VAL;
		
		for( j = 0; j < 4; ++j )
		{
			if ( ap[j].x < minx )
				minx = ap[j].x;
				
			if ( ap[j].y < miny )
				miny = ap[j].y;
				
			if ( ap[j].x > maxx )
				maxx = ap[j].x;
			
			if ( ap[j].y > maxy )
				maxy = ap[j].y;
		}
		
		bb.origin.x = minx;
		bb.origin.y = miny;
		bb.size.width = fabs(maxx - minx);
		bb.size.height = fabs(maxy - miny);
	}
	else if ( lm == NSClosePathBezierPathElement )
	{
		int fe = [self subpathStartingElementForElement:elementIndex];
		[self elementAtIndex:fe associatedPoints:ap];
		
		if( pm == NSCurveToBezierPathElement )
			bb = NSRectFromTwoPoints( ap[0], pp[2] );
		else
			bb = NSRectFromTwoPoints( ap[0], pp[0] );
		
	//	LogEvent_(kInfoEvent, @"fe = %d, a = %@, b = %@", fe, NSStringFromPoint( ap[0]), NSStringFromPoint( pp[0] ));
	}
	else
	{
		// lines define two opposite corners of the bbox
		
		if( pm == NSCurveToBezierPathElement )
			bb = NSRectFromTwoPoints( ap[0], pp[2] );
		else
			bb = NSRectFromTwoPoints( ap[0], pp[0] );
	}
	
	return bb;
}


- (void)				drawElementsBoundingBoxes
{
	// this is a debugging method - it displays the bounding rects of the path in the current view
	
	[[NSColor redColor] set];
	[NSBezierPath setDefaultLineWidth:0.0];
	
	int		i, m = [self elementCount];
	
	for( i = 0; i < m; ++i )
		[NSBezierPath strokeRect:[self boundingBoxForElement:i]];
}


- (NSSet*)			boundingBoxesForPartcode:(int) pc
{
	// returns a set of two rectangles (as NSValues) which bound the elements either side of the partcode. The rects are not ordered as such - you
	// can use them to call for a refresh of the path for just that element which can reduce uneeded drawing (the entire path is still redrawn, but
	// other objects close to it that intersect its overall bounds but not the element bounds will not be).
	
	NSMutableSet* set = [NSMutableSet set];
	int		j, e = elementIndexForPartcode(pc);
	NSRect	r = [self boundingBoxForElement:e];
	[set addObject:[NSValue valueWithRect:r]];
	
	NSBezierPathElement lm = [self elementTypeForPartcode:pc];
	
	// the other rect is for the next or previous element depending on whether pc is the first control point or a later one.
	
	if( e < [self elementCount])
	{
		j = arrayIndexForPartcode(pc);
		
		if ( j == 0 && e > 0 && lm == NSCurveToBezierPathElement)
		{
			r = [self boundingBoxForElement:e - 1];
			[set addObject:[NSValue valueWithRect:r]];
		}
		else if ( e < [self elementCount] - 1 )
		{
			r = [self boundingBoxForElement:e + 1];
			[set addObject:[NSValue valueWithRect:r]];
		}
	}
	
	// if the path is closed it also needs to return the box from the opposite end of the path

	if([self isPathClosed])
	{
		if ( e < 2 )
		{
			r = [self boundingBoxForElement:[self subpathEndingElementForElement:e]];
			[set addObject:[NSValue valueWithRect:r]];
		}
		else if ( e == ([self elementCount] - 1))
		{
			r = [self boundingBoxForElement:[self subpathStartingElementForElement:e] + 1];
			[set addObject:[NSValue valueWithRect:r]];
		}
	}
	
	return set;
}


- (NSSet*)				allBoundingBoxes
{
	NSMutableSet*	set = [NSMutableSet set];
	NSRect			r;
	int				i, m = [self elementCount];
	
	for( i = 0; i < m; ++i )
	{
		r = [self boundingBoxForElement:i];
		[set addObject:[NSValue valueWithRect:r]];
	}
	return set;
}


@end



static inline int			partcodeForElement( const int element )
{
	// returns a unique partcode for an element that contains just a single point (i.e. all of them except curveto)
	
	return (( element + 1 ) << 2 );
}


static inline int			partcodeForElementControlPoint( const int element, const int controlPointIndex )
{
	// given the element and the index of the control point (0, 1 or 2 ), this returns a unique "partcode" that
	// can be used to refer to that specific control point in the path.
	
	return ((( element + 1 ) << 2 ) | ( controlPointIndex & 3 ));
}


static inline int			arrayIndexForPartcode( const int pc )
{
	return ( pc & 3 );
}


static inline int			elementIndexForPartcode( const int pc )
{
	// returns the element index a partcode is referring to
	
	return ( pc >> 2 ) - 1;
}

