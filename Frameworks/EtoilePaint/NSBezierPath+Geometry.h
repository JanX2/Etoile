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

- (NSBezierPath*)		bezierPathByInterpolatingPath:(float) amount;

@end

