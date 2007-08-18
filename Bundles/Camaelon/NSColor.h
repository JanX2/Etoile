#import <AppKit/AppKit.h>
#import "GraphicToolbox.h"

@interface NSColor (theme)
+ (void) setSystemColorList;
+ (NSColor*) titlebarTextColor;
+ (NSColor*) selectedTitlebarTextColor;
+ (NSColor*) rowBackgroundColor;
+ (NSColor*) alternateRowBackgroundColor;
+ (NSColor*) rowTextColor;
+ (NSColor*) selectedRowBackgroundColor;
+ (NSColor*) selectedRowTextColor;
+ (NSColor*) selectedControlColor;
+ (NSColor*) selectedTextColor; 
+ (NSColor*) selectedTextBackgroundColor;
+ (NSColor*) windowBackgroundColor;
+ (NSColor*) controlBackgroundColor;

+ (NSColor*) windowBorderColor;
@end
