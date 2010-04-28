#import <EtoileFoundation/Macros.h>
#import <EtoileUI/EtoileUI.h>
#import "ETPatternStrokeStyle.h"

@implementation ETPatternStrokeStyle

- (id) init
{
	SUPERINIT
	ASSIGN(_color, [NSColor blackColor]);
	_joinStyle = [NSBezierPath defaultLineJoinStyle];
	_capStyle = [NSBezierPath defaultLineCapStyle];
	_width = [NSBezierPath defaultLineWidth];	
	return self;
}

- (void) dealloc
{
	DESTROY(_color);
	DESTROY(_dashStyle);
	[super dealloc];
}

- (NSLineJoinStyle) joinStyle
{
	return _joinStyle;
}

- (void) setJoinStyle: (NSLineJoinStyle)style;
{
	_joinStyle = style;
}

- (NSLineCapStyle) capStyle;
{
	return _capStyle;
}

- (void) setCapStyle: (NSLineCapStyle)style;
{
	_capStyle = style;
}

- (ETStrokeDash *) dashStyle;
{
	return _dashStyle;
}

- (void) setDashStyle: (ETStrokeDash *)dash;
{
	ASSIGN(_dashStyle, dash);
}

- (NSColor *)color
{
    return AUTORELEASE([_color copy]); 
}

- (void) setColor: (NSColor *)color
{
	ASSIGN(_color, [color copy]);
}

- (float) width
{
	return _width;
}

- (void) setWidth: (float)width
{
	_width = width;
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

	NSBezierPath *pathCopy = [[path copy] autorelease];
	[pathCopy setLineJoinStyle: _joinStyle];
	[pathCopy setLineWidth: _width];
	[pathCopy setLineCapStyle: _capStyle];
	[_color set];
	[pathCopy stroke];

	[NSGraphicsContext restoreGraphicsState];
}

@end
