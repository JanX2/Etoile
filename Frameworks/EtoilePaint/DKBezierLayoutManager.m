//
//  DKBezierLayoutManager.m
//  GCDrawKit
//
//  Created by graham on 26/11/2008.
//  Copyright 2008 Apptree.net. All rights reserved.
//

#import "DKBezierLayoutManager.h"


@implementation DKBezierLayoutManager


- (NSBezierPath*)		textPath
{
	return mPath;
}


- (NSArray*)			glyphPathsForContainer:(NSTextContainer*) container usedSize:(NSSize*) aSize
{
	// this method can be used to return a list of bezier paths, each representing one glyph. The relative positions of the paths are as laid out by the layout manager
	// in the given container. If <usedSize> isn't nil, the size actually used by the laid out text is returned also. This has limited utility, but is used for example
	// by DKTextShape to return glyphs separately so they can be converted to a grouped shape, allowing the individual glyphs to be recovered and manipulated individually
	// as graphics. Note that <container> should already belong to the layout manager's list of containers; prior to calling, its size should be set as required.
	
	NSMutableArray*	array = [NSMutableArray array];
	NSRange			glyphRange;
	
	// lay out the text and find out how much of it fits in the container.
	
	glyphRange = [self glyphRangeForTextContainer:container];
	
	if ( aSize )
		*aSize = [self usedRectForTextContainer:container].size;
	
	NSBezierPath*	temp;
	NSRect			fragRect;
	NSRange			grange;
	unsigned		glyphIndex = 0;	
	
	if (glyphRange.length > 0)
	{
		while( glyphIndex < glyphRange.length )
		{
			// look at the formatting applied to individual glyphs so that the path applies that formatting as necessary.
			
			NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
			
			unsigned	g;
			NSPoint		gloc, ploc;
			NSFont*		font;
			float		base;
			
			fragRect = [self lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:&grange];
			
			for( g = grange.location; g < grange.location + grange.length; ++g )
			{
				temp = [NSBezierPath bezierPath];
				ploc = gloc = [self locationForGlyphAtIndex:g];
				
				ploc.x -= fragRect.origin.x;
				ploc.y -= fragRect.origin.y;
				
				font = [[[self textStorage] attributesAtIndex:g effectiveRange:NULL] objectForKey:NSFontAttributeName];
				
				[temp moveToPoint:ploc];
				[temp appendBezierPathWithGlyph:[self glyphAtIndex:g] inFont:font];
				
				base = [font pointSize] - [font ascender];
				
				// need to vertically flip and offset each glyph as it is created
				
				NSAffineTransform* xform = [NSAffineTransform transform];
				[xform translateXBy:0 yBy:( fragRect.size.height - base ) * 2];
				[xform scaleXBy:1.0 yBy:-1.0];
				[temp transformUsingAffineTransform:xform];
				
				[array addObject:temp];
			}
			// next line:
			glyphIndex += grange.length;
			[pool drain];
		}
	}
	
	return array;
}



- (void)	showPackedGlyphs:(char*) packedGlyphs length:(NSUInteger) glyphLen
			   glyphRange:(NSRange) glyphRange atPoint:(NSPoint) point font:(NSFont*) font
					color:(NSColor*) color printingAdjustment:(NSSize) printingAdjustment
{
	[mPath moveToPoint:point];
	[mPath appendBezierPathWithPackedGlyphs:packedGlyphs];
	
	// debug:
/*
	[mPath setLineWidth:1.0];
	[[NSColor blackColor] set];
	[mPath stroke];
*/
}


- (void)	drawUnderlineForGlyphRange:(NSRange)glyphRange
					  underlineType:(NSInteger)underlineVal
					 baselineOffset:(CGFloat)baselineOffset
				   lineFragmentRect:(NSRect)lineRect
			 lineFragmentGlyphRange:(NSRange)lineGlyphRange
					containerOrigin:(NSPoint)containerOrigin
{
	
	// no-op
}

- (void)	drawStrikethroughForGlyphRange:(NSRange)glyphRange
					  strikethroughType:(NSInteger)strikethroughVal
						 baselineOffset:(CGFloat)baselineOffset
					   lineFragmentRect:(NSRect)lineRect
				 lineFragmentGlyphRange:(NSRange)lineGlyphRange
						containerOrigin:(NSPoint)containerOrigin
{
	// no-op
}


- (id)		init
{
	self = [super init];
	if( self )
		mPath = [[NSBezierPath alloc] init];
	
	return self;
}


- (void)	dealloc
{
	[mPath release];
	[super dealloc];
}

@end
