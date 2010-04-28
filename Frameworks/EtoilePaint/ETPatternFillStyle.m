#import <EtoileFoundation/Macros.h>
#import <EtoileUI/EtoileUI.h>
#import "ETPatternFillStyle.h"

@implementation ETPatternFillStyle

- (id) init
{
	SUPERINIT
	return self;
}

- (void) dealloc
{
	DESTROY(_color);
	[super dealloc];
}

- (NSColor *)color
{
    return AUTORELEASE([_color copy]); 
}

- (void) setColor: (NSColor *)color
{
	ASSIGN(_color, [color copy]);
}

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect;
{
	[self drawPath: [inputValues valueForKey: @"path"] inRect: [item drawingBoundsForStyle: self]];
}

- (void) drawPath: (NSBezierPath *)path inRect: (NSRect)rect
{
	[NSGraphicsContext saveGraphicsState];

	[_color set];
	[path fill];

	[NSGraphicsContext restoreGraphicsState];
}

@end
