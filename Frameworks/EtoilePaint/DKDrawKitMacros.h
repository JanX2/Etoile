/*
 *  DKDrawKitMacros.h
///  DrawKit ©2005-2008 Apptree.net
 *
 *  Created by graham on 25/02/2008.
///
///	 This software is released subject to licensing conditions as detailed in DRAWKIT-LICENSING.TXT, which must accompany this source file. 
 *
 */

// pinning a value between a lower and upper limit

#define LIMIT( value, min, max )		(((value) < (min))? (min) : (((value) > (max))? (max) : (value)))

// converting from radians to degrees

#define	DEGREES_TO_RADIANS( d )			((d) * 0.0174532925199432958)
#define RADIANS_TO_DEGREES( r )			((r) * 57.29577951308232)

// some useful angular constants

#define pi (3.14159265)
#define FIFTEEN_DEGREES					(0.261799387799)
#define NINETY_DEGREES					(pi * 0.5)
#define FORTYFIVE_DEGREES				(pi * 0.25)
#define HALF_PI							(pi * 0.5)

// exception safe save/restore of the current graphics context

#define	SAVE_GRAPHICS_CONTEXT			@try { [NSGraphicsContext saveGraphicsState];
#define RESTORE_GRAPHICS_CONTEXT		} @finally { [NSGraphicsContext restoreGraphicsState]; }



