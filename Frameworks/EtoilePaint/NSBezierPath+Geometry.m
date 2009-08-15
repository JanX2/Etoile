///**********************************************************************************************************************************
///  NSBezierPath-Geometry.m
///  DrawKit ¬¨¬®¬¨¬Æ¬¨¬®¬¨¬©2005-2008 Apptree.net
///
///  Created by graham on 22/10/2006.
///
///	 This software is released subject to licensing conditions as detailed in DRAWKIT-LICENSING.TXT, which must accompany this source file. 
///
///**********************************************************************************************************************************

#import "NSBezierPath+Geometry.h"
#include <math.h>

#define LIMIT( value, min, max )                (((value) < (min))? (min) : (((value) > (max))? (max) : (value)))

static void				InterpolatePoints( const NSPoint* pointsIn, NSPoint* cp1, NSPoint* cp2, const float smooth_value );

@implementation NSBezierPath (Geometry)

- (NSBezierPath*)		bezierPathByInterpolatingPath:(float) amount
{
	// smooths a vector (line segment) path by interpolation into curve segments. This algorithm from http://antigrain.com/research/bezier_interpolation/index.html#PAGE_BEZIER_INTERPOLATION
	// existing curve segments are reinterpolated as if a straight line joined the start and end points. Note this doesn't simplify a curve - it merely smooths it using the same number
	// of curve segments. <amount> is a value from 0..1 that yields the amount of smoothing, 0 = none.
	
	amount = LIMIT( amount, 0, 1 );
	
	if( amount == 0.0 || [self isEmpty])
		return self;	// nothing to do
	
	NSBezierPath*		newPath = [NSBezierPath bezierPath];
	int					i, m = [self elementCount], spc = 0;
	NSBezierPathElement element;
	NSPoint				ap[3];
	NSPoint				v[3];
	NSPoint				fp, cp1, cp2, pcp;
	
	fp = cp1 = cp2 = NSZeroPoint;
	v[0] = v[1] = v[2] = NSZeroPoint;
	
	for( i = 0; i < m; ++i )
	{
		element = [self elementAtIndex:i associatedPoints:ap];
		
		switch( element )
		{
			case NSMoveToBezierPathElement:
				// starting a new subpath
				
				[newPath moveToPoint:ap[0]];
				fp = v[0] = ap[0];
				spc = 0;
				break;
				
			case NSLineToBezierPathElement:
				if( spc == 0 )
				{
					// recently started a new subpath, so set 2nd vertex
					v[1] = ap[0];
					spc++;
				}
				else
				{
					v[2] = ap[0];
					
					// we have three vertices, so we can interpolate
					
					InterpolatePoints( v, &cp1, &cp2, amount );
					
					// cp2 completes the  curve segment v0..v1 so we can add that to the new path. If it was the first
					// segment, cp1 == cp2
					
					if( spc == 1 )
						pcp = cp2;
					
					[newPath curveToPoint:v[1] controlPoint1:pcp controlPoint2:cp2];
					
					// shift vertex array
					
					v[0] = v[1];
					v[1] = v[2];
					pcp = cp1;
					spc++;
				}
				break;
				
			case NSCurveToBezierPathElement:
				if( spc == 0 )
				{
					// recently started a new subpath, so set 2nd vertex
					v[1] = ap[2];
					spc++;
				}
				else
				{
					v[2] = ap[2];
					
					// we have three vertices, so we can interpolate
					
					InterpolatePoints( v, &cp1, &cp2, amount );
					
					// cp2 completes the  curve segment v0..v1 so we can add that to the new path. If it was the first
					// segment, cp1 == cp2
					
					if( spc == 1 )
						pcp = cp2;
					
					[newPath curveToPoint:v[1] controlPoint1:pcp controlPoint2:cp2];
					
					// shift vertex array
					
					v[0] = v[1];
					v[1] = v[2];
					pcp = cp1;
					spc++;
				}
				break;
				
			case NSClosePathBezierPathElement:
				// close the path by curving back to the first point
				v[2] = fp;
				
				InterpolatePoints( v, &cp1, &cp2, amount );
				
				// cp2 completes the  curve segment v0..v1 so we can add that to the new path. If it was the first
				// segment, cp1 == cp2
				
				if( spc == 1 )
					pcp = cp2;
				
				[newPath curveToPoint:v[1] controlPoint1:pcp controlPoint2:cp2];
				
				// final segment closes the path
				
				[newPath curveToPoint:fp controlPoint1:cp1 controlPoint2:cp1];
				[newPath closePath];
				spc = 0;
				break;
				
			default:
				break;
		}
	}
	
	if( spc > 1 )
	{
		// path ended without a closepath, so add in the final curve segment to the end
		
		[newPath curveToPoint:v[1] controlPoint1:pcp controlPoint2:pcp];
	}
	
	//NSLog(@"new path = %@", newPath);
	
	return newPath;
}


static void				InterpolatePoints( const NSPoint* v, NSPoint* cp1, NSPoint* cp2, const float smooth_value )
{
	// given the vertices of the path v0..v2, this calculates cp1 and cp2 being the control points for the curve segments v0..v1 and v1..v2. i.e. this
	// calculates only half of the control points, but does so for two segments. The caller needs to accumulate cp1 until it has cp2 for the same segment
	// before it can add the curve segment.
	
	// calculate the midpoints of the two edges
	
	float xc1 = ( v[0].x + v[1].x ) * 0.5f;	//(x0 + x1) / 2.0;
    float yc1 =	( v[0].y + v[1].y ) * 0.5f;	//(y0 + y1) / 2.0;
    float xc2 =	( v[1].x + v[2].x ) * 0.5f;	//(x1 + x2) / 2.0;
    float yc2 =	( v[1].y + v[2].y ) * 0.5f;	//(y1 + y2) / 2.0;
	
	// calculate the ratio of the two lengths

    float len1 = hypotf( v[1].x - v[0].x, v[1].y - v[0].y );	//sqrt((x1-x0) * (x1-x0) + (y1-y0) * (y1-y0));
    float len2 = hypotf( v[2].x - v[1].x, v[2].y - v[1].y );	//sqrt((x2-x1) * (x2-x1) + (y2-y1) * (y2-y1));
    float k1;
	
	if(( len1 + len2 ) > 0.0 )
		k1 = len1 / (len1 + len2);
    else
		k1 = 0.0;
	
	// calculate the pivot point of the control point "arms" xm1, ym1
	
    float xm1 =	xc1 + (xc2 - xc1) * k1;
    float ym1 = yc1 + (yc2 - yc1) * k1;

	NSPoint ctrl1, ctrl2;
	
	// ctrl1 is CP1 for the segment v1..v2
	// ctrl2 is CP2 for the segment v0..v1
	
    ctrl1.x = ( xm1 + (xc2 - xm1) * smooth_value ) + v[1].x - xm1;
    ctrl1.y = ( ym1 + (yc2 - ym1) * smooth_value ) + v[1].y - ym1;
	
	ctrl2.x = ( xm1 - (xm1 - xc1) * smooth_value ) + v[1].x - xm1;
	ctrl2.y = ( ym1 - (ym1 - yc1) * smooth_value ) + v[1].y - ym1;

	if( cp1 )
		*cp1 = ctrl1;
		
	if( cp2 )
		*cp2 = ctrl2;
}

@end
