///**********************************************************************************************************************************
///  DKGeometryUtilities.h
///  DrawKit ©2005-2008 Apptree.net
///
///  Created by graham on 22/10/2006.
///
///	 This software is released subject to licensing conditions as detailed in DRAWKIT-LICENSING.TXT, which must accompany this source file. 
///
///**********************************************************************************************************************************

#import <Cocoa/Cocoa.h>

#ifdef __cplusplus
extern "C"
{
#endif


NSRect				NSRectFromTwoPoints( const NSPoint a, const NSPoint b );
NSRect				NSRectCentredOnPoint( const NSPoint p, const NSSize size );
NSRect				UnionOfTwoRects( const NSRect a, const NSRect b );
NSRect				UnionOfRectsInSet( const NSSet* aSet );
NSSet*				DifferenceOfTwoRects( const NSRect a, const NSRect b );
NSSet*				SubtractTwoRects( const NSRect a, const NSRect b );

BOOL				AreSimilarRects( const NSRect a, const NSRect b, const float epsilon );

float				PointFromLine( const NSPoint inPoint, const NSPoint a, const NSPoint b );
NSPoint				NearestPointOnLine( const NSPoint inPoint, const NSPoint a, const NSPoint b );
float				RelPoint( const NSPoint inPoint, const NSPoint a, const NSPoint b );
int					PointInLineSegment( const NSPoint inPoint, const NSPoint a, const NSPoint b );

NSPoint				BisectLine( const NSPoint a, const NSPoint b );
NSPoint				Interpolate( const NSPoint a, const NSPoint b, const float proportion);
float				LineLength( const NSPoint a, const NSPoint b );

float				SquaredLength( const NSPoint p );
NSPoint				DiffPoint( const NSPoint a, const NSPoint b );
float				DiffPointSquaredLength( const NSPoint a, const NSPoint b );
NSPoint				SumPoint( const NSPoint a, const NSPoint b );

NSPoint				EndPoint( NSPoint origin, float angle, float length );
float				Slope( const NSPoint a, const NSPoint b );
float				AngleBetween( const NSPoint a, const NSPoint b, const NSPoint c );
float				DotProduct( const NSPoint a, const NSPoint b );
NSPoint				Intersection( const NSPoint aa, const NSPoint ab, const NSPoint ba, const NSPoint bb );
NSPoint				Intersection2( const NSPoint p1, const NSPoint p2, const NSPoint p3, const NSPoint p4 );

NSRect				CentreRectOnPoint( const NSRect inRect, const NSPoint p );
NSPoint				MapPointFromRect( const NSPoint p, const NSRect rect );
NSPoint				MapPointToRect( const NSPoint p, const NSRect rect );
NSPoint				MapPointFromRectToRect( const NSPoint p, const NSRect srcRect, const NSRect destRect );
NSRect				MapRectFromRectToRect( const NSRect inRect, const NSRect srcRect, const NSRect destRect );

NSRect				ScaleRect( const NSRect inRect, const float scale );
NSRect				ScaledRectForSize( const NSSize inSize, NSRect const fitRect );
NSRect				CentreRectInRect(const NSRect r, const NSRect cr );

NSRect				NormalizedRect( const NSRect r );
NSAffineTransform*	RotationTransform( const float radians, const NSPoint aboutPoint );

//NSPoint			PerspectiveMap( NSPoint inPoint, NSSize sourceSize, NSPoint quad[4]);

NSPoint				NearestPointOnCurve( const NSPoint inp, const NSPoint bez[4], double* tValue );
NSPoint				Bezier( const NSPoint* v, const int degree, const double t, NSPoint* Left, NSPoint* Right );

float				BezierSlope( const NSPoint bez[4], const float t );

extern const NSPoint NSNotFoundPoint;


#ifdef __cplusplus
}
#endif

