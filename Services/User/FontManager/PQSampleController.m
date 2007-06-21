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
	defaultSampleText =
		[NSArray arrayWithObjects:NSLocalizedString(@"PQPangram", nil), nil];
	sampleTextHistory = [[NSMutableArray alloc] init];


	sizes = [NSArray arrayWithObjects: [NSNumber numberWithInt:9],
		[NSNumber numberWithInt:10], [NSNumber numberWithInt:11],
		[NSNumber numberWithInt:12], [NSNumber numberWithInt:13],
		[NSNumber numberWithInt:14], [NSNumber numberWithInt:18],
		[NSNumber numberWithInt:24], [NSNumber numberWithInt:36],
		[NSNumber numberWithInt:48], [NSNumber numberWithInt:64],
		[NSNumber numberWithInt:72], [NSNumber numberWithInt:96],
		[NSNumber numberWithInt:144], [NSNumber numberWithInt:288], nil];

	fontsNeedUpdate = YES;

	RETAIN(fonts);
	RETAIN(defaultSampleText);
	RETAIN(sampleTextHistory);
	RETAIN(sizes);

	return self;
}

- (void) awakeFromNib
{
	[sampleView setAutoSize: YES];
	[sampleView setFontSize: 24];
	[sampleView setSampleText: NSLocalizedString(@"PQPangram", nil)];

	/* Couldn't set "Uses data source" in gorm */
	[sampleField setUsesDataSource: YES];
	[sampleField setDataSource: self];
	[sizeField setUsesDataSource: YES];
	[sizeField setDataSource: self];

	[self updateControls];
}

- (void) dealloc
{
	RELEASE(fonts);
	RELEASE(defaultSampleText);
	RELEASE(sampleTextHistory);
	RELEASE(sizes);

	[super dealloc];
}

- (void) setFonts: (NSArray *)someFonts
{
	ASSIGN(fonts, someFonts);
	fontsNeedUpdate = YES;
	[sampleView setNeedsDisplay: YES];
}

- (NSArray *) fonts
{
	return fonts;
}

- (void) setSampleTextHistory: (NSArray *)aHistory
{
	ASSIGN(sampleTextHistory, aHistory);
}

- (NSArray *) sampleTextHistory
{
	return sampleTextHistory;
}


/* Combo box data source */

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


/* Font sample view data source */

- (int) numberOfFontsInFontSampleView: (PQFontSampleView *)aFontSampleView
{
	return [fonts count];
}

- (NSString *) fontSampleView: (PQFontSampleView *)aFontSampleView
									fontAtIndex: (int)rowIndex
{
	return [fonts objectAtIndex: rowIndex];
}

- (BOOL) fontsShouldChangeInFontSampleView: (PQFontSampleView *)aFontSampleView
{
	if (fontsNeedUpdate == YES)
	{
		fontsNeedUpdate = NO;
		return YES;
	}
	return NO;
}


/* Keep controls updated */

- (void) updateControls
{
	[sampleField setStringValue: [sampleView sampleText]];
	[sizeField setIntValue: [sampleView fontSize]];
	[sizeSlider setIntValue: [sampleView fontSize]];
}

- (void) changeSize: (id)sender
{
	[sampleView setFontSize: [sender intValue]];
	[self updateControls];
}

- (void) changeColor: (id)sender
{
	[sampleView setForegroundColor: [foregroundColorWell color]];
	[sampleView setBackgroundColor: [backgroundColorWell color]];
}

- (void) changeSampleText: (id)sender
{
	NSString *newSampleText = [sampleField stringValue];
	[sampleView setSampleText: newSampleText];
	[self PQAddSampleTextToHistory: newSampleText];
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
