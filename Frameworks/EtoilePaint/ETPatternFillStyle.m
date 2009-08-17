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
	// FIXME: May be we should better support dirtyRect. The next drawing 
	// methods don't take in account it and simply redraw all their content.

	[self drawPath: [inputValues valueForKey: @"path"] inRect: [item drawingFrame]];

	//[super render: inputValues layoutItem: item dirtyRect: dirtyRect];
}

- (void) drawPath: (NSBezierPath *)path inRect: (NSRect)rect
{
	[NSGraphicsContext saveGraphicsState];

	[_color set];
	[path fill];

	[NSGraphicsContext restoreGraphicsState];
}

@end
