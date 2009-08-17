//
//  ETStrokeDash.h
///  DrawKit ©2005-2008 Apptree.net
//
//  Created by graham on 10/09/2006.
///
///	 This software is released subject to licensing conditions as detailed in DRAWKIT-LICENSING.TXT, which must accompany this source file. 
//

#import <Cocoa/Cocoa.h>


@interface ETStrokeDash : NSObject <NSCoding, NSCopying>
{
@private
	float		m_pattern[8];
	float		m_phase;
	unsigned	m_count;
	BOOL		m_scaleToLineWidth;
}

+ (ETStrokeDash*)	defaultDash;
+ (ETStrokeDash*)	dashWithPattern:(float[]) dashes count:(int) count;
+ (ETStrokeDash*)	dashWithName:(NSString*) name;
+ (void)			registerDash:(ETStrokeDash*) dash withName:(NSString*) name;
+ (NSArray*)		registeredDashes;

+ (ETStrokeDash*)	equallySpacedDashToFitSize:(NSSize) aSize dashLength:(float) len;

+ (void)			saveDefaults;
+ (void)			loadDefaults;

- (id)				initWithPattern:(float[]) dashes count:(int) count;
- (void)			setDashPattern:(float[]) dashes count:(int) count;
- (void)			getDashPattern:(float[]) dashes count:(int*) count;
- (int)				count;
- (void)			setPhase:(float) ph;
- (float)			phase;
- (float)			length;

- (void)			setScalesToLineWidth:(BOOL) stlw;
- (BOOL)			scalesToLineWidth;

- (void)			applyToPath:(NSBezierPath*) path;
- (void)			applyToPath:(NSBezierPath*) path withPhase:(float) phase;

- (NSString*)		styleScript;
- (NSImage*)		dashSwatchImageWithSize:(NSSize) size strokeWidth:(float) width;
- (NSImage*)		standardDashSwatchImage;



@end


/*
 This stores a particular dash pattern for stroking an NSBezierPath, and can be owned by a ETStroke.
*/

#define			kETStandardDashSwatchImageSize		(NSMakeSize( 80.0, 4.0 ))
#define			kETStandardDashSwatchStrokeWidth	2.0
