/*
 * PQSampleView.m - Font Manager
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
	NSString *currentFontName;
	NSFont *currentFont;
	NSMutableDictionary *currentAttributes = [[NSMutableDictionary alloc] init];
	NSRect currentDrawingRect = NSMakeRect(0, 0, 0, 0);
	int fontsCount = [dataSource numberOfFontsInFontSampleView: self];
	int index = 0;
	NSSize frameSize = [self frame].size;
	BOOL shouldUpdateSize = NO;
	
	float biggestWidth = 0;

	while (index < fontsCount)
	{
		currentFontName = [dataSource fontSampleView: self fontAtIndex: index];
		currentFont = [NSFont fontWithName: currentFontName size: [self fontSize]];

		[currentAttributes setObject: currentFont forKey: NSFontAttributeName];

		if (frameSize.height < currentDrawingRect.origin.y)
		{
			frameSize.height = currentDrawingRect.origin.y;
			shouldUpdateSize = YES;
		}

		if (shouldUpdateSize)
			[self setFrameSize: frameSize];

		[sampleText drawAtPoint: currentDrawingRect.origin
		         withAttributes: currentAttributes];


		currentDrawingRect.origin.y +=
			[sampleText sizeWithAttributes: currentAttributes].height;

		++index;
	}
}

@end
