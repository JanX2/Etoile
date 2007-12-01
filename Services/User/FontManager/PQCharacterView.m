/*
 * PQCharacterView.m - Font Manager
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 12/01/07
 * License: 3-Clause BSD license (see file COPYING)
 */


#import "PQCharacterView.h"
#import "PQCompat.h"


@implementation PQCharacterView

- (id) initWithFrame: (NSRect)frame
{
	[super initWithFrame: frame];
	
	fontName = @"Bitstream Vera Sans";
	fontSize = 48.0;
	
	/* Set up text system */
	textStorage = [[NSTextStorage alloc] initWithString:@"j"];
	layoutManager = [[NSLayoutManager alloc] init];
	textContainer = [[NSTextContainer alloc] init];
	[layoutManager addTextContainer: textContainer];
	[textStorage addLayoutManager: layoutManager];
	
	RETAIN(textStorage);
	RETAIN(fontName);

	return self;
}

- (void) dealloc
{
	RELEASE(textStorage);
	RELEASE(fontName);
	[super dealloc];
}


/* Drawing */

- (BOOL) isFlipped
{
	return NO;
}

- (void) drawRect: (NSRect)rect
{
	NSFont *font = [NSFont fontWithName: fontName size: fontSize];
	NSGlyph glyph;
	BOOL isValidIndex;
	
	[textStorage addAttribute: NSFontAttributeName
											value: font
											range: NSMakeRange(0, [textStorage length])];
	
	glyph = [layoutManager glyphAtIndex: 0 isValidIndex: &isValidIndex];
	
	NSPoint origin = [layoutManager locationForGlyphAtIndex: 0];
	
	NSRect glyphRect = [layoutManager
		boundingRectForGlyphRange:NSMakeRange(0, [textStorage length])
		inTextContainer: textContainer];
		
	NSLog(@"%i", glyph);
		
	[[NSColor redColor] set];
	[NSBezierPath strokeRect: glyphRect];
	
	if (isValidIndex)
	{
		float advancement = [font advancementForGlyph: glyph].width;
		float height = [font ascender];
		
		[[NSColor redColor] set];
		
		NSBezierPath *path = [[NSBezierPath alloc] init];
		
		[path moveToPoint: NSMakePoint(10, 10)];
		
		/*
		[path lineToPoint: NSMakePoint(origin.x, height)];
		[path lineToPoint: NSMakePoint(advancement + origin.x, height)];
		[path lineToPoint: NSMakePoint(advancement + origin.x, origin.y)];
		[path lineToPoint: origin];
		
		[path closePath];
		[path stroke]; */
		
	
		[textContainer setContainerSize: [self frame].size];
		
		[layoutManager drawGlyphsForGlyphRange: NSMakeRange(0, 1)
																   atPoint: NSMakePoint(0, 0)];
	}
}

@end
