//
//  NSBezierPath+Text.m
//  GCDrawKit
//
//  Created by graham on 05/02/2009.
//  Copyright 2009 Apptree.net. All rights reserved.
//

#import "NSBezierPath+Text.h"
#import "NSBezierPath+Geometry.h"
#import "NSBezierPath+Editing.h"
#import "DKGeometryUtilities.h"
#import "DKBezierLayoutManager.h"
#import "DKDrawKitMacros.h"

#include <math.h>

@interface NSBezierPath (TextOnPathPrivate)

- (void)				motionCallback:(NSTimer*) timer;

@end

// keys used for data in private cache

static NSString* kDKTextOnPathGlyphPositionCacheKey			= @"DKTextOnPathGlyphPositions";
static NSString* kDKTextOnPathChecksumCacheKey				= @"DKTextOnPathChecksum";
static NSString* kDKTextOnPathTextFittedCacheKey			= @"DKTextOnPathTextFitted";

@implementation NSBezierPath (TextOnPath)


+ (NSLayoutManager*)	textOnPathLayoutManager
{
	// returns a layout manager instance which is used for all text on path layout tasks. Reusing this shared instance saves a little time and memory
	
	static NSLayoutManager*	topLayoutMgr = nil;
	
	if( topLayoutMgr == nil )
	{
		topLayoutMgr = [[NSLayoutManager alloc] init];
		NSTextContainer* tc = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize( 1.0e6, 1.0e6 )];
		[topLayoutMgr addTextContainer:tc];
		[tc release];
		
		[topLayoutMgr setUsesScreenFonts:NO];
	}
	
	return topLayoutMgr;
}



- (BOOL)				drawTextOnPath:(NSAttributedString*) str yOffset:(float) dy
{
	return [self drawTextOnPath:str yOffset:dy layoutManager:nil cache:nil];
}


- (BOOL)				drawTextOnPath:(NSAttributedString*) str yOffset:(float) dy layoutManager:(NSLayoutManager*) lm cache:(NSMutableDictionary*) cache
{
	// draws the string along the path in the current view or context, which is assumed to be flipped. All attributes applied to the string are drawn with the
	// exception of strikethroughs and underlines, which are handled separately to ensure that they appear smooth and unbroken.
	
	// the <cache> parameter is an optional mutable dictionary, which, if present, the text on path layout code may stash various items to prevent lengthy
	// recalculation. The cache must be owned by the external client code, and passed in each time. The client code is responsible for invalidating the
	// cache when it knows that the text data has changed in a way that would invalidate its layout. Invalidation requires simply removing all of the cache's content.
	// Passing nil for <cache> will work normally but naturally no information will be cached.
	
	unsigned	cachedCS = [[cache objectForKey:kDKTextOnPathChecksumCacheKey] intValue];
	unsigned	CS = [self checksum];
	
	if( cachedCS != CS )
	{
		// path has changed so cache is unreliable.
		//NSLog(@"cs mismatch, invalidating cache (old = %@, new cs = %d)", cache, CS );
		
		// don't remove if value is 0, as that implies cache was already cleared externally, and may contain other informaiton of importance or
		// use the the external client (Alternatively we should remove only the keys that we know are ours, but this is currently quite hard due to the
		// dynamic nature of some of the keys, and the fact that the items are not grouped in any way.).
		
		if( cachedCS != 0 )
			[cache removeAllObjects];
		
		[cache setObject:[NSNumber numberWithInt:CS] forKey:kDKTextOnPathChecksumCacheKey];
	}
	
	BOOL usingStandardLM = NO;
	
	if( lm == nil )
	{
		lm = [[self class] textOnPathLayoutManager];
		usingStandardLM = YES;
	}
	
	NSTextStorage* text = [self preadjustedTextStorageWithString:str layoutManager:lm];
	
	[self drawUnderlinePathForLayoutManager:lm yOffset:dy cache:cache];

	// remove underline and strikethrough attributes from what the layout will use so they aren't drawn again:
	
	[text removeAttribute:NSUnderlineStyleAttributeName range:NSMakeRange( 0, [text length])];
	
	//FIXME: Add removeAttribute:NSStrikethroughStyleAttributeName to GNUstep
	//[text removeAttribute:NSStrikethroughStyleAttributeName range:NSMakeRange( 0, [text length])];
	
	DKTextOnPathGlyphDrawer* gd = [[DKTextOnPathGlyphDrawer alloc] init];
	BOOL result = [self layoutStringOnPath:text yOffset:dy usingLayoutHelper:gd layoutManager:lm cache:cache];
	[gd release];
	
	// draw strikethrough attributes based on the original string
	
	if( usingStandardLM )
	{
		text = [self preadjustedTextStorageWithString:str layoutManager:lm];
		[self drawStrikethroughPathForLayoutManager:lm yOffset:dy cache:cache];
	}
	
	return result;
}


- (BOOL)				drawStringOnPath:(NSString*) str
{
	// draws a string along the path with the default attributes, which are Helvetica Roman 12 pt black.
	
	return [self drawStringOnPath:str attributes:nil];
}


- (BOOL)				drawStringOnPath:(NSString*) str attributes:(NSDictionary*) attrs;
{
	// draws a string along the path with the supplied attributes
	
	if ( attrs == nil )
	{
		NSFont *font = [NSFont fontWithName:@"Helvetica" size:12.0];
		attrs = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
	}
	
	NSAttributedString* as = [[NSAttributedString alloc] initWithString:str attributes:attrs];
	BOOL result = [self drawTextOnPath:as yOffset:0];
	[as release];
	
	return result;
}



- (NSBezierPath*)		bezierPathWithTextOnPath:(NSAttributedString*) str yOffset:(float) dy
{
	// returns the laid out glyphs as a single path for the entire laid out string
	
	NSEnumerator*	iter = [[self bezierPathsWithGlyphsOnPath:str yOffset:dy] objectEnumerator];
	NSBezierPath*	path = [NSBezierPath bezierPath];
	NSBezierPath*	temp;
	
	while(( temp = [iter nextObject]))
		[path appendBezierPath:temp];
	
	return path;
}


- (NSArray*)			bezierPathsWithGlyphsOnPath:(NSAttributedString*) str yOffset:(float) dy
{
	// returns the laid out glyphs as an array of separate paths
	
	DKTextOnPathGlyphAccumulator* ga = [[[DKTextOnPathGlyphAccumulator alloc] init] autorelease];
	NSLayoutManager* lm = [[self class] textOnPathLayoutManager];
	NSTextStorage* text = [self preadjustedTextStorageWithString:str layoutManager:lm];
	
	[self layoutStringOnPath:text yOffset:dy usingLayoutHelper:ga layoutManager:lm cache:nil];
	return [ga glyphs];
}


- (NSBezierPath*)		bezierPathWithStringOnPath:(NSString*) str
{
	// returns the path of the string laid out on the path with default attributes
	
	return [self bezierPathWithStringOnPath:str attributes:nil];
}


- (NSBezierPath*)		bezierPathWithStringOnPath:(NSString*) str attributes:(NSDictionary*) attrs
{
	// returns the path of the laid out string with the given attributes
	
	NSAttributedString* as = [[NSAttributedString alloc] initWithString:str attributes:attrs];
	NSBezierPath*		np = [self bezierPathWithTextOnPath:as yOffset:0];
	[as release];
	return np;
}



- (BOOL)				layoutStringOnPath:(NSTextStorage*) str
								yOffset:(float) dy
								usingLayoutHelper:(id) helperObject
								layoutManager:(NSLayoutManager*) lm
								cache:(NSMutableDictionary*) cache
{
	// this method does all the actual work of glyph generation and positioning of the glyphs along the path. It is called by all other methods. The helper object
	// does the appropriate thing, either adding the glyph outline to a list or actually drawing the glyph. Note that the glyph layout is handled by the layout
	// manager as usual, but the helper is responsible for the last step.
	
	// return value is YES if all the text was laid out, NO if it couldn't be laid out within the available length of the path
	
	if([self elementCount] < 2 || [str length] < 1 )
		return NO;	// nothing useful to do
	
	// if the helper is invalid, throw exception
	
	NSAssert( helperObject != nil, @" cannot proceed without a valid helper object");
	NSAssert( lm != nil, @"cannot proceed without a valid layout manager");
	
	if(![helperObject respondsToSelector:@selector(layoutManager:willPlaceGlyphAtIndex:atLocation:pathAngle:yOffset:)])
		[NSException raise:NSInternalInconsistencyException format:@"The helper object does not implement the TextOnPathPlacement informal protocol"];
		
	// set the line break mode to clipping - this prevents unwanted wrapping of the text if the path is too short
	
	NSMutableParagraphStyle* para = [[[str attributesAtIndex:0 effectiveRange:NULL] valueForKey:NSParagraphStyleAttributeName] mutableCopy];
	[para setLineBreakMode:NSLineBreakByClipping];
	
	if( para )
	{
		NSDictionary* attrs = [NSDictionary dictionaryWithObject:para forKey:NSParagraphStyleAttributeName];
		[str addAttributes:attrs range:NSMakeRange(0,[str length])];
		[para release];
	}
	
	NSTextContainer*	tc = [[lm textContainers] lastObject];
	NSBezierPath*		temp;
	unsigned			glyphIndex;
	NSRect				gbr;
	BOOL				result = YES;
	
	gbr.origin = NSZeroPoint;
	gbr.size = [tc containerSize];
	
	NSRange glyphRange = [lm glyphRangeForBoundingRect:gbr inTextContainer:tc];
	
	// all the layout positions and angles may be cached for more performance. An array of previously calculated glyph positions can be retrieved and
	// simply iterated to lay out the glyphs.
	
	NSArray* glyphCache = [cache objectForKey:kDKTextOnPathGlyphPositionCacheKey];
	
	if( glyphCache == nil )
	{
		// not cached, so work it out and cache it this time
		
		NSMutableArray*			newGlyphCache = [NSMutableArray array];
		DKPathGlyphInfo*		posInfo;
		float					baseline;		
		
		// lay down the glyphs along the path
	
		for ( glyphIndex = glyphRange.location; glyphIndex < NSMaxRange(glyphRange); ++glyphIndex )
		{
			NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
			
			NSRect		lineFragmentRect = [lm lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:NULL];
			NSPoint		viewLocation, layoutLocation = [lm locationForGlyphAtIndex:glyphIndex];
			
			// if this represents anything other than the first line, ignore it
			
			if( lineFragmentRect.origin.y > 0.0 )
			{
				result = NO;
				break;
			}
			
			gbr = [lm boundingRectForGlyphRange:NSMakeRange( glyphIndex, 1) inTextContainer:tc];
			float half = NSWidth( gbr ) * 0.5f;
			
			// if the character width is zero or -ve, skip it - some control glyphs appear to need suppressing in this way
			
			if ( half > 0 )
			{
				// get a shortened path that starts at the character location
				
				temp = [self bezierPathByTrimmingFromLength:NSMinX( lineFragmentRect ) + layoutLocation.x + half];
				
				// if no more room on path, stop laying glyphs
				
				if ([temp length] < half )
				{
					result = NO;
					break;
				}
				
				[temp elementAtIndex:0 associatedPoints:&viewLocation];
				float angle = [temp slopeStartingPath];
				
				// view location needs to be offset vertically normal to the path to account for the baseline
			
				// FIXME: GNUstep lacks NSTypesetter
				baseline = NSHeight( gbr );// baseline = NSHeight( gbr ) - [[lm typesetter] baselineOffsetInLayoutManager:lm glyphIndex:glyphIndex];
				
				viewLocation.x -= baseline * cosf( angle + NINETY_DEGREES );
				viewLocation.y -= baseline * sinf( angle + NINETY_DEGREES );
				
				// view location needs to be projected back along the baseline tangent by half the character width to align
				// the character based on the middle of the glyph instead of the left edge
				
				viewLocation.x -= half * cosf( angle );
				viewLocation.y -= half * sinf( angle );
				
				// cache the glyph positioning information to avoid recalculation next time round
				
				posInfo = [[DKPathGlyphInfo alloc] initWithGlyphIndex:glyphIndex position:viewLocation slope:angle];
				[newGlyphCache addObject:posInfo];
				[posInfo release];
				
				// call the helper object to finish off what we intend to do with this glyph
				
				[helperObject layoutManager:lm willPlaceGlyphAtIndex:glyphIndex atLocation:viewLocation pathAngle:angle yOffset:dy];
			}
			
			[pool drain];
		}
		
		[cache setObject:newGlyphCache forKey:kDKTextOnPathGlyphPositionCacheKey];
		[cache setObject:[NSNumber numberWithBool:result] forKey:kDKTextOnPathTextFittedCacheKey];
	}
	else
	{
		//NSLog(@"drawing from cache, %d glyphs", [glyphCache count]);
		// glyph layout info was cached, so all we need do is to feed the information to the helper object
		
		DKPathGlyphInfo* info;
		NSEnumerator* iter = [glyphCache objectEnumerator];
		
		while(( info = [iter nextObject]))
			[helperObject layoutManager:lm willPlaceGlyphAtIndex:[info glyphIndex] atLocation:[info point] pathAngle:[info slope] yOffset:dy];
		
		result = [[cache objectForKey:kDKTextOnPathTextFittedCacheKey] boolValue];
	}
	
	return result;
}


- (void)				kernText:(NSTextStorage*) text toFitLength:(float) length
{
	// adjusts the kerning of the text passed so that it fits exactly into <length>
	
	NSAssert( text != nil, @"oops, text storage was nil");
	
	NSLayoutManager*	lm = [[text layoutManagers] lastObject];
	NSTextContainer*	tc = [[lm textContainers] lastObject];
	NSRect				gbr;
	
	gbr.size = NSMakeSize(length, 50000.0);
	gbr.origin = NSZeroPoint;
	
	// set container size so that the width is the path's length - this will honour left/right/centre paragraphs setting
	// and truncate at the end of the last whole word that can be fitted.
	
	[tc setContainerSize:gbr.size];
	NSRange glyphRange = [lm glyphRangeForBoundingRect:gbr inTextContainer:tc];
	
	// if we are kerning to fit, calculate the kerning amount needed and set it up
	
	NSRect fragRect = [lm lineFragmentUsedRectForGlyphAtIndex:0 effectiveRange:NULL];
	float kernAmount = (gbr.size.width - fragRect.size.width) / (float)(glyphRange.length - 1);
	
	if( kernAmount <= 0 )
	{
		// to squeeze the text down, we now need to know how much space the line would require if the text container weren't constraining it.
		
		NSSize strSize = [text size];
		kernAmount = (gbr.size.width - strSize.width)/ (float)(glyphRange.length - 1);
		
		// limit the amount to keep text readable. Once the limit is hit, the text will get clipped off beyond the end of the path.
		// the limit is related to the point size of the glyph which in turn is already encoded in the line height. The value here is
		// derived empirically to give text that is just about readable at the limit.
		
		float kernLimit = strSize.height * -0.15;
		
		if( kernAmount < kernLimit )
			kernAmount = kernLimit;
	}
	
	NSDictionary*	kernAttributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:kernAmount] forKey:NSKernAttributeName];
	NSRange charRange = [lm characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
	[text addAttributes:kernAttributes range:charRange];
}


- (NSTextStorage*)		preadjustedTextStorageWithString:(NSAttributedString*) str layoutManager:(NSLayoutManager*) lm
{
	// returns text storage with the layout manager added, set up to the path width, and if so required, prekerned to fit the path.
	
	NSAssert( lm != nil, @"nil layout manager passed while processing text on path");
	NSAssert( str != nil, @"nil string passed while processing text on path");
	
	NSTextContainer*	tc = [[lm textContainers] lastObject];

	NSAssert( tc != nil, @" no text container was present in the layout manager");
	
	// determine whether the text needs to be kerned to fit - yes if the alignment is 'justified'

	NSParagraphStyle* para = [str attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:NULL];
	BOOL autoKern = ([para alignment] == NSJustifiedTextAlignment);
	
	NSTextStorage* text = [[NSTextStorage alloc] initWithAttributedString:str];
	[text addLayoutManager:lm];
	
	// wrap the text within the line length but set the height to some arbitrarily large value.
	// lines beyond the first are ignored anyway, regardless of lineheight.
	
	float pathLength = [self length];
	
	// set container size so that the width is the path's length - this will honour left/right/centre paragraphs setting
	// and truncate at the end of the last whole word that can be fitted.
	
	[tc setContainerSize:NSMakeSize( pathLength, 50000 )];
	
	// apply kerning to fit if necessary
	
	if( autoKern )
		[self kernText:text toFitLength:pathLength];
	
	return [text autorelease];
}




- (void)				drawUnderlinePathForLayoutManager:(NSLayoutManager*) lm yOffset:(float) dy cache:(NSMutableDictionary*) cache
{
	// draws underline for the text <str> on this path. The path has the requisite dash pattern, etc. and number. The caller
	// still needs to get the underline colour to use. Note that this is not guaranteed to give identical results to Apple's own interpretation of the
	// attributes, but is intended to get as close as possible.
	
	NSRange			effectiveRange = NSMakeRange( 0, 0 );
	unsigned		rangeLimit = 0;
	NSNumber*		ul;
	
	while( rangeLimit < [[lm textStorage] length])
	{
		ul = [[lm textStorage] attribute:NSUnderlineStyleAttributeName atIndex:rangeLimit effectiveRange:&effectiveRange];
		
		if( ul && [ul intValue] > 0 )
			[self drawUnderlinePathForLayoutManager:lm range:effectiveRange yOffset:dy cache:cache];
		
		rangeLimit = NSMaxRange( effectiveRange );
	}
}


- (void)				drawStrikethroughPathForLayoutManager:(NSLayoutManager*) lm yOffset:(float) dy cache:(NSMutableDictionary*) cache
{
	// draws strikethrough for the text <str> on this path. The path has the requisite dash pattern, etc. and number. The caller
	// still needs to get the underline colour to use. Note that this is not guaranteed to give identical results to Apple's own interpretation of the
	// attributes, but is intended to get as close as possible.
	
	//FIXME: GNUstep lacks NSStrikethroughStyleAttributeName
	#if 0
	NSRange			effectiveRange = NSMakeRange( 0, 0 );
	unsigned		rangeLimit = 0;
	NSNumber*		ul;
	
	while( rangeLimit < [[lm textStorage] length])
	{
		ul = [[lm textStorage] attribute:NSStrikethroughStyleAttributeName atIndex:rangeLimit effectiveRange:&effectiveRange];
		
		if( ul && [ul intValue] > 0 )
			[self drawStrikethroughPathForLayoutManager:lm range:effectiveRange yOffset:dy cache:cache];
		
		rangeLimit = NSMaxRange( effectiveRange );
	}
	#endif
}


- (void)				drawUnderlinePathForLayoutManager:(NSLayoutManager*) lm range:(NSRange) range yOffset:(float) dy cache:(NSMutableDictionary*) cache
{
	// FIXME: do nothing because GNUstep is missing some things needed here
	#if 0
	// underlines the given range of characters of <str> by offsetting the path by <dy> and stroking it using stroke attributes
	// derved from the font and other information.
	
	NSAttributedString* str = [lm textStorage];
	NSFont*				font = [str attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL]; // UL thickness taken from first character on line regardless
	int					ulAttribute = [[str attribute:NSUnderlineStyleAttributeName atIndex:range.location effectiveRange:NULL] intValue];
	float				ulOffset, ulThickness = [font underlineThickness];
	float				start, length, grot;
	NSBezierPath*		ulp;
	
	// see if the path we need is cached, in which case we can avoid recomputing it. Because there could be several different paths that apply to ranges,
	// the cache key is generated from the various parameters
	
	NSString* pathKey = [NSString stringWithFormat:@"DKUnderlinePath_%@_%.2f", NSStringFromRange( range ), dy];
	ulp = [cache objectForKey:pathKey];
	
	if( ulp == nil )
	{
		// Apple's text rendering appears to ignore the font's underlinePosition and instead relies on some internal magic in NSTypesetter. For parity, we'll try and
		// do the same. By trial and error it appears as if the underline position is set to half the baseline offset returned by the typesetter. However this must ignore
		// any subscripted parts which don't affect the underline (but do break it).
		
		// layout without superscripts and subscripts:
		
		NSLayoutManager* tempLM = [[NSLayoutManager alloc] init];
		[tempLM addTextContainer:[[lm textContainers] lastObject]];
		NSTextStorage* tempStr = [[NSTextStorage alloc] initWithAttributedString:str];
		[tempStr removeAttribute:NSSuperscriptAttributeName range:NSMakeRange( 0, [tempStr length])];
		[tempStr addLayoutManager:tempLM];
		[tempLM release];
		
		unsigned glyphIndex = [tempLM glyphIndexForCharacterAtIndex:range.location];
		//FIXME: GNUstep lacks NSTypesetter
		ulOffset = [font underlinePosition]; //[[tempLM typesetter] baselineOffsetInLayoutManager:tempLM glyphIndex:glyphIndex] * -0.5f;
		
		[tempStr release];
		
		// if the underline metrics aren't set for the font, use an average of those for Times + Helvetica for the same point size. According to Apple that's what
		// they do, though it's not clear if just a value of 0 is considered bad, as there are discrepancies with certain fonts.
		
		if( ulThickness <= 0 )
			ulThickness = [font valueForInvalidUnderlineThickness];
		
		[self pathPosition:&start andLength:&length forCharactersOfString:str inRange:range];
		
		// breaks can also be cached separately. It's unusual that the breaks would exist without the path in the cache, but we'll permit that to
		// be possible.
		
		NSArray* descenderBreaks;
		NSString* breaksKey = [NSString stringWithFormat:@"DKUnderlineBreaks_%@_%.2f", NSStringFromRange( range ), ulOffset];
		descenderBreaks = [cache objectForKey:breaksKey];
		
		if( descenderBreaks == nil )
		{
			descenderBreaks = [self descenderBreaksForString:str range:range underlineOffset:ulOffset];
			if( descenderBreaks )
				[cache setObject:descenderBreaks forKey:breaksKey];
		}
		
		//NSLog(@"descender breaks; %@", descenderBreaks);
		//NSLog(@"will draw underline from: %.3f to: %.3f; path length = %.3f, character range = %@", start, start + length, [self length], NSStringFromRange( range ));
		
		// to arrive at a sensible grot value, we need some measure of the average character width of the string. To do this we take the width of the glyph run
		// and divide by the number of characters in the range, and then apply a scaling.
		
		NSPoint glyphPosition = [lm locationForGlyphAtIndex:glyphIndex];
		
		float runWidth = glyphPosition.x;
		glyphIndex = [lm glyphIndexForCharacterAtIndex:NSMaxRange(range) - 1];
		glyphPosition = [lm locationForGlyphAtIndex:glyphIndex];
		runWidth = glyphPosition.x - runWidth;
		
		grot = ( runWidth * 0.67 ) / (float)( range.length - 1 );
		
		ulp = [self textLinePathWithMask:ulAttribute
						   startPosition:start
								  length:length
								  offset:dy + ulOffset
						   lineThickness:ulThickness
						 descenderBreaks:descenderBreaks
						   grotThreshold:grot];
		
		if( ulp )
			[cache setObject:ulp forKey:pathKey];
	}
	//else
	//	NSLog(@"drawing cached underline path (cache key = %@)", pathKey );
	
	// what colour to draw it in. Unless explicitly set, use foreground colour.
	
	NSColor* ulc = [str attribute:NSUnderlineColorAttributeName atIndex:range.location effectiveRange:NULL];
	
	if( ulc == nil )
		ulc = [str attribute:NSForegroundColorAttributeName atIndex:range.location effectiveRange:NULL];
	
	if( ulc == nil )
		ulc = [NSColor blackColor];
	
	// any text shadow?
	
	//FIXME: Implement NSShadow in GNUstep
	//NSShadow* shad = [str attribute:NSShadowAttributeName atIndex:range.location effectiveRange:NULL];
	
	SAVE_GRAPHICS_CONTEXT
	
	if( shad )
		[shad set];
	
	[ulc set];
	[ulp stroke];
	
	RESTORE_GRAPHICS_CONTEXT
	#endif
}


- (void)				drawStrikethroughPathForLayoutManager:(NSLayoutManager*) lm range:(NSRange) range yOffset:(float) dy cache:(NSMutableDictionary*) cache
{
	// FIXME: disabled for now; gnustep lacks attribute:NSStrikethroughStyleAttributeName

	#if 0

	// draws the strikethrough for the range of characters of the given string
	
	NSAttributedString* str = [lm textStorage];
	NSFont*				font = [str attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
	int					ulAttribute = [[str attribute:NSStrikethroughStyleAttributeName atIndex:range.location effectiveRange:NULL] intValue];
	float				start, length;
	float				xHeight = [font xHeight];
	float				ulThickness = [font underlineThickness];
	NSBezierPath*		ulp;
	
	// see if we can reuse a previously cached path here
	
	NSString* pathKey = [NSString stringWithFormat:@"DKStrikethroughPath_%@_%.2f", NSStringFromRange( range ), dy];
	ulp = [cache objectForKey:pathKey];
	
	if( ulp == nil )
	{
		// calculate the strikethrough position. Must take into account the true baseline of the glyphs because
		// if they are superscripted, the strikethrough must be positioned accordingly.
		
		unsigned glyphIndex = [lm glyphIndexForCharacterAtIndex:range.location];
		NSRect gbr = [lm boundingRectForGlyphRange:NSMakeRange( glyphIndex, 1) inTextContainer:[[lm textContainers] lastObject]];
		
		//FIXME: GNUstep lacks NSTypesetter
		//float base = NSHeight( gbr ) - [[lm typesetter] baselineOffsetInLayoutManager:lm glyphIndex:glyphIndex];
		float base = NSHeight( gbr );		

		NSPoint loc = [lm locationForGlyphAtIndex:glyphIndex];
		
		base -= loc.y;
		
		[self pathPosition:&start andLength:&length forCharactersOfString:str inRange:range];
		
		ulp = [self textLinePathWithMask:ulAttribute
						   startPosition:start
								  length:length
								  offset:base + dy + ( xHeight * 0.5f )
						   lineThickness:ulThickness
						 descenderBreaks:nil
						   grotThreshold:0];
		
		if( ulp )
			[cache setObject:ulp forKey:pathKey];
	}
	
	// what colour to draw it in. Unless explicitly set, use foreground colour.
	
	NSColor* ulc = [str attribute:NSStrikethroughColorAttributeName atIndex:range.location effectiveRange:NULL];
	
	if( ulc == nil )
		ulc = [str attribute:NSForegroundColorAttributeName atIndex:range.location effectiveRange:NULL];
	
	if( ulc == nil )
		ulc = [NSColor blackColor];
	
	// any text shadow?
	
	//FIXME: Implement NSShadow in GNUstep
	//NSShadow* shad = [str attribute:NSShadowAttributeName atIndex:range.location effectiveRange:NULL];
	
	SAVE_GRAPHICS_CONTEXT
	
	//if( shad )
	//	[shad set];

	[ulc set];
	[ulp stroke];
	
	RESTORE_GRAPHICS_CONTEXT

	#endif
}


- (void)				pathPosition:(float*) start andLength:(float*) length forCharactersOfString:(NSAttributedString*) str inRange:(NSRange) range
{
	// returns by reference the starting position and length of the path that correspond to the given range of characters in the string. This takes into account
	// paragraph style attributes of the string as well as font and other information to accurately determine the path range that the characters fall against. This
	// is used to calculate where runs of underlines, etc should be placed.
	
	if( start == NULL || length == NULL )
		return;
	
	DKTextOnPathMetricsHelper* mh = [[DKTextOnPathMetricsHelper alloc] init];
	[mh setCharacterRange:range];
	
	[self layoutStringOnPath:(NSTextStorage*)str yOffset:0 usingLayoutHelper:mh layoutManager:[[self class] textOnPathLayoutManager] cache:nil];
	
	*start = [mh position];
	*length = [mh length];
	
	[mh release];
}


- (NSArray*)			descenderBreaksForString:(NSAttributedString*) str range:(NSRange) range underlineOffset:(float) offset
{
	// returns a list of NSPoint values which are the places where an underline attribute intersects the descenders of <str> within <range>.
	// This works by obtaining the path of the glyphs in the range then intersecting the underline Y offset with it. As such it's likely to be slow.
	// The offsets are relative to the beginning of the text. The <offset<> is the distance from the baseline to the underline as derived from the
	// font in use.
	
	NSTextStorage* subString = [[NSTextStorage alloc] initWithAttributedString:[str attributedSubstringFromRange:range]];
	
	DKBezierLayoutManager* lm = [[DKBezierLayoutManager alloc] init];
	NSTextContainer* btc = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(1.0e6, 1.0e6 )];
	[lm addTextContainer:btc];
	[subString setAlignment:NSLeftTextAlignment range:NSMakeRange( 0, range.length )];
	[subString addLayoutManager:lm];
	
	NSRange glyphRange = [lm glyphRangeForTextContainer:btc];
	[lm drawGlyphsForGlyphRange:glyphRange atPoint:NSZeroPoint];
	
	// find the baseline for the glyph which is where the underline is placed relative to
	
	// FIXME: GNUstep lacks NSTypesetter

	float baseline = 0.0f; //[[lm typesetter] baselineOffsetInLayoutManager:lm glyphIndex:glyphRange.location];
	NSRect lineFrag = [lm lineFragmentRectForGlyphAtIndex:glyphRange.location effectiveRange:NULL];
	float yOffset = NSHeight( lineFrag ) - baseline + fabs(offset);
	
	NSBezierPath* glyphPath = [lm textPath];
	NSArray* result = [[glyphPath intersectingPointsWithHorizontalLineAtY:yOffset] retain];
	
	[btc release];
	[lm release];
	[subString release];
	
	return [result autorelease];
}

#define DESCENDER_BREAK_PADDING		3
#define DESCENDER_BREAK_OFFSET		-5

- (NSBezierPath*)		textLinePathWithMask:(int) mask
						  startPosition:(float) sp
								 length:(float) length
								 offset:(float) offset
						  lineThickness:(float) lineThickness
						descenderBreaks:(NSArray*) breaks
						  grotThreshold:(float) gt
{
	// returns a single path extending from <sp> to <sp + length>, laterally offset by <offset> and having the attributes suggested by <mask>. If any descender breaks
	// have been passed in, the path is broken into separate sections leaving a gap at the break.
	
	// the "grotThreshold" <gt> is a limit value where any fragments of underline less than this are not included. It's used to avoid bits of "grot" appearing between
	// descenders of a character for a cleaner underline, and is based on the average character width.
	
	// extract the path we are based on. Note: underline by word is not yet supported.
	
	if(( mask & 0x0F ) == NSUnderlineStyleNone )
		return nil;
	
	// line width is between 3 and 4% of the point size
	// if we require a double line, add another offset path. The mask is 0x09 (1001) but the lower 1 indicates the first line, so we mask with 8 (1000).
	
	BOOL	isDouble = ( mask & 0x08 );
	
	if(mask & NSUnderlineStyleThick)
		lineThickness *= 2.0;
	
	if( isDouble )
	{
		lineThickness *= 0.75f;
		offset += (lineThickness * 0.5f );
	}
	
	NSBezierPath* trimmedPath; 
	
	// factor in any descender breaks if we have them. Each break alternates between the start of a break and the resumption of the line.
	
	if( breaks && [breaks count] > 0 )
	{
		NSEnumerator*	iter = [breaks objectEnumerator];
		NSValue*		breakVal;
		float			pos, breakOffset, padding;
		BOOL			hadFirst = NO;
		
		trimmedPath = [NSBezierPath bezierPath];
		pos = sp;
		
		padding = gt * 0.3;
		
		while(( breakVal = [iter nextObject]))
		{
			breakOffset = sp + [breakVal pointValue].x - padding + DESCENDER_BREAK_OFFSET;
			
			if(( breakOffset - pos ) > gt || !hadFirst)
				[trimmedPath appendBezierPath:[self bezierPathByTrimmingFromLength:pos toLength:breakOffset - pos]];
			
			breakVal = [iter nextObject];
			if( breakVal )
				pos = sp + [breakVal pointValue].x + padding + DESCENDER_BREAK_OFFSET;
			
			hadFirst = YES;
		}
		
		if(( sp + length - pos ) > gt || !hadFirst )
			[trimmedPath appendBezierPath:[self bezierPathByTrimmingFromLength:pos toLength:sp + length - pos]];
	}
	else
		trimmedPath = [self bezierPathByTrimmingFromLength:sp toLength:length];
	
	[trimmedPath setFlatness:0.1];
	float savedFlatness = [NSBezierPath defaultFlatness];
	[NSBezierPath setDefaultFlatness:0.1];
	
	// parallel offset has opposite sign to text offset
	
	trimmedPath = [trimmedPath paralleloidPathWithOffset2:-offset];
	[trimmedPath setLineWidth:lineThickness];
	
	if( isDouble )
	{
		NSBezierPath* bp = [trimmedPath paralleloidPathWithOffset2:2.0 * lineThickness];
		[trimmedPath appendBezierPath:bp];
	}
	
	[NSBezierPath setDefaultFlatness:savedFlatness];
	
	if( mask & 0x0F00 )
	{
		// some dash pattern is indicated, so work it out and apply it
		
		float	dashPattern[6];
		int		count = 0;
		
		switch( mask & 0x0F00 )
		{
			default:
			case NSUnderlinePatternDot:
				dashPattern[0] = dashPattern[1] = 1.0;
				count = 2;
				break;
				
			case NSUnderlinePatternDash:
				dashPattern[0] = 4.0;
				dashPattern[1] = 2.0;
				count = 2;
				break;
				
			case NSUnderlinePatternDashDot:
				dashPattern[0] = 4.0;
				dashPattern[1] = 2.0;
				dashPattern[2] = 1.0;
				dashPattern[3] = 2.0;
				count = 4;
				break;
				
			case NSUnderlinePatternDashDotDot:
				dashPattern[0] = 4.0;
				dashPattern[1] = 2.0;
				dashPattern[2] = 1.0;
				dashPattern[3] = 2.0;
				dashPattern[4] = 1.0;
				dashPattern[5] = 2.0;
				count = 6;
				break;
		}
		[trimmedPath setLineDash:dashPattern count:count phase:0.0];
	}
	
	return trimmedPath;
}



- (NSArray*)			placeObjectsOnPathAtInterval:(float) interval factoryObject:(id) object userInfo:(void*) userInfo
{
	// at each <interval> of distance, calls <object> with the placeObjectAtPoint... method and adds its result to the array. This can be
	// used to place a series of other objects along the path at a linear spacing.
	
	if( ![object respondsToSelector:@selector(placeObjectAtPoint:onPath:position:slope:userInfo:)])
		[NSException raise:NSInvalidArgumentException format:@"Factory object %@ does not implement the required protocol", object];

	if ([self elementCount] < 2 || interval <= 0 )
		return nil;
	
	NSMutableArray*		array = [[NSMutableArray alloc] init];
	NSPoint				p;
	float				slope, distance, length;
	id					placedObject;
	
	distance = 0;
	
	length = [self length];
	
	while( distance <= length )
	{
		p = [self pointOnPathAtLength:distance slope:&slope];
		
		placedObject = [object placeObjectAtPoint:p onPath:self position:distance slope:slope userInfo:userInfo];
		
		if ( placedObject )
			[array addObject:placedObject];
		
		distance += interval;
	}
	
	return [array autorelease];
}


- (NSBezierPath*)		bezierPathWithObjectsOnPathAtInterval:(float) interval factoryObject:(id) object userInfo:(void*) userInfo
{
	// as above, but where the returned objects are in themselves paths, they are appended into one general path and returned.
	
	if ([self elementCount] < 2 || interval <= 0 )
		return nil;
	
	NSBezierPath*	newPath = nil;
	NSArray*		placedObjects = [self placeObjectsOnPathAtInterval:interval factoryObject:object userInfo:userInfo];
	
	if ([placedObjects count] > 0 )
	{
		newPath = [NSBezierPath bezierPath];
		
		NSEnumerator*	iter = [placedObjects objectEnumerator];
		id				obj;
		
		while(( obj = [iter nextObject]))
		{
			if ([obj isKindOfClass:[NSBezierPath class]])
				[newPath appendBezierPath:obj];
		}
	}
	
	return newPath;
}


- (NSBezierPath*)		bezierPathWithPath:(NSBezierPath*) path atInterval:(float) interval
{
	// as above, but places copies of <path> along this path spaced at the interval <interval>. The path is rotated to match the slope of the
	// path at each point, but is not scaled. Each copy of the path is centred at the calculated location.
	
	if ([self elementCount] < 2 || interval <= 0 )
		return nil;
	
	NSBezierPath*		newPath = [NSBezierPath bezierPath];
	NSBezierPath*		temp;
	NSPoint				p, q;
	float				slope, distance, length;
	
	distance = 0;
	
	length = [self length];
	
	while( distance <= length )
	{
		p = [self pointOnPathAtLength:distance slope:&slope];
		
		temp = [path copy];
		
		// centre the path at <p> and rotate it to match <slope>
		
		q.x = NSMidX([temp bounds]);
		q.y = NSMidY([temp bounds]);
		
		NSAffineTransform* tfm = [NSAffineTransform transform];
		
		[tfm translateXBy:-q.x yBy:-q.y];
		[tfm rotateByRadians:slope];
		[tfm translateXBy:p.x yBy:p.y];
		
		[temp transformUsingAffineTransform:tfm];
		[newPath appendBezierPath:temp];
		[temp release];
		
		distance += interval;
	}
	
	return newPath;
}


- (NSArray*)			placeLinksOnPathWithLinkLength:(float) ll factoryObject:(id) object userInfo:(void*) userInfo
{
	return [self placeLinksOnPathWithEvenLinkLength:ll oddLinkLength:ll factoryObject:object userInfo:userInfo];
}


- (NSArray*)			placeLinksOnPathWithEvenLinkLength:(float) ell oddLinkLength:(float) oll factoryObject:(id) object userInfo:(void*) userInfo
{
	// similar to object placement, but treats the objects as "links" like in a chain, where a rigid link of a fixed length connects two points on the path.
	// The factory object is called with the pair of points computed, and returns a path representing the link between those two points. Non-nil results are
	// accumulated into the array returned. Even and odd links can have different lengths for added flexibility. Note that to keep this working quickly, the
	// link length is used as a path length to find the initial link pivot point, then the actual point is calculated by using the link radius in this direction.
	// The result can be that links will not exactly follow a very convoluted or curved path, but each link is guaranteed to be a fixed length and exactly
	// join to its neighbours.
	
	if( ![object respondsToSelector:@selector(placeLinkFromPoint:toPoint:onPath:linkNumber:userInfo:)])
		[NSException raise:NSInvalidArgumentException format:@"Factory object %@ does not implement the required protocol", object];
	
	if ([self elementCount] < 2 || ell <= 0 || oll <= 0 )
		return nil;
	
	NSMutableArray*		array = [[NSMutableArray alloc] init];
	int					linkCount = 0;
	NSPoint				prevLink;
	NSPoint				p = NSZeroPoint;
	float				distance, length, angle, radius;
	id					placedObject;
	
	distance = 0;
	length = [self length];
	prevLink = [self firstPoint];
	
	while( distance <= length )
	{
		// find an initial point
		
		if ( linkCount & 1 )
			radius = oll;
		else
			radius = ell;
		
		distance += radius;
		
		if ( distance <= length )
		{
			p = [self pointOnPathAtLength:distance slope:NULL];
			
			// point to use will be in this general direction but ensure link length is correct:
			
			angle = atan2( p.y - prevLink.y, p.x - prevLink.x );
			p.x = prevLink.x + ( cosf( angle ) * radius );
			p.y = prevLink.y + ( sinf( angle ) * radius );
			
			placedObject = [object placeLinkFromPoint:prevLink toPoint:p onPath:self linkNumber:linkCount++ userInfo:userInfo];
			
			if ( placedObject )
				[array addObject:placedObject];
		}
		prevLink = p;
	}
	
	return [array autorelease];
}



- (void)				moveObject:(id) object atSpeed:(float) speed loop:(BOOL) loop userInfo:(id) userInfo
{
	// moves an object along the path at the speed given, which is a value in pixels per second. The object must respond to the motion protocol.
	// This tries to maintain a 30 frames per second rate, calculating the distance moved using the actual time elapsed. This returns immediately
	// after starting the motion, which continues as the timer runs and there is remaining path to use, or if we are set to loop. The object being
	// moved can abort the motion at any time by returning NO.
	
	NSAssert( object != nil, @"can't move a nil object");
	
	if( ![object respondsToSelector:@selector(moveObjectTo:position:slope:userInfo:)])
		[NSException raise:NSInvalidArgumentException format:@"Moved object %@ does not implement the required protocol", object];

	if ([self elementCount] < 2 || speed <= 0 )
		return;
	
	if ( object )
	{
		// set the object's position to the start of the path initially
		
		NSPoint		where;
		float		slope;
		
		where = [self pointOnPathAtLength:0 slope:&slope];
		if([object moveObjectTo:where position:0 slope:slope userInfo:userInfo])
		{
			// set up a dictionary of parameters we can pass using the timer (allows many concurrent motions since there are no state variables
			// cached by the object)
			
			NSMutableDictionary*	parameters = [[NSMutableDictionary alloc] init];
			
			[parameters setObject:self forKey:@"path"];
			[parameters setObject:[NSNumber numberWithFloat:speed] forKey:@"speed"];
			
			if ( userInfo != nil )
				[parameters setObject:userInfo forKey:@"userinfo"];
			
			[parameters setObject:object forKey:@"target"];
			[parameters setObject:[NSNumber numberWithFloat:[self length]] forKey:@"path_length"];
			[parameters setObject:[NSNumber numberWithBool:loop] forKey:@"loop"];
			[parameters setObject:[NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]] forKey:@"start_time"];
			
			NSTimer*	t = [NSTimer timerWithTimeInterval:1.0/30.0 target:self selector:@selector(motionCallback:) userInfo:parameters repeats:YES];
			
			[parameters release];
			[[NSRunLoop currentRunLoop] addTimer:t forMode:NSEventTrackingRunLoopMode];
			[[NSRunLoop currentRunLoop] addTimer:t forMode:NSDefaultRunLoopMode];
		}
	}
}


- (void)				motionCallback:(NSTimer*) timer
{
	float			distance, speed, elapsedTime, length;
	BOOL			loop, shouldStop = NO;
	NSDictionary*	params = [timer userInfo];
	
	elapsedTime = [NSDate timeIntervalSinceReferenceDate] - [[params objectForKey:@"start_time"] floatValue];
	speed = [[params objectForKey:@"speed"] floatValue];
	
	distance = speed * elapsedTime;
	length = [[params objectForKey:@"path_length"] floatValue];
	loop = [[params objectForKey:@"loop"] boolValue];
	
	if ( !loop && distance > length )
	{
		distance = length;
		
		// reached the end of the path, so kill the timer if not looping
		
		shouldStop = YES;
	}
	else if ( loop )
		distance = fmodf( distance, length );
	
	// move the target object to the calculated point
	
	NSPoint		where;
	float		slope;
	id			obj = [params objectForKey:@"target"];
	
	where = [self pointOnPathAtLength:distance slope:&slope];
	shouldStop |= ![obj moveObjectTo:where position:distance slope:slope userInfo:[params objectForKey:@"userinfo"]];
	
	// if the target returns NO, it is telling us to stop immediately, whether or not we are looping
	
	if ( shouldStop )
		[timer invalidate];
}




NSInteger SortPointsHorizontally( id value1, id value2, void* context )
{
	NSPoint a, b;
	
	a = [value1 pointValue];
	b = [value2 pointValue];
	
	if( a.x > b.x )
		return NSOrderedDescending;
	else if ( a.x < b.x )
		return NSOrderedAscending;
	else
		return NSOrderedSame;
}


- (NSArray*)			intersectingPointsWithHorizontalLineAtY:(float) yPosition
{
	// given a y value within the bounds, this returns an array of points (as NSValues) which are the intersection of
	// a horizontal line extending across the full width of the shape at y and the curve itself. This works by approximating the curve as a series
	// of straight lines and testing each one for intersection with the line at y. This is the primitive method used to determine line layout
	// rectangles - a series of calls to this is needed for each line (incrementing y by the lineheight) and then rects forming from the
	// resulting points. See -lineFragmentRectsForFixedLineheight:
	
	// this is also used when calculating descender breaks for underlining text on a path.
	
	// this method is guaranteed to return an even number of (or none) results
	
	NSAssert( yPosition > 0.0, @"y value must be greater than 0");
	
	if([self isEmpty])
		return nil;		// nothing here, so bail
	
	NSRect br = [self bounds];
	
	// see if y is within the bounds - if not, there can't be any intersecting points so we can bail now.
	
	if( yPosition < NSMinY( br ) || yPosition > NSMaxY( br ))
		return nil;
	
	// set up the points for the horizontal line:
	
	br = NSInsetRect( br, -1, -1 );
	
	NSPoint hla, hlb;
	
	hla.y = hlb.y = yPosition;
	hla.x = NSMinX( br ) - 1;
	hlb.x = NSMaxX( br) + 1;
	
	// we can use a relatively coarse flatness for more speed - exact precision isn't needed for text layout.
	
	float savedFlatness = [self flatness];
	[self setFlatness:5.0];	
	NSBezierPath*	flatpath = [self bezierPathByFlatteningPath];
	[self setFlatness:savedFlatness];
	
	NSMutableArray*		result = [NSMutableArray array];
	int					i, m = [flatpath elementCount];
	NSBezierPathElement	lm;
	NSPoint				fp, lp, ap, ip;
	fp = lp = ap = ip = NSZeroPoint;
	
	for( i = 0; i < m; ++i )
	{
		lm = [flatpath elementAtIndex:i associatedPoints:&ap];
		
		if ( lm == NSMoveToBezierPathElement )
			fp = lp = ap;
		else
		{
			if( lm == NSClosePathBezierPathElement )
				ap = fp;
			
			ip = Intersection2( ap, lp, hla, hlb );
			lp = ap;
			
			// if the result is NSNotFoundPoint, lines are parallel and don't intersect. The intersection point may also fall outside the bounds,
			// so we discard that result as well.
			
			if( NSEqualPoints( ip, NSNotFoundPoint))
				continue;
			
			if ( NSPointInRect( ip, br ))
				[result addObject:[NSValue valueWithPoint:ip]];
		}
	}
	
	// if the result is not empty, sort the points into order horizontally
	
	if([result count] > 0 )
	{
		[result sortUsingFunction:SortPointsHorizontally context:NULL];
		
		// if the result is odd, it means that we don't have a closed path shape at the line position -
		// i.e. there's an open endpoint. So to ensure that we return an even number of items (or none),
		// delete the last item to make the result even.
		
		if(([result count] & 1) == 1)
		{
			[result removeLastObject];
			
			if([result count] == 0 )
				result = nil;
		}
	}
	else
		result = nil;	// nothing found, so just return nil
	
	return result;
}


- (NSArray*)			lineFragmentRectsForFixedLineheight:(float) lineHeight
{
	// given a lineheight value, this returns an array of rects (as NSValues) which are the ordered line layout rects from left to right and top to bottom
	// within the shape to layout text in. This is computationally intensive, so the result should probably be cached until the shape is actually changed.
	// This works with a fixed lineheight, where every line is the same.
	
	// Note that this method isn't really suitable for use with NSTextContainer or Cocoa's text system in general - for flowing text using NSLayoutManager use
	// DKBezierTextContainer which calls the -lineFragmentRectForProposedRect:remainingRect: method below.
	
	NSAssert( lineHeight > 0.0, @"lineheight must be positive and greater than 0");
	
	NSRect br = [self bounds];
	NSMutableArray*	result = [NSMutableArray array];
	
	// how many lines will fit in the shape?
	
	int lineCount = ( floor( NSHeight( br ) / lineHeight)) + 1;
	
	if( lineCount > 0 )
	{
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		NSArray*		previousLine = nil;
		NSArray*		currentLine;
		int				i;
		float			linePosition = NSMinY( br );
		NSRect			lineRect;
		
		lineRect.size.height = lineHeight;
		
		for( i = 0; i < lineCount; ++i )
		{
			lineRect.origin.y = linePosition;
			
			if ( i == 0 )
				previousLine = [self intersectingPointsWithHorizontalLineAtY:linePosition + 1];
			else
			{
				linePosition = NSMinY( br ) + (i * lineHeight);
				currentLine = [self intersectingPointsWithHorizontalLineAtY:linePosition];
				
				if( currentLine != nil )
				{
					// go through the points of the previous line and this one, forming rects
					// by taking the inner points
					
					unsigned j, ur, lr, rectsOnLine;
					
					ur = [previousLine count];
					lr = [currentLine count];
					
					rectsOnLine = MAX( ur, lr );
					
					for( j = 0; j < rectsOnLine; ++j )
					{
						NSPoint upper, lower;
						
						upper = [[previousLine objectAtIndex:j % ur] pointValue];
						lower = [[currentLine objectAtIndex:j % lr] pointValue];
						
						// even values of j are left edges, odd values are right edges
						
						if(( j & 1 ) == 0 )
							lineRect.origin.x = MAX( upper.x, lower.x );
						else
						{
							lineRect.size.width = MIN( upper.x, lower.x ) - lineRect.origin.x;
							lineRect = NormalizedRect( lineRect );
							
							// if any corner of the rect is outside the path, chuck it
							
							NSRect tr = NSInsetRect( lineRect, 1, 1 );
							NSPoint tp = NSMakePoint( NSMinX( tr ), NSMinY( tr ));
							
							if(![self containsPoint:tp])
								continue;
							
							tp = NSMakePoint( NSMaxX( tr ), NSMinY( tr ));
							if(![self containsPoint:tp])
								continue;
							
							tp = NSMakePoint( NSMaxX( tr ), NSMaxY( tr ));
							if(![self containsPoint:tp])
								continue;
							
							tp = NSMakePoint( NSMinX( tr ), NSMaxY( tr ));
							if(![self containsPoint:tp])
								continue;
							
							[result addObject:[NSValue valueWithRect:lineRect]];
						}
					}
					
					previousLine = currentLine;
				}
			}
		}
		[pool release];
	}
	
	return result;
}


- (NSRect)				lineFragmentRectForProposedRect:(NSRect) aRect remainingRect:(NSRect*) rem
{
	return [self lineFragmentRectForProposedRect:aRect remainingRect:rem datumOffset:0];
}


- (NSRect)				lineFragmentRectForProposedRect:(NSRect) aRect remainingRect:(NSRect*) rem datumOffset:(float) dOffset
{
	// The datum offset is a value
	// between -0.5 and +0.5 that specifies where in the line's height is used to find the shape's intersections at that y value.
	// A value of 0 means use the centre of the line, -0.5 the top, and +0.5 the bottom. 
	
	// this offsets <proposedRect> to the right to the next even-numbered intersection point, setting its length to the difference
	// between that point and the next. That part is the return value. If there are any further points, the remainder is set to
	// the rest of the rect. This allows this method to be used directly by a NSTextContainer subclass
	
	float od = LIMIT( dOffset, -0.5, +0.5 ) + 0.5;
	
	NSRect result;
	
	result.origin.y = NSMinY( aRect );
	result.size.height = NSHeight( aRect );
	
	float y = NSMinY( aRect ) + ( od * NSHeight( aRect ));
	
	// find the intersection points - these are already sorted left to right
	
	NSArray*	thePoints = [self intersectingPointsWithHorizontalLineAtY:y];
	NSPoint		p1, p2;
	int			ptIndex, ptCount;
	
	ptCount = [thePoints count];
	
	// search for the next even-numbered intersection point starting at the left edge of proposed rect.
	
	for( ptIndex = 0; ptIndex < ptCount; ptIndex += 2 )
	{
		p1 = [[thePoints objectAtIndex:ptIndex] pointValue];
		
		// even, so it's a left edge
		
		if( p1.x >= aRect.origin.x )
		{
			// this is the main rect to return
			
			p2 = [[thePoints objectAtIndex:ptIndex + 1] pointValue];
			
			result.origin.x = p1.x;
			result.size.width = p2.x - p1.x;
			
			// and this is the remainder
			
			if( rem != NULL )
			{
				aRect.origin.x = p2.x;
				*rem = aRect;
			}
			
			return result;
		}
	}
	
	// if we went through all the points and there were no more following the left edge of proposedRect, then there's no
	// more space on this line, so return zero rect.
	
	result = NSZeroRect;
	if ( rem != NULL )
		*rem = NSZeroRect;
	
	return result;
}



@end





@implementation DKTextOnPathGlyphAccumulator

- (NSArray*)			glyphs
{
	return mGlyphs;
}


- (void)				layoutManager:(NSLayoutManager*) lm willPlaceGlyphAtIndex:(unsigned) glyphIndex atLocation:(NSPoint) location pathAngle:(float) angle yOffset:(float) dy
{
	// determine the font for the glyph we are laying
	
	unsigned	charIndex = [lm characterIndexForGlyphAtIndex:glyphIndex];
	NSFont*		font = [[lm textStorage] attribute:NSFontAttributeName atIndex:charIndex effectiveRange:NULL];
	NSGlyph		glyph = [lm glyphAtIndex:glyphIndex];
	
	// get the baseline of the glyph
	
	float base = [lm locationForGlyphAtIndex:glyphIndex].y;
	
	// get the path of the glyph
	
	NSBezierPath* glyphTemp = [[NSBezierPath alloc] init];
	[glyphTemp moveToPoint:NSMakePoint( 0, dy - base )];
	[glyphTemp appendBezierPathWithGlyph:glyph inFont:font];

	// set up a transform to rotate the glyph to the path's local angle and flip it vertically
	
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform translateXBy:location.x yBy:location.y];
	[transform rotateByRadians:angle];
	[transform scaleXBy:1 yBy:-1];		// assumes destination is flipped

	[glyphTemp transformUsingAffineTransform:transform];
	
	// add the transformed glyph
	
	[mGlyphs addObject:glyphTemp];
	[glyphTemp release];
}


- (id)					init
{
	self = [super init];
	if( self )
		mGlyphs = [[NSMutableArray alloc] init];
	
	return self;
}


- (void)				dealloc
{
	[mGlyphs release];
	[super dealloc];
}

@end




@implementation DKTextOnPathGlyphDrawer

- (void)				layoutManager:(NSLayoutManager*) lm willPlaceGlyphAtIndex:(unsigned) glyphIndex atLocation:(NSPoint) location pathAngle:(float) angle yOffset:(float) dy
{
	// this simply applies the current angle and transformation to the current context and asks the layout manager to draw the glyph. It is assumed that this is called
	// within a valid drawing context, and that the context is flipped.
	
	SAVE_GRAPHICS_CONTEXT
	
	NSPoint gp = [lm locationForGlyphAtIndex:glyphIndex];
	
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform translateXBy:location.x yBy:location.y];
	[transform rotateByRadians:angle];
	[transform concat];
	
	[lm drawBackgroundForGlyphRange:NSMakeRange(glyphIndex, 1) atPoint:NSMakePoint( -gp.x, 0 - dy )];
	[lm drawGlyphsForGlyphRange:NSMakeRange(glyphIndex, 1) atPoint:NSMakePoint( -gp.x, 0 - dy )];
	
	RESTORE_GRAPHICS_CONTEXT
}



@end


@implementation DKTextOnPathMetricsHelper



- (void)				setCharacterRange:(NSRange) range
{
	mCharacterRange = range;
}


- (float)				length
{
	return mLength;
}


- (float)				position
{
	return mStartPosition;
}


- (void)				layoutManager:(NSLayoutManager*) lm willPlaceGlyphAtIndex:(unsigned) glyphIndex atLocation:(NSPoint) location pathAngle:(float) angle yOffset:(float) dy
{
	unsigned charIndex = [lm characterIndexForGlyphAtIndex:glyphIndex];
	
	if( NSLocationInRange( charIndex, mCharacterRange ))
	{
		// within the range of interest, so get the glyph's bounding rect
		// if length is 0, this is the first glyph of interest so record its position
		
		if( mLength == 0.0 )
			mStartPosition = [lm locationForGlyphAtIndex:glyphIndex].x;
		
		if( [lm isValidGlyphIndex:++glyphIndex])
			mLength = [lm locationForGlyphAtIndex:glyphIndex].x - mStartPosition;
		else
			mLength = NSMaxX([lm lineFragmentUsedRectForGlyphAtIndex:glyphIndex - 1 effectiveRange:NULL]) - mStartPosition;
	}
}

@end


@implementation DKPathGlyphInfo

- (id)			initWithGlyphIndex:(unsigned) glyphIndex position:(NSPoint) pt slope:(float) slope
{
	self = [super init];
	if( self )
	{
		mGlyphIndex = glyphIndex;
		mPoint = pt;
		mSlope = slope;
	}
	
	return self;
}


- (unsigned)	glyphIndex
{
	return mGlyphIndex;
}


- (float)		slope
{
	return mSlope;
}


- (NSPoint)		point
{
	return mPoint;
}

@end



@implementation NSFont (DKUnderlineCategory)

- (float)		valueForInvalidUnderlinePosition
{
	float ulo;
	NSFont* font = [[self class] fontWithName:@"Helvetica" size:[self pointSize]];
	
	ulo = [font underlinePosition];
	
	font = [[self class] fontWithName:@"Times" size:[self pointSize]];
	
	return ( ulo + [font underlinePosition]) * 0.5f;
}


- (float)		valueForInvalidUnderlineThickness
{
	float ulo;
	NSFont* font = [[self class] fontWithName:@"Helvetica" size:[self pointSize]];
	
	ulo = [font underlineThickness];
	
	font = [[self class] fontWithName:@"Times" size:[self pointSize]];
	
	return ( ulo + [font underlineThickness]) * 0.5f;
}
	
	
@end
	
	
