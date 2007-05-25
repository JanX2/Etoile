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
	
	sizes = [NSArray arrayWithObjects: [NSNumber numberWithInt:9],
		[NSNumber numberWithInt:10], [NSNumber numberWithInt:11],
		[NSNumber numberWithInt:12], [NSNumber numberWithInt:13],
		[NSNumber numberWithInt:14], [NSNumber numberWithInt:18],
		[NSNumber numberWithInt:24], [NSNumber numberWithInt:36],
		[NSNumber numberWithInt:48], [NSNumber numberWithInt:64],
		[NSNumber numberWithInt:72], [NSNumber numberWithInt:96],
		[NSNumber numberWithInt:144], [NSNumber numberWithInt:288], nil];
	RETAIN(sizes);
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[super dealloc];
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

- (void) update
{

	/* Update size controls */

	[sizeField setObjectValue:fontSize];
	[sizeSlider setObjectValue:fontSize];

/*
	NSEnumerator *fontEnumerator = [[self fonts] objectEnumerator];
	NSString *currentFont;
	
	NSTextStorage *fontSample = [sampleView textStorage];

	// "The quick brown fox jumps over a lazy dog."
	//initWithString:attributes:
	//addAttribute:value:range:
	//NSMakeRange(0, )
	while (currentFont = [fontEnumerator nextObject])
	{
    NSAttributedString *fontName =
			[[NSAttributedString alloc] initWithString:
				[currentFont stringByAppendingString:@"\n"]];
		[fontSample appendAttributedString:fontName];
	}*/
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

@end
