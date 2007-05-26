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


@interface PQSampleController (FontManagerPrivate)
- (void) PQAddSampleTextToHistory: (NSString *)someText;
@end


@implementation PQSampleController

- (id) init
{
	[super init];

	fonts = [[NSArray alloc] init];
	sampleText = NSLocalizedString(@"PQPangram", nil);
	defaultSampleText =
		[NSArray arrayWithObjects:NSLocalizedString(@"PQPangram", nil), nil];
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

	needsUpdateFonts = NO;
	needsUpdateSampleText = NO;
	needsUpdateSize= NO;

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

- (void) setNeedsUpdateFonts: (BOOL)flag
{
	needsUpdateFonts = flag;
}

- (BOOL) needsUpdateFonts
{
	return needsUpdateFonts;
}

- (void) setNeedsUpdateSampleText: (BOOL)flag
{
	needsUpdateSampleText = flag;
}

- (BOOL) needsUpdateSampleText
{
	return needsUpdateSampleText;
}

- (void) setNeedsUpdateSize: (BOOL)flag
{
	needsUpdateSize = flag;
}

- (BOOL) needsUpdateSize
{
	return needsUpdateSize;
}

- (void) setFonts: (NSArray *)someFonts
{
	ASSIGN(fonts, someFonts);
	[self updateFonts];
}

- (NSArray *) fonts
{
	return fonts;
}

- (void) setForegroundColor: (NSColor *)aColor
{
	ASSIGN(foregroundColor, aColor);
}

- (NSColor *) foregroundColor
{
	return foregroundColor;
}

- (void) setBackgroundColor: (NSColor *)aColor
{
	ASSIGN(backgroundColor, aColor);
}

- (NSColor *) backgroundColor
{
	return backgroundColor;
}

- (void) setSize: (NSNumber *)aNumber
{
	ASSIGN(size, aNumber);
	[self updateSize];
}

- (NSNumber *) size
{
	return size;
}

- (void) setSampleText: (NSString *)someText
{
	ASSIGN(sampleText, someText);
	[self updateSampleText];
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

- (id) comboBox: (NSComboBox *)aComboBox objectValueForItemAtIndex: (int)index
{
	if (aComboBox == sizeField)
	{
		return [sizes objectAtIndex:index];
	}
	else if (aComboBox == sampleField)
	{
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
		NSString *newSampleText = [sampleField stringValue];

		[self setSampleText: newSampleText];

		[self PQAddSampleTextToHistory: newSampleText];
	}
	else if (theObject == sizeField)
	{
		[self setSize: [sizeField objectValue]];
	}
}

- (void) comboBoxWillDismiss: (NSNotification *)notification
{
	id theObject = [notification object];

	if (theObject == sampleField)
	{
		int index = [sampleField indexOfSelectedItem];
		
		if (index == -1)
		{
			return;
		}

		NSString *newSampleText =
			[[defaultSampleText arrayByAddingObjectsFromArray: sampleTextHistory]
			objectAtIndex: index];
			
		[self setSampleText: newSampleText];

		[self PQAddSampleTextToHistory: newSampleText];

		[self updateSampleText];
	}
	else if (theObject == sizeField)
	{
		int index = [sizeField indexOfSelectedItem];
		size = [sizes objectAtIndex: index];

		[self updateSize];
	}
}

@end


@implementation PQSampleController (FontManagerPrivate)

- (void) PQAddSampleTextToHistory: (NSString *)someText
{
	if ([defaultSampleText containsObject: someText] == NO)
	{
		unsigned index = [sampleTextHistory indexOfObject: someText];

		if (index != NSNotFound)
		{
			[sampleTextHistory removeObjectAtIndex: index];
		}

		[sampleTextHistory insertObject: someText atIndex: 0];
	}

	if ([sampleTextHistory count] > 10)
	{
		NSRange trimRange = NSMakeRange(10, ([sampleTextHistory count] - 10));

		[sampleTextHistory removeObjectsInRange:trimRange];
	}
}

@end
