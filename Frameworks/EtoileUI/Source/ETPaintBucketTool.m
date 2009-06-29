/*
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2008
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETPaintBucketTool.h"
#import "ETActionHandler.h"
#import "ETApplication.h"
#import "ETLayoutItem.h"
#import "ETCompatibility.h"


@implementation ETBucketTool

+ (NSString *) baseClassName
{
	return @"Tool";
}

/** Initializes and returns a new paint bucket tool which is set up with orange 
as stroke color and brown as fill color. */
- (id) init
{
	SUPERINIT
	[self setStrokeColor: [NSColor orangeColor]];
	[self setFillColor: [NSColor brownColor]];
	return self;
}

- (void) dealloc
{
    DESTROY(_fillColor);
    DESTROY(_strokeColor);
    [super dealloc];
}

/** Returns the fill color associated with the receiver. */
- (NSColor *) fillColor
{
    return AUTORELEASE([_fillColor copy]); 
}

/** Sets the fill color associated with the receiver. */
- (void) setFillColor: (NSColor *)color
{
	ASSIGN(_fillColor, [color copy]);
}

/** Returns the stroke color associated with the receiver. */
- (NSColor *) strokeColor
{
    return AUTORELEASE([_strokeColor copy]); 
}

/** Sets the stroke color associated with the receiver. */
- (void) setStrokeColor: (NSColor *)color
{
	ASSIGN(_strokeColor, [color copy]);
}

/** Returns the paint action produced by the receiver, either stroke or fill. */
- (ETPaintMode) paintMode
{
	return _paintMode;
}

/** Sets the paint action produced by the receiver, either stroke or fill. */
- (void) setPaintMode: (ETPaintMode)aMode
{
	_paintMode = aMode;
}

/* Outside of the boundaries doesn't count because the parent instrument will 
be reactivated when we exit our owner layout. */
- (void) mouseUp: (ETEvent *)anEvent
{	
	ETLayoutItem *item = [self hitTestWithEvent: anEvent];
	ETActionHandler *actionHandler = [item actionHandler];

	ETDebugLog(@"Mouse up with %@ on item %@", self, item);

	if ([self paintMode] == ETPaintModeFill && [actionHandler canFill: item])
	{
		[actionHandler handleFill: item withColor: [self fillColor]];
	}
	else if ([self paintMode] == ETPaintModeStroke && [actionHandler canStroke: item])
	{
		[actionHandler handleStroke: item withColor: [self strokeColor]];
	}
}

- (NSMenu *) menuRepresentation
{
	NSMenu *menu = AUTORELEASE([[NSMenu alloc] initWithTitle: _(@"Bucket Tool Options")]);
	NSMenu *modeSubmenu = AUTORELEASE([[NSMenu alloc] initWithTitle: _(@"Bucket Tool Paint Mode")]);

	[menu addItemWithSubmenu: modeSubmenu];

	[modeSubmenu addItemWithTitle: _(@"Fill")
	                target: self
	                action: @selector(changePaintMode:)
	         keyEquivalent: @""];

	[modeSubmenu addItemWithTitle: _(@"Stroke")
	                target: self
	                action: @selector(changePaintMode:)
	         keyEquivalent: @""];

	[menu addItemWithTitle:  _(@"Choose Colors…")
	                target: self
	                action: @selector(chooseColors:)
	         keyEquivalent: @""];

	return menu;
}

- (void) changePaintMode: (id)sender
{
	 // TODO: Implement
}

- (void) changeColor: (id)sender
{
	NSColor *newColor = nil; // TODO: Finish to implement

	if ([self paintMode] == ETPaintModeFill)
	{
		[self setFillColor: newColor];
	}
	else if ([self paintMode] == ETPaintModeStroke)
	{
		[self setStrokeColor: newColor];
	}
}

@end
