#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETStyle.h>

#import <EtoilePaint/ETStrokeDash.h>

@interface ETStrokeStyle : ETStyle
{
	NSColor *_color;
	NSLineJoinStyle _joinStyle;
	NSLineCapStyle _capStyle;
	ETStrokeDash *_dashStyle;
	float _width;
}

- (NSColor *) color;
- (void) setColor: (NSColor *)color;
- (NSLineJoinStyle) joinStyle;
- (void) setJoinStyle: (NSLineJoinStyle)style;
- (NSLineCapStyle) capStyle;
- (void) setCapStyle: (NSLineCapStyle)style;
- (ETStrokeDash *) dashStyle;
- (void) setDashStyle: (ETStrokeDash *)dash;
- (float) width;
- (void) setWidth: (float)width;

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect;
- (void) drawPath: (NSBezierPath *)path inRect: (NSRect)rect;

@end
