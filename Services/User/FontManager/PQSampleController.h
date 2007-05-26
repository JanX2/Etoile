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

	BOOL needsUpdateFonts;
	BOOL needsUpdateSampleText;
	BOOL needsUpdateSize;
}

/* Methods for updating the font sample.
   Do not call directly. Instead use -setNeedsUpdate*: methods. */
- (void) updateFonts;
- (void) updateSampleText;
- (void) updateSize;

- (void) setNeedsUpdateFonts: (BOOL)flag;
- (BOOL) needsUpdateFonts;
- (void) setNeedsUpdateSampleText: (BOOL)flag;
- (BOOL) needsUpdateSampleText;
- (void) setNeedsUpdateSize: (BOOL)flag;
- (BOOL) needsUpdateSize;

- (void) setFonts: (NSArray *)someFonts;
- (NSArray *) fonts;
- (void) setForegroundColor: (NSColor *)aColor;
- (NSColor *) foregroundColor;
- (void) setBackgroundColor: (NSColor *)aColor;
- (NSColor *) backgroundColor;
- (void) setSize: (NSNumber *)aNumber;
- (NSNumber *) size;
- (void) setSampleText: (NSString *)someText;
- (NSString *) sampleText;
- (void) setSampleTextHistory: (NSArray *)aHistory;
- (NSArray *) sampleTextHistory;

@end
