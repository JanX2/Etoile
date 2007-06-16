/*
 * PQFontSampleView.m - Font Manager
 *
 * A font sampling view.
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 05/28/07
 * License: Modified BSD license (see file COPYING)
 */


#import "PQFontSampleView.h"
#import "PQCompat.h"


@implementation PQFontSampleView

- (id) initWithFrame: (NSRect)frame
{
	[super initWithFrame: frame];

	sampleText = [[NSString alloc] init];
	fontSize = 24;

	foregroundColor = [NSColor blackColor];
	backgroundColor = [NSColor whiteColor];


	RETAIN(sampleText);
	RETAIN(foregroundColor);
	RETAIN(backgroundColor);

	return self;
}

- (void) dealloc
{
	RELEASE(sampleText);
	RELEASE(foregroundColor);
	RELEASE(backgroundColor);
	
	[super dealloc];
}


/* Data source */

- (void) setDataSource: (id)anObject
{
	if ([anObject
		respondsToSelector:@selector(numberOfFontsInFontSampleView:)] == NO)
	{
			[NSException raise: NSInternalInconsistencyException 
			            format: @"Data source does not respond to "
			                    @"numberOfFontsInFontSampleView:"];
	}
	else if ([anObject
		respondsToSelector:@selector(fontSampleView:fontAtIndex:)] == NO)
	{
			[NSException raise: NSInternalInconsistencyException 
			            format: @"Data source does not respond to "
			                    @"fontSampleView:fontAtIndex:"];
	}

	dataSource = anObject;

	[self setNeedsDisplay: YES];
}

- (id) dataSource
{
	return dataSource;
}


/* View properties */

- (void) setSampleText: (NSString *)someText
{
	ASSIGN(sampleText, someText);
	[self setNeedsDisplay: YES];
}

- (NSString *) sampleText
{
	return sampleText;
}

- (void) setFontSize: (int)aSize
{
	fontSize = aSize;
	[self setNeedsDisplay: YES];
}

- (int) fontSize
{
	return fontSize;
}


/* Foreground and background colors */

- (void) setForegroundColor: (NSColor *)aColor
{
	ASSIGN(foregroundColor, aColor);
	[self setNeedsDisplay: YES];
}

- (NSColor *) foregroundColor
{
	return foregroundColor;
}

- (void) setBackgroundColor: (NSColor *)aColor
{
	ASSIGN(backgroundColor, aColor);
	[self setNeedsDisplay: YES];
}

- (NSColor *) backgroundColor
{
	return backgroundColor;
}


/* Drawing */

- (BOOL) isFlipped
{
	return YES;
}

- (void) drawRect: (NSRect)rect
{
	int fontsCount = [[self dataSource] numberOfFontsInFontSampleView: self];
	int index = 0;
  NSRange rangeNeedsDrawing;

	/* Text system components */
	NSTextStorage *textStorage = [[NSTextStorage alloc] init];
	NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
	NSTextContainer *textContainer = [[NSTextContainer alloc] init];

	/* Font sample components */
	NSString *currentFontName;
	NSFont *currentFont;
	NSString *currentLabel;
	NSMutableDictionary *currentAttributes = [[NSMutableDictionary alloc] init];


	/* Set up text system */
	[textContainer setContainerSize: NSMakeSize([self frame].size.width, 50000)];
	[layoutManager addTextContainer: textContainer];
	[textStorage addLayoutManager: layoutManager];

	/* Add color attribute */
	[currentAttributes setValue: [self foregroundColor]
	                     forKey: NSForegroundColorAttributeName];

	/* Create font sample */
	while (index < fontsCount)
	{
		/* Find next font */
		currentFontName = [[self dataSource] fontSampleView: self
		                                        fontAtIndex: index];

		currentFont = [NSFont fontWithName: currentFontName size: [self fontSize]];

		/* Add label to text storage */
		[currentAttributes setValue: [NSFont labelFontOfSize: 0]
		                     forKey: NSFontAttributeName];

		if (index == 0)
		{
			currentLabel =
				[NSString stringWithFormat: @"%@:\n", [currentFont displayName]];
		}
		else
		{
			currentLabel =
				[NSString stringWithFormat: @"\n\n%@:\n", [currentFont displayName]];
		}

		[textStorage appendAttributedString:
			[[NSAttributedString alloc] initWithString: currentLabel
														          attributes: currentAttributes]];

		/* Add font sample to text storage */
		[currentAttributes setValue: currentFont forKey: NSFontAttributeName];

		[textStorage appendAttributedString:
			[[NSAttributedString alloc] initWithString: [self sampleText]
			                                attributes: currentAttributes]];

		++index;
	}

	/*(void) [layoutManager glyphRangeForTextContainer: textContainer];
	_sampleSizeHeight =
		[layoutManager usedRectForTextContainer:textContainer].size.height;
NSLog(@"-%f", _sampleSizeHeight);*/


	/* Draw font sample */
  rangeNeedsDrawing = [layoutManager glyphRangeForBoundingRect: rect
	                                             inTextContainer: textContainer];

	[layoutManager drawGlyphsForGlyphRange: rangeNeedsDrawing
																 atPoint: NSMakePoint(0, 0)];
}

@end
