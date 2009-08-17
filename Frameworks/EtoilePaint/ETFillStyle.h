#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETStyle.h>

@interface ETFillStyle : ETStyle
{
	NSColor *_color;
}

- (NSColor *) fillColor;
- (void) setFillColor: (NSColor *)color;

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect;
- (void) drawInRect: (NSRect)rect;
- (void) drawSelectionIndicatorInRect: (NSRect)indicatorRect;

- (void) didChangeItemBounds: (NSRect)bounds;

@end
