/* FMSampleController */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface FMSampleController : NSObject
{
    IBOutlet NSColorWell *backgroundColorWell;
    IBOutlet NSComboBox *customSampleField;
    IBOutlet NSColorWell *foregroundColorWell;
    IBOutlet NSTextView *sampleView;
    IBOutlet NSTextField *sizeField;
    IBOutlet NSTableView *sizeListView;
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
