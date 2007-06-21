/*
 * PQSamplerController.h - Font Manager
 *
 * Controller for font sampler.
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 05/24/07
 * License: Modified BSD license (see file COPYING)
 */


#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "PQFontSampleView.h"


@interface PQSampleController : NSObject
{
	PQFontSampleView *sampleView;

	NSComboBox *sampleField;
	NSComboBox *sizeField;
	NSSlider *sizeSlider;

	NSColorWell *foregroundColorWell;
	NSColorWell *backgroundColorWell;

	NSArray *fonts;
	NSArray *defaultSampleText;
	NSMutableArray *sampleTextHistory;

	NSArray *sizes;

	BOOL fontsNeedUpdate;
}

- (void) setFonts: (NSArray *)someFonts;
- (NSArray *) fonts;
- (void) setSampleTextHistory: (NSArray *)aHistory;
- (NSArray *) sampleTextHistory;

- (void) changeSize: (id)sender;
- (void) changeColor: (id)sender;
- (void) changeSampleText: (id)sender;

- (void) updateControls;

@end
