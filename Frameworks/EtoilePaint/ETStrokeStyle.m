#import <EtoileFoundation/Macros.h>
#import <EtoileUI/EtoileUI.h>
#import "ETFillStyle.h"

@implementation ETFillStyle

/** Initializes and returns a new custom shape based on the given bezier path. */
- (id) init
{
	SUPERINIT

	[self setPath: aPath];
	[self setFillColor: [NSColor darkGrayColor]];
	[self setStrokeColor: [NSColor lightGrayColor]];
	[self setAlphaValue: 0.5];
	[self setHidden: NO];
	
    return self;
}

- (void) dealloc
{
    DESTROY(_color);
    [super dealloc];
}

/** Returns a copy of the receiver shape.

The copied shape is never hidden, even when the receiver was. */
- (id) copyWithZone: (NSZone *)aZone
{
	ETShape *newShape = [super copyWithZone: aZone];
	newShape->_path = [_path copyWithZone: aZone];
	newShape->_fillColor = [_fillColor copyWithZone: aZone];
	newShape->_strokeColor = [_strokeColor copyWithZone: aZone];
	newShape->_alpha = _alpha;
	newShape->_resizeSelector = _resizeSelector;
	return newShape;
}

- (NSColor *) fillColor
{
    return AUTORELEASE([_fillColor copy]); 
}

- (void) setFillColor: (NSColor *)color
{
	ASSIGN(_fillColor, [color copy]);
}

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect;
{
	// FIXME: May be we should better support dirtyRect. The next drawing 
	// methods don't take in account it and simply redraw all their content.

	[self drawInRect: [item drawingFrame]];

	if ([item isSelected])
		[self drawSelectionIndicatorInRect: [item drawingFrame]];
	
	//[super render: inputValues layoutItem: item dirtyRect: dirtyRect];
}

- (void) drawInRect: (NSRect)rect
{
	[NSGraphicsContext saveGraphicsState];

	float alpha = [self alphaValue];
	[[[self fillColor] colorWithAlphaComponent: alpha] setFill];
	[[[self strokeColor] colorWithAlphaComponent: alpha] setStroke];
	[[self path] fill];
	[[self path] stroke];

	[NSGraphicsContext restoreGraphicsState];
}

/** Draws a selection indicator that covers the whole item frame if 
    indicatorRect is equal to it. */
- (void) drawSelectionIndicatorInRect: (NSRect)indicatorRect
{
	//ETLog(@"--- Drawing selection %@ in view %@", NSStringFromRect([item drawingFrame]), [NSView focusView]);
	
	// TODO: We disable the antialiasing for the stroked rect with direct 
	// drawing, but this code may be better moved in 
	// -[ETLayoutItem render:dirtyRect:inContext:] to limit the performance impact.
	BOOL gstateAntialias = [[NSGraphicsContext currentContext] shouldAntialias];
	[[NSGraphicsContext currentContext] setShouldAntialias: NO];
	
	/* Align on pixel boundaries for fractional pixel margin and frame. 
	   Fractional item frame results from the item scaling. 
	   NOTE: May be we should adjust pixel boundaries per edge and only if 
	   needed to get a perfect drawing... */
	NSRect normalizedIndicatorRect = NSInsetRect(NSIntegralRect(indicatorRect), 0.5, 0.5);
	
	/* Draw the interior */
	// FIXME: -setFill doesn't work on GNUstep
	[[[NSColor lightGrayColor] colorWithAlphaComponent: 0.45] set];

	// NOTE: [NSBezierPath fillRect: indicatorRect]; doesn't handle color alpha 
	// on GNUstep
	NSRectFillUsingOperation(normalizedIndicatorRect, NSCompositeSourceOver);

	/* Draw the outline
	   FIXME: Cannot get the outline precisely aligned on pixel boundaries for 
	   GNUstep. With the current code which works well on Cocoa, the top border 
	   of the outline isn't drawn most of the time and the image drawn 
	   underneath seems to wrongly extend beyond the border. */
#ifdef USE_BEZIER_PATH
	// FIXME: NSFrameRectWithWidthUsingOperation() seems to be broken. It 
	// doesn't work even with no alpha in the color, NSCompositeCopy and a width 
	// of 1.0
	[[[NSColor darkGrayColor] colorWithAlphaComponent: 0.55] set];
	NSFrameRectWithWidthUsingOperation(normalizedIndicatorRect, 0.0, NSCompositeSourceOver);
#else
	// FIXME: -setStroke doesn't work on GNUstep
	[[[NSColor darkGrayColor] colorWithAlphaComponent: 0.55] set];
	[NSBezierPath strokeRect: normalizedIndicatorRect];
#endif

	[[NSGraphicsContext currentContext] setShouldAntialias: gstateAntialias];
}

- (void) didChangeItemBounds: (NSRect)bounds
{
	[self setBounds: bounds];
	[super didChangeItemBounds: bounds];
}

@end
