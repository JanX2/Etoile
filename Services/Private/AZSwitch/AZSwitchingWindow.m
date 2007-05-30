/*
 *  AZExpose - A window switcher for GNUstep
 *  Copyright (C) 2007 Yen-Ju Chen
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import "AZSwitchingWindow.h"
#import "AZClientCell.h"

@implementation AZSwitchingWindow
- (void) matrixAction: (id) sender
{
	NSLog(@"matrixAction %@", sender);
}

- (void) next: (id) sender
{
	selectedIndex++;
	if (selectedIndex >= [clients count])
		selectedIndex = 0;
	[matrix selectCellAtRow: selectedIndex column: 0];
}

- (void) previous: (id) sender
{
	selectedIndex--;
	if (selectedIndex < 0)
		selectedIndex = [clients count]-1;
	[matrix selectCellAtRow: selectedIndex column: 0];
}

- (void) setClients: (NSArray *) c
{
	ASSIGN(clients, c);
	int i, count = [clients count];
	[matrix renewRows: [clients count] columns: 1];
	for (i = 0; i < count; i++)
	{
		AZClientCell *cell = [matrix cellAtRow: i column: 0];
		[cell setClient: [clients objectAtIndex: i]];
	}
	[matrix sizeToCells];

	NSRect rect = NSZeroRect;
	rect.size = [matrix frame].size;
	rect.origin = [self frame].origin;
	/* Window is displayed after update clients. So display is NO */
    [self setFrame: rect display:NO animate:NO];

	/* Always select the first one */
	selectedIndex = 0;
	[matrix selectCellAtRow: selectedIndex column: 0];
	[matrix setNeedsDisplay: YES];
}

- (int) indexOfSelectedClient
{
	return selectedIndex;
}

- (id) initWithContentRect: (NSRect)contentRect
                 styleMask: (unsigned int)aStyle
                   backing: (NSBackingStoreType)bufferingType
                     defer: (BOOL)flag
                    screen: (NSScreen*)aScreen
{
	self = [super initWithContentRect: contentRect
	                        styleMask: aStyle
	                          backing: bufferingType
	                            defer: flag
	                           screen: aScreen];
	NSRect rect = NSZeroRect;
	rect.size = contentRect.size;
	AZClientCell *cell = [[AZClientCell alloc] initTextCell: nil];
	[cell setAlignment: NSCenterTextAlignment];
	[cell setTarget: self];
	[cell setAction: @selector(matrixAction:)];
	matrix = [[NSMatrix alloc] initWithFrame: rect];
	[matrix setPrototype: cell];
	[matrix setMode: NSRadioModeMatrix];
	[matrix setCellSize: NSMakeSize(rect.size.width, 25)];
	[matrix setDrawsCellBackground: YES];
	[matrix setAllowsEmptySelection: NO];
	[[self contentView] addSubview: matrix];
	DESTROY(cell);
	return self;
}


@end

