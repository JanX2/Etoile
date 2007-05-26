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
	IBOutlet NSComboBox *sampleField;
	IBOutlet NSColorWell *foregroundColorWell;
	IBOutlet NSTextView *sampleView;
	IBOutlet NSComboBox *sizeField;
	IBOutlet NSSlider *sizeSlider;

	NSArray *fonts;
	NSString *sampleText;
	NSArray *defaultSampleText;
	NSMutableArray *sampleTextHistory;

	NSColor *foregroundColor;
	NSColor *backgroundColor;

	NSArray *sizes;
	NSNumber *size;
}

- (void) setFonts: (NSArray *)someFonts;
- (NSArray *) fonts;
- (void) setForegroundColor: (NSColor *)aColor;
- (NSColor *) foregroundColor;
- (void) setBackgroundColor: (NSColor *)aColor;
- (NSColor *) backgroundColor;
- (void) setSampleText: (NSString *)someText;
- (NSString *) sampleText;
- (void) setSampleTextHistory: (NSArray *)aHistory;
- (NSArray *) sampleTextHistory;

- (void) updateFonts;
- (void) updateSampleText;
- (void) updateSize;

@end
