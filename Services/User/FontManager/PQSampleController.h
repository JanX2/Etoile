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

@interface PQSampleController : NSObject
{
  IBOutlet NSColorWell *backgroundColorWell;
	IBOutlet NSComboBox *customSampleField;
	IBOutlet NSColorWell *foregroundColorWell;
	IBOutlet NSTextView *sampleView;
	IBOutlet NSComboBox *sizeField;
	IBOutlet NSSlider *sizeSlider;

	NSArray *fonts;
	NSString *sampleText;

	NSColor *foregroundColor;
	NSColor *backgroundColor;

	NSArray *sizes;

	NSNumber *fontSize;
}

- (void) setFonts: (NSArray *)newFonts;
- (NSArray *) fonts;

- (void) update;

@end
