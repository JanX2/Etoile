#import <EtoileFoundation/Macros.h>
#import <EtoileUI/EtoileUI.h>
#import "ETStrokeStyle.h"

@implementation ETStrokeStyle

/** Initializes and returns a new custom shape based on the given bezier path. */
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

	[self drawInRect: [item drawingFrame]];

	//[super render: inputValues layoutItem: item dirtyRect: dirtyRect];
}

- (void) drawInRect: (NSRect)rect
{
	[NSGraphicsContext saveGraphicsState];


	[NSGraphicsContext restoreGraphicsState];
}

@end
