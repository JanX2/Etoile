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
	NSString *sampleText;
	NSArray *defaultSampleText;
	NSMutableArray *sampleTextHistory;

	BOOL fontsNeedUpdate;

	NSNumber *size;
	NSArray *sizes;
}

- (void) setFonts: (NSArray *)someFonts;
- (NSArray *) fonts;
- (void) setSampleText: (NSString *)someText;
- (NSString *) sampleText;
- (void) setSampleTextHistory: (NSArray *)aHistory;
- (NSArray *) sampleTextHistory;

- (void) updateControls;

@end
