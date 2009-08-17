#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETStyle.h>

@interface ETFillStyle : ETStyle
{
	NSColor *_color;
}

- (NSColor *) color;
- (void) setColor: (NSColor *)color;

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect;
- (void) drawPath: (NSBezierPath *)path inRect: (NSRect)rect;

@end
