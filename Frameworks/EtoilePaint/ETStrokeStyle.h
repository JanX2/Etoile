#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETStyle.h>

@interface ETStrokeStyle : ETStyle
{
	NSColor *_color;
}

- (NSColor *) color;
- (void) setColor: (NSColor *)color;

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect;
- (void) drawInRect: (NSRect)rect;

@end
