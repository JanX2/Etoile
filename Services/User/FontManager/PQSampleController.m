/*
 * PQSamplerController.m - Font Manager
 *
 * Controller for font sampler.
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 05/24/07
 * License: Modified BSD license (see file COPYING)
 */

#import "PQCompat.h"
#import "PQSampleController.h"

@implementation PQSampleController

- (id) init
{
	[super init];

	fonts = [[NSArray alloc] init];
	sampleText = NSLocalizedString(@"PQPangram", nil);
	sampleTextHistory = [NSArray arrayWithObject:@"Big Fat Hairy Test"];

	foregroundColor = [NSColor blackColor];
	backgroundColor = [NSColor whiteColor];
	
	sizes = [NSArray arrayWithObjects: [NSNumber numberWithInt:9],
		[NSNumber numberWithInt:10], [NSNumber numberWithInt:11],
		[NSNumber numberWithInt:12], [NSNumber numberWithInt:13],
		[NSNumber numberWithInt:14], [NSNumber numberWithInt:18],
		[NSNumber numberWithInt:24], [NSNumber numberWithInt:36],
		[NSNumber numberWithInt:48], [NSNumber numberWithInt:64],
		[NSNumber numberWithInt:72], [NSNumber numberWithInt:96],
		[NSNumber numberWithInt:144], [NSNumber numberWithInt:288], nil];

	fontSize = [NSNumber numberWithInt:24];

	RETAIN(fonts);
	RETAIN(sampleText);
	RETAIN(sampleTextHistory);
	RETAIN(foregroundColor);
	RETAIN(backgroundColor);
	RETAIN(sizes);
	RETAIN(fontSize);

	return self;
}

- (void) setFonts: (NSArray *)newFonts
{
	ASSIGN(fonts, newFonts);
	[self update];
}

- (NSArray *) fonts
{
	return fonts;
}

- (void) setForegroundColor: (NSColor *)newColor
{
	ASSIGN(foregroundColor, newColor);
	[self update];
}

- (NSColor *) foregroundColor
{
	return foregroundColor;
}

- (void) setBackgroundColor: (NSColor *)newColor
{
	ASSIGN(backgroundColor, newColor);
	[self update];
}

- (NSColor *) backgroundColor
{
	return backgroundColor;
}

- (void) setSampleText: (NSString *)newText
{
	ASSIGN(sampleText, newText);
	[self update];
}

- (NSString *) sampleText
{
	return sampleText;
}

- (void) setSampleTextHistory: (NSArray *)newHistory
{
	ASSIGN(sampleTextHistory, newHistory);
	[self update];
}

- (NSArray *) sampleTextHistory
{
	return sampleTextHistory;
}

- (void) update
{

	/* Update controls */

	[sizeField setObjectValue: fontSize];
	[sizeSlider setObjectValue: fontSize];
	[customSampleField setStringValue: [self sampleText]];

	/* Update sample */

	NSEnumerator *fontNamesEnum = [[self fonts] objectEnumerator];
	NSString *currentFontName;
	NSFont *currentFont;
	NSString *currentString;
	
	BOOL isFirstSample = YES;
	
	NSTextStorage *fontSample = [sampleView textStorage];
	
	[fontSample setAttributedString:
		[[NSAttributedString alloc] initWithString:@""]];

	while (currentFontName = [fontNamesEnum nextObject])
	{
		currentFont = [NSFont fontWithName: currentFontName
		                              size: [fontSize floatValue]];
		
		if (isFirstSample == YES)
		{
			currentString =
				[NSString stringWithFormat:@"%@:\n", [currentFont displayName]];
			isFirstSample = NO;
		}
		else /* isFirstSample == NO */
		{
			currentString =
				[NSString stringWithFormat:@"\n\n%@:\n", [currentFont displayName]];
		}

		[fontSample appendAttributedString:
			[[NSAttributedString alloc] initWithString: currentString]];

		NSDictionary *attributes = [NSDictionary dictionaryWithObject: currentFont
			forKey: NSFontAttributeName];

		[fontSample appendAttributedString:
			[[NSAttributedString alloc] initWithString: sampleText
			attributes:attributes]];
	}
}

- (id) comboBox: (NSComboBox *)aComboBox objectValueForItemAtIndex: (int)index
{
	if (aComboBox == sizeField)
	{
		return [sizes objectAtIndex:index];
	}
	else if (aComboBox == customSampleField)
	{
		return @"The quick brown fox jumps over a lazy dog."; // Temp
	}
	
	/* Else: something is wrong */
	return nil;
}

- (int) numberOfItemsInComboBox: (NSComboBox *)aComboBox
{
	if (aComboBox == sizeField)
	{
		return [sizes count];
	}
	else if (aComboBox == customSampleField)
	{
		return 1; // Temp
	}
	
	/* Else: something is wrong */
	return 0;
}

/* Keep controls updated */

- (void) controlTextDidEndEditing: (NSNotification *)aNotification
{
	sampleText = [customSampleField stringValue];
	[self update];
}

- (void) dealloc
{
	RELEASE(fonts);
	RELEASE(sampleText);
	RELEASE(sampleTextHistory);
	RELEASE(foregroundColor);
	RELEASE(backgroundColor);
	RELEASE(sizes);
	RELEASE(fontSize);

	[super dealloc];
}

@end
