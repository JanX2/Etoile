//
//  NSBezierPath+Text.h
//  GCDrawKit
//
//  Created by graham on 05/02/2009.
//  Copyright 2009 Apptree.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>



@interface NSBezierPath (TextOnPath)

+ (NSLayoutManager*)	textOnPathLayoutManager;

// drawing text along a path - high level methods that use a default layout manager and don't use a cache:

- (BOOL)				drawTextOnPath:(NSAttributedString*) str yOffset:(float) dy;
- (BOOL)				drawStringOnPath:(NSString*) str;
- (BOOL)				drawStringOnPath:(NSString*) str attributes:(NSDictionary*) attrs;

// more advanced method called by the others allows use of different layout managers and cached information for better efficiency. If an object passes back the same
// cache each time, text-on-path rendering avoids recalculating several things. The caller is responsible for invalidating the cache if the actual string
// content to be drawn has changed, but the path will detect changes to itself automatically.

- (BOOL)				drawTextOnPath:(NSAttributedString*) str yOffset:(float) dy layoutManager:(NSLayoutManager*) lm cache:(NSMutableDictionary*) cache;

// obtaining the paths of the glyphs laid out on the path

- (NSArray*)			bezierPathsWithGlyphsOnPath:(NSAttributedString*) str yOffset:(float) dy;
- (NSBezierPath*)		bezierPathWithTextOnPath:(NSAttributedString*) str yOffset:(float) dy;

- (NSBezierPath*)		bezierPathWithStringOnPath:(NSString*) str;
- (NSBezierPath*)		bezierPathWithStringOnPath:(NSString*) str attributes:(NSDictionary*) attrs;

// low-level glyph layout method called by all other methods to generate the glyphs. The result depends on the helper object which must conform
// to the textOnPathPlacement informal protocol (see below)

- (BOOL)				layoutStringOnPath:(NSTextStorage*) str
							yOffset:(float) dy
							usingLayoutHelper:(id) helperObject
							layoutManager:(NSLayoutManager*) lm
							cache:(NSMutableDictionary*) cache;

- (void)				kernText:(NSTextStorage*) text toFitLength:(float) length;
- (NSTextStorage*)		preadjustedTextStorageWithString:(NSAttributedString*) str layoutManager:(NSLayoutManager*) lm;

// drawing underline and strikethrough paths

- (void)				drawUnderlinePathForLayoutManager:(NSLayoutManager*) lm yOffset:(float) dy cache:(NSMutableDictionary*) cache;
- (void)				drawStrikethroughPathForLayoutManager:(NSLayoutManager*) lm yOffset:(float) dy cache:(NSMutableDictionary*) cache;
- (void)				drawUnderlinePathForLayoutManager:(NSLayoutManager*) lm range:(NSRange) range yOffset:(float) dy cache:(NSMutableDictionary*) cache;
- (void)				drawStrikethroughPathForLayoutManager:(NSLayoutManager*) lm range:(NSRange) range yOffset:(float) dy cache:(NSMutableDictionary*) cache;

- (void)				pathPosition:(float*) start andLength:(float*) length forCharactersOfString:(NSAttributedString*) str inRange:(NSRange) range;
- (NSArray*)			descenderBreaksForString:(NSAttributedString*) str range:(NSRange) range underlineOffset:(float) offset;
- (NSBezierPath*)		textLinePathWithMask:(int) mask startPosition:(float) sp length:(float) length offset:(float) offset lineThickness:(float) lineThickness descenderBreaks:(NSArray*) breaks grotThreshold:(float) gt;

// getting text layout rects for running text within a shape

- (NSArray*)			intersectingPointsWithHorizontalLineAtY:(float) yPosition;
- (NSArray*)			lineFragmentRectsForFixedLineheight:(float) lineHeight;
- (NSRect)				lineFragmentRectForProposedRect:(NSRect) aRect remainingRect:(NSRect*) rem;
- (NSRect)				lineFragmentRectForProposedRect:(NSRect) aRect remainingRect:(NSRect*) rem datumOffset:(float) dOffset;

// drawing/placing/moving anything along a path:

- (NSArray*)			placeObjectsOnPathAtInterval:(float) interval factoryObject:(id) object userInfo:(void*) userInfo;
- (NSBezierPath*)		bezierPathWithObjectsOnPathAtInterval:(float) interval factoryObject:(id) object userInfo:(void*) userInfo;
- (NSBezierPath*)		bezierPathWithPath:(NSBezierPath*) path atInterval:(float) interval;

// placing "chain links" along a path:

- (NSArray*)			placeLinksOnPathWithLinkLength:(float) ll factoryObject:(id) object userInfo:(void*) userInfo;
- (NSArray*)			placeLinksOnPathWithEvenLinkLength:(float) ell oddLinkLength:(float) oll factoryObject:(id) object userInfo:(void*) userInfo;

// easy motion method:

- (void)				moveObject:(id) object atSpeed:(float) speed loop:(BOOL) loop userInfo:(id) userInfo;


@end



// informal protocol for placing objects at linear intervals along a bezier path. Will be called from placeObjectsOnPathAtInterval:withObject:userInfo:
// the <object> is called with this method if it implements it.

// the second method can be used to implement fluid motion along a path using the moveObject:alongPathDistance:inTime:userInfo: method.

// the links method is used to implement chain effects from the "placeLinks..." method.

@interface NSObject (BezierPlacement)

- (id)					placeObjectAtPoint:(NSPoint) p onPath:(NSBezierPath*) path position:(float) pos slope:(float) slope userInfo:(void*) userInfo;
- (BOOL)				moveObjectTo:(NSPoint) p position:(float) pos slope:(float) slope userInfo:(id) userInfo;
- (id)					placeLinkFromPoint:(NSPoint) pa toPoint:(NSPoint) pb onPath:(NSBezierPath*) path linkNumber:(int) lkn userInfo:(void*) userInfo;

@end


// when laying out glyphs on the path, a helper object with this informal protocol is used. The object can process the glyph appropriately, for example
// just drawing it after applying a transform, or accumulating the glyph path. An object implementing this protocol is passed internally by the text on
// path methods as necessary, or you can supply one. 

@interface NSObject (TextOnPathPlacement)

- (void)				layoutManager:(NSLayoutManager*) lm willPlaceGlyphAtIndex:(unsigned) glyphIndex atLocation:(NSPoint) location pathAngle:(float) angle yOffset:(float) dy;

@end




// helper objects used internally when accumulating or laying glyphs

@interface DKTextOnPathGlyphAccumulator	: NSObject
{
	NSMutableArray*		mGlyphs;
}

- (NSArray*)			glyphs;
- (void)				layoutManager:(NSLayoutManager*) lm willPlaceGlyphAtIndex:(unsigned) glyphIndex atLocation:(NSPoint) location pathAngle:(float) angle yOffset:(float) dy;

@end



// this just applies the transform and causes the layout manager to draw the glyph. This ensures that all the stylistic variations on the glyph are applied allowing
// attributed strings to be drawn along the path.

@interface DKTextOnPathGlyphDrawer	: NSObject

- (void)				layoutManager:(NSLayoutManager*) lm willPlaceGlyphAtIndex:(unsigned) glyphIndex atLocation:(NSPoint) location pathAngle:(float) angle yOffset:(float) dy;

@end



// this helper calculates the start and length of a given run of characters in the string. The character range should be set prior to use. As each glyph is laid, the
// glyph run position and length along the line fragment rectangle is calculated.

@interface DKTextOnPathMetricsHelper : NSObject
{
	float		mStartPosition;
	float		mLength;
	NSRange		mCharacterRange;
}

- (void)				setCharacterRange:(NSRange) range;
- (float)				length;
- (float)				position;
- (void)				layoutManager:(NSLayoutManager*) lm willPlaceGlyphAtIndex:(unsigned) glyphIndex atLocation:(NSPoint) location pathAngle:(float) angle yOffset:(float) dy;

@end



// this is a small wrapper object used to cache information about locations on a path, to save recalculating them each time.

@interface DKPathGlyphInfo : NSObject
{
	unsigned	mGlyphIndex;
	NSPoint		mPoint;
	float		mSlope;
}

- (id)			initWithGlyphIndex:(unsigned) glyphIndex position:(NSPoint) pt slope:(float) slope;
- (unsigned)	glyphIndex;
- (float)		slope;
- (NSPoint)		point;


@end



// category on NSFont used to fudge the underline offset for invalid fonts. Apparently this is what Apple do also, though currently the
// definition of "invalid font" is not known with any precision. Currently underline offsets of 0 will use this value instead

@interface NSFont (DKUnderlineCategory)

- (float)	valueForInvalidUnderlinePosition;
- (float)	valueForInvalidUnderlineThickness;

@end


