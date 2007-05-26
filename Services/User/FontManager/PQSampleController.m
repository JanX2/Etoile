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
	defaultSampleText =
		[NSArray arrayWithObjects:NSLocalizedString(@"PQPangram", nil), @"A test ok", nil];
	sampleTextHistory = [[NSMutableArray alloc] init];

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

	size = [NSNumber numberWithInt:24];

	RETAIN(fonts);
	RETAIN(sampleText);
	RETAIN(defaultSampleText);
	RETAIN(sampleTextHistory);
	RETAIN(foregroundColor);
	RETAIN(backgroundColor);
	RETAIN(sizes);
	RETAIN(size);

	return self;
}

- (void) setFonts: (NSArray *)someFonts
{
	ASSIGN(fonts, someFonts);
	[self update];
}

- (NSArray *) fonts
{
	return fonts;
}

- (void) setForegroundColor: (NSColor *)aColor
{
	ASSIGN(foregroundColor, aColor);
	[self update];
}

- (NSColor *) foregroundColor
{
	return foregroundColor;
}

- (void) setBackgroundColor: (NSColor *)aColor
{
	ASSIGN(backgroundColor, aColor);
	[self update];
}

- (NSColor *) backgroundColor
{
	return backgroundColor;
}

- (void) setSampleText: (NSString *)someText
{
	ASSIGN(sampleText, someText);
	[self update];
}

- (NSString *) sampleText
{
	return sampleText;
}

- (void) setSampleTextHistory: (NSArray *)aHistory
{
	ASSIGN(sampleTextHistory, aHistory);
	[self update];
}

- (NSArray *) sampleTextHistory
{
	return sampleTextHistory;
}

- (void) updateFonts
{
	[self update];
}

- (void) updateSampleText
{
	[self update];
}

- (void) updateSize
{
	[self update];
}

- (void) update
{

	/* Update controls */

	[sizeField setObjectValue: size];
	[sizeSlider setObjectValue: size];
	[sampleField setStringValue: [self sampleText]];

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
		                              size: [size floatValue]];
		
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
	else if (aComboBox == sampleField)
	{/*
		if (index < [defaultSampleText count])
		{
			return [defaultSampleText objectAtIndex:index];
		}
		else
		{
			return [sampleTextHistory
				objectAtIndex:(index - [defaultSampleText count])];
		}*/
		
		return [[defaultSampleText
			arrayByAddingObjectsFromArray: sampleTextHistory] objectAtIndex: index];
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
	else if (aComboBox == sampleField)
	{
		//return ([defaultSampleText count] + [sampleTextHistory count]);
		
		return [[defaultSampleText
			arrayByAddingObjectsFromArray: sampleTextHistory] count];
	}
	
	/* Else: something is wrong */
	return 0;
}

/* Keep controls updated */

- (void) controlTextDidEndEditing: (NSNotification *)aNotification
{
	id theObject = [aNotification object];
	
	if (theObject == sampleField)
	{
		sampleText = [sampleField stringValue];

		if ([defaultSampleText containsObject: sampleText] == NO)
		{
			unsigned index = [sampleTextHistory indexOfObject: sampleText];

			if (index != NSNotFound)
			{
				[sampleTextHistory removeObjectAtIndex: index];
			}

			[sampleTextHistory insertObject: sampleText atIndex: 0];
		}

		if ([sampleTextHistory count] > 10)
		{
			NSRange trimRange = NSMakeRange(10, ([sampleTextHistory count] - 10));

			[sampleTextHistory removeObjectsInRange:trimRange];
		}
		[self updateSampleText];
	}
	else if (theObject == sizeField)
	{
		size = [sizeField objectValue];

		[self updateSize];
	}
}

- (void) comboBoxWillDismiss: (NSNotification *)notification
{
	id theObject = [notification object];
	
	if (theObject == sampleField)
	{
		int index = [sampleField indexOfSelectedItem];
		[self setSampleText:
			[[defaultSampleText arrayByAddingObjectsFromArray: sampleTextHistory]
			objectAtIndex: index]];

		[self updateSampleText];
	}
	else if (theObject == sizeField)
	{
		int index = [sizeField indexOfSelectedItem];
		size = [sizes objectAtIndex: index];

		[self updateSize];
	}
}

- (void) dealloc
{
	RELEASE(fonts);
	RELEASE(sampleText);
	RELEASE(defaultSampleText);
	RELEASE(sampleTextHistory);
	RELEASE(foregroundColor);
	RELEASE(backgroundColor);
	RELEASE(sizes);
	RELEASE(size);

	[super dealloc];
}

@end
