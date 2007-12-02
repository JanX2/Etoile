/*
 * PQCharacterView.m - Font Manager
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 12/01/07
 * License: 3-Clause BSD license (see file COPYING)
 */


#import <stdlib.h>
#import <math.h>
#import "PQCharacterView.h"
#import "PQCompat.h"


float invf(float f);


@implementation PQCharacterView

- (id) initWithFrame: (NSRect)frame
{
	[super initWithFrame: frame];

#ifdef GNUSTEP
	fontName = @"Bitstream Vera Sans";
#else
	//fontName = @"Helvetica";
	//fontName = @"TrebuchetMS-Italic";
	fontName = @"TimesNewRomanPS-ItalicMT";
#endif
	fontSize = 144.0;
	
	color = [NSColor blackColor];
	guideColor = [NSColor redColor];
	backgroundColor = [NSColor whiteColor];
	
	character = @"R";
	
	RETAIN(fontName);
	RETAIN(color);
	RETAIN(guideColor);
	RETAIN(backgroundColor);
	RETAIN(character);

	return self;
}

- (void) dealloc
{
	RELEASE(fontName);
	RELEASE(color);
	RELEASE(guideColor);
	RELEASE(backgroundColor);
	RELEASE(character);
	
	[super dealloc];
}

- (void) setFontSize: (float)newSize
{
	fontSize = newSize;
	
	[self setNeedsDisplay: YES];
}

- (float) fontSize
{
	return fontSize;
}

- (void) changeSize: (id)sender
{
	[self setFontSize: [sender intValue]];
}

/* Drawing */

- (void) drawRect: (NSRect)rect
{
	NSFont *font = [NSFont fontWithName: fontName size: fontSize];
	NSBezierPath *path = [[NSBezierPath alloc] init];
	
	/* Text system components */
	NSTextStorage *textStorage;
	NSLayoutManager *layoutManager;

	/* Set up text system */
	textStorage = [[NSTextStorage alloc] initWithString: character];
	[textStorage addAttribute: NSFontAttributeName
											value: font
											range: NSMakeRange(0, [textStorage length])];
	[textStorage addAttribute: NSForegroundColorAttributeName
											value: color
											range: NSMakeRange(0, [textStorage length])];
	layoutManager = [[NSLayoutManager alloc] init];
	[textStorage addLayoutManager: layoutManager];
	RELEASE(layoutManager); /* Retained by textStorage */
	
	[backgroundColor set];
	[NSBezierPath fillRect: rect];

	if ([layoutManager numberOfGlyphs] > 0)
	{
		float advancement = [font advancementForGlyph: [layoutManager glyphAtIndex: 0]].width;
		float ascent = [font ascender];
		float descent = [font descender];
		float xHeight = [font xHeight];
		float italicAngle = [font italicAngle];
		float yOffset = (rect.size.height - [textStorage size].height) / 2.0;
    float baseline = yOffset + abs(descent);
		float xOffset = NSMidX(rect) - (advancement / 2.0);
				
    [guideColor set];

		[path moveToPoint: NSMakePoint(0.0, baseline)];
		[path lineToPoint: NSMakePoint(rect.size.width, baseline)];

		[path stroke];

		[path removeAllPoints];

		float pattern[] = {1.0, 2.0};
		[path setLineDash: pattern count: 2 phase: 0.0];

		[path moveToPoint: NSMakePoint(xOffset, 0.0)];
		[path lineToPoint: NSMakePoint(xOffset, rect.size.height)];

		[path moveToPoint: NSMakePoint(xOffset + advancement, 0.0)];
		[path lineToPoint: NSMakePoint(xOffset + advancement,
		                               rect.size.height)];

		[path moveToPoint: NSMakePoint(0.0, baseline + descent)];
		[path lineToPoint: NSMakePoint(rect.size.width, baseline + descent)];

		[path moveToPoint: NSMakePoint(0.0, baseline + ascent)];
		[path lineToPoint: NSMakePoint(rect.size.width, baseline + ascent)];

		[path moveToPoint: NSMakePoint(0.0, baseline + xHeight)];
		[path lineToPoint: NSMakePoint(rect.size.width, baseline + xHeight)];

		if (italicAngle != 0.0)
		{
			float top = ([self frame].size.height / 2.0);
			float bottom = ([self frame].size.height / 2.0);
			float tangent = tan(invf(italicAngle) * (3.141592 / 180.0));

			[path moveToPoint:
				NSMakePoint(xOffset + (tangent * top),
										[self frame].size.height)];
			[path lineToPoint:
				NSMakePoint(xOffset - (tangent * bottom), 0.0)];

			[path moveToPoint:
				NSMakePoint(xOffset + advancement + (tangent * top),
										[self frame].size.height)];
			[path lineToPoint:
				NSMakePoint((xOffset + advancement) - (tangent * bottom), 0.0)];
		}

		[path stroke];

		[textStorage drawAtPoint: NSMakePoint(xOffset, yOffset)];       
	}
}

@end

float invf(float f)
{
	if (f > 0.0)
	{
		return f - (f * 2);
	}
	else if (f < 0.0)
	{
		return abs(f);
	}
	
	return 0.0;
}
